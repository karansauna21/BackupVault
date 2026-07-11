import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';
import 'connection_manager.dart';
import 'device_identity.dart';
import 'logging_service.dart';

class PendingPairingRequest {
  final DeviceModel device;
  final String pairCode;
  final String token;
  final DateTime expiresAt;
  final bool isIncoming;
  final Socket? socket;

  PendingPairingRequest({
    required this.device,
    required this.pairCode,
    required this.token,
    required this.expiresAt,
    required this.isIncoming,
    this.socket,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DevicePairingService {
  final DeviceRepository _repository;
  final DeviceIdentity _identity;
  final ConnectionManager _connectionManager;
  final LoggingService _logger;

  final List<PendingPairingRequest> _pendingRequests = [];
  final StreamController<List<PendingPairingRequest>> _pendingRequestsController =
      StreamController<List<PendingPairingRequest>>.broadcast();

  // Active pairing timers
  final Map<String, Timer> _expirationTimers = {};

  // Callback to notify UI of new incoming request
  void Function(PendingPairingRequest request)? onIncomingRequest;

  DevicePairingService(
    this._repository,
    this._identity,
    this._connectionManager,
    this._logger,
  ) {
    _connectionManager.onPairingRequestReceived = _handleIncomingPairingRequest;
  }

  Stream<List<PendingPairingRequest>> get pendingRequestsStream =>
      _pendingRequestsController.stream;

  List<PendingPairingRequest> get pendingRequests => List.unmodifiable(_pendingRequests);

  /// Generates a random 6-digit pair code.
  String generatePairCode() {
    final random = Random();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  /// Generates a secure random pairing token.
  String generatePairingToken() {
    return const Uuid().v4();
  }

  /// Initiates pairing request to a target IP.
  Future<bool> initiatePairing(String targetIp, String pairCode) async {
    final selfModel = await _identity.toModel();
    final pairingToken = generatePairingToken();
    
    await _logger.info('DeviceManager', 'Initiating pairing request to $targetIp with code $pairCode');

    final requestJson = {
      'type': 'pairing_request',
      'device': selfModel.toJson(),
      'pairCode': pairCode,
      'pairingToken': pairingToken,
    };

    final response = await _connectionManager.sendPairingRequest(targetIp, requestJson);
    if (response == null) {
      await _logger.error('DeviceManager', 'Pairing request to $targetIp failed: No response/Timeout');
      return false;
    }

    if (response['status'] == 'approved') {
      final targetDeviceMap = response['device'] as Map<String, dynamic>;
      targetDeviceMap['ipAddress'] = targetIp;
      
      var targetDevice = DeviceModel.fromJson(targetDeviceMap);
      targetDevice = targetDevice.copyWith(
        trustStatus: 'Trusted',
        connectionStatus: 'Online',
        pairingDate: DateTime.now(),
        lastSeen: DateTime.now(),
        pairingToken: response['pairingToken'] as String?,
      );

      await _repository.addOrUpdateDevice(targetDevice);
      await _logger.info('DeviceManager', 'Device "${targetDevice.name}" added successfully (Approved)');
      return true;
    } else {
      final reason = response['status'] == 'rejected' ? 'Rejected by user' : 'Blocked/Unknown';
      await _logger.warning('DeviceManager', 'Pairing request to $targetIp was not approved. Status: $reason');
      return false;
    }
  }

  /// Handles incoming pairing request over TCP/Mock
  void _handleIncomingPairingRequest(Map<String, dynamic> requestJson, Socket? socket) async {
    try {
      final senderMap = requestJson['device'] as Map<String, dynamic>;
      final senderDevice = DeviceModel.fromJson(senderMap);
      final pairCode = requestJson['pairCode'] as String;
      final pairingToken = requestJson['pairingToken'] as String;

      // 1. Check if blocked
      final existing = await _repository.getDeviceById(senderDevice.id);
      if (existing != null && existing.trustStatus == 'Blocked') {
        await _logger.warning('DeviceManager', 'Blocked connection attempt from ${senderDevice.name} (${senderDevice.id})');
        if (socket != null) {
          _connectionManager.respondToRequest(socket, {'status': 'blocked'});
        }
        return;
      }

      await _logger.info('DeviceManager', 'Received pairing request from ${senderDevice.name} with code $pairCode');

      // 2. Add pending request
      final request = PendingPairingRequest(
        device: senderDevice,
        pairCode: pairCode,
        token: pairingToken,
        expiresAt: DateTime.now().add(const Duration(seconds: 60)),
        isIncoming: true,
        socket: socket,
      );

      _pendingRequests.add(request);
      _pendingRequestsController.add(_pendingRequests);

      // 3. Set automatic expiration timer (60 seconds)
      final timer = Timer(const Duration(seconds: 60), () {
        _handleRequestExpiration(request.device.id);
      });
      _expirationTimers[request.device.id] = timer;

      if (onIncomingRequest != null) {
        onIncomingRequest!(request);
      }
    } catch (e, s) {
      _logger.error('DeviceManager', 'Error handling incoming pairing request: $e', s.toString());
      if (socket != null) {
        socket.close();
      }
    }
  }

  /// Handles the automatic expiration of a request.
  void _handleRequestExpiration(String deviceId) async {
    final index = _pendingRequests.indexWhere((r) => r.device.id == deviceId);
    if (index != -1) {
      final req = _pendingRequests.removeAt(index);
      _pendingRequestsController.add(_pendingRequests);
      _expirationTimers.remove(deviceId)?.cancel();

      await _logger.warning('DeviceManager', 'Pairing request from ${req.device.name} expired');
      
      if (req.socket != null) {
        _connectionManager.respondToRequest(req.socket!, {'status': 'expired'});
      }
    }
  }

  /// Approves a pending pairing request.
  Future<void> approveRequest(String deviceId) async {
    final index = _pendingRequests.indexWhere((r) => r.device.id == deviceId);
    if (index == -1) return;

    final req = _pendingRequests.removeAt(index);
    _pendingRequestsController.add(_pendingRequests);
    _expirationTimers.remove(deviceId)?.cancel();

    final selfModel = await _identity.toModel();
    final secureToken = generatePairingToken();

    final response = {
      'type': 'pairing_response',
      'status': 'approved',
      'device': selfModel.toJson(),
      'pairingToken': secureToken,
    };

    if (req.socket != null) {
      _connectionManager.respondToRequest(req.socket!, response);
    }

    // Add to trusted database
    final trustedDevice = req.device.copyWith(
      trustStatus: 'Trusted',
      connectionStatus: 'Online',
      pairingDate: DateTime.now(),
      lastSeen: DateTime.now(),
      pairingToken: secureToken,
    );

    await _repository.addOrUpdateDevice(trustedDevice);
    await _logger.info('DeviceManager', 'Approved pairing request from ${req.device.name}');
  }

  /// Rejects a pending pairing request.
  Future<void> rejectRequest(String deviceId) async {
    final index = _pendingRequests.indexWhere((r) => r.device.id == deviceId);
    if (index == -1) return;

    final req = _pendingRequests.removeAt(index);
    _pendingRequestsController.add(_pendingRequests);
    _expirationTimers.remove(deviceId)?.cancel();

    final response = {
      'type': 'pairing_response',
      'status': 'rejected',
    };

    if (req.socket != null) {
      _connectionManager.respondToRequest(req.socket!, response);
    }

    await _logger.info('DeviceManager', 'Rejected pairing request from ${req.device.name}');
  }

  // Simulation support for testing
  void simulateIncomingRequest(DeviceModel sender, String code) {
    final payload = {
      'type': 'pairing_request',
      'device': sender.toJson(),
      'pairCode': code,
      'pairingToken': generatePairingToken(),
    };
    _handleIncomingPairingRequest(payload, null);
  }

  void dispose() {
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _pendingRequestsController.close();
  }
}
