import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';
import 'connection_manager.dart';
import 'device_identity.dart';
import 'logging_service.dart';
import 'device_manager.dart';
import '../discovery/discovery_manager.dart';
import '../../shared/providers/device_provider.dart';
import '../discovery/discovery_provider.dart';

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
  final Ref? _ref;

  final List<PendingPairingRequest> _pendingRequests = [];
  final StreamController<List<PendingPairingRequest>> _pendingRequestsController =
      StreamController<List<PendingPairingRequest>>.broadcast();

  // Active pairing timers
  final Map<String, Timer> _expirationTimers = {};

  // Active hosting code & token
  String? _activePairCode;
  String? _activePairingToken;
  DateTime? _activePairCodeExpiry;

  // Callback to notify UI of new incoming request
  void Function(PendingPairingRequest request)? onIncomingRequest;

  DevicePairingService(
    this._repository,
    this._identity,
    this._connectionManager,
    this._logger, [
    this._ref,
  ]) {
    _connectionManager.onPairingRequestReceived = _handleIncomingPairingRequest;
  }

  Stream<List<PendingPairingRequest>> get pendingRequestsStream =>
      _pendingRequestsController.stream;

  List<PendingPairingRequest> get pendingRequests => List.unmodifiable(_pendingRequests);

  String? get activePairCode => _activePairCode;

  DeviceRepository get repository => _repository;
  DeviceIdentity get identity => _identity;

  /// Starts hosting pairing, generates a 6-digit code and starts the expiry timer.
  String startHostingPairing() {
    _activePairCode = generatePairCode();
    _activePairingToken = generatePairingToken();
    _activePairCodeExpiry = DateTime.now().add(const Duration(seconds: 300));
    
    // Save to key-value settings database asynchronously
    _repository.savePairCodeDetails(
      _activePairCode!,
      DateTime.now(),
      _activePairCodeExpiry!,
    );
    
    // Log Pair Code Generated
    _logger.info('PairCode', 'Pair Code Generated: $_activePairCode');
    
    return _activePairCode!;
  }

  void stopHostingPairing() {
    _activePairCode = null;
    _activePairingToken = null;
    _activePairCodeExpiry = null;
  }

  /// Estimates the local IP address
  Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      
      // Step 1: Filter out known virtual/loopback interfaces
      final realInterfaces = interfaces.where((interface) {
        final name = interface.name.toLowerCase();
        return !name.contains('vbox') &&
               !name.contains('wsl') &&
               !name.contains('virtual') &&
               !name.contains('vmnet') &&
               !name.contains('docker') &&
               !name.contains('hyper-v') &&
               !name.contains('host-only') &&
               !name.contains('loopback');
      }).toList();

      // Step 2: Prioritize Wi-Fi and Ethernet interfaces
      for (final interface in realInterfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wi-fi') ||
            name.contains('wifi') ||
            name.contains('wlan') ||
            name.contains('ethernet') ||
            name.contains('eth') ||
            name.contains('lan') ||
            name.contains('wext')) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }

      // Step 3: Fallback to any non-loopback address from real interfaces
      for (final interface in realInterfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }

      // Step 4: Fallback to any non-loopback address at all
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1'; // Fallback
  }

  /// Encodes host pairing information as a JSON string for QR Code
  Future<String> getPairingQrPayload() async {
    final ip = await getLocalIpAddress();
    final selfModel = await _identity.toModel(ip: ip, port: ConnectionManager.tcpPort);
    
    // Calculate expiration time (from active code expiry, or 5 minutes from now)
    final expiry = _activePairCodeExpiry ?? DateTime.now().add(const Duration(seconds: 300));

    final payload = {
      'pairCode': _activePairCode ?? '',
      'deviceUuid': selfModel.id,
      'deviceName': selfModel.name,
      'localIp': ip,
      'tcpPort': ConnectionManager.tcpPort,
      'appVersion': selfModel.appVersion,
      'expirationTime': expiry.toIso8601String(),
    };
    
    final payloadString = json.encode(payload);
    
    // Log QR Generated
    _logger.info('PairCode', 'QR Generated: $payloadString');
    
    return payloadString;
  }

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
  Future<bool> initiatePairing(String targetIp, String pairCode, {int? port, String? qrToken}) async {
    final selfModel = await _identity.toModel();
    final pairingToken = generatePairingToken();
    
    final targetPort = port ?? ConnectionManager.tcpPort;
    await _logger.info('DeviceManager', '[HANDSHAKE STEP 1] Initiating pairing request to $targetIp:$targetPort with code "$pairCode" and QR token "${qrToken ?? 'none'}"');
    await _logger.info('PairCode', 'Pair Code Sent to $targetIp:$targetPort: $pairCode');

    final requestJson = {
      'type': 'pairing_request',
      'device': selfModel.toJson(),
      'pairCode': pairCode,
      'qrToken': qrToken ?? '',
      'pairingToken': pairingToken,
    };

    final response = await _connectionManager.sendPairingRequest(targetIp, requestJson, port: targetPort);
    if (response == null) {
      await _logger.error('DeviceManager', '[HANDSHAKE ERROR] Pairing request to $targetIp:$targetPort failed: No response / Connection Timeout');
      return false;
    }

    final status = response['status'] as String?;
    await _logger.info('DeviceManager', '[HANDSHAKE STEP 4] Received response from $targetIp:$targetPort. Status: "$status"');

    if (status == 'approved') {
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

      // Save to SQLite
      await _repository.addOrUpdateDevice(targetDevice);
      
      if (_ref != null) {
        final DeviceManager devManager = _ref.read(deviceManagerProvider);
        await devManager.addDevice(targetDevice);
        
        final DiscoveryManager discManager = _ref.read(discoveryManagerProvider);
        await discManager.refresh();
      }

      await _logger.info('DeviceManager', '[HANDSHAKE SUCCESS] Device "${targetDevice.name}" added successfully as Trusted');
      return true;
    } else {
      final reason = response['reason'] as String? ?? (status == 'blocked' ? 'Blocked' : 'Rejected');
      await _logger.warning('DeviceManager', '[HANDSHAKE FAILED] Pairing request to $targetIp:$targetPort was not approved. Reason: $reason');
      return false;
    }
  }

  /// Handles incoming pairing request over TCP/Mock
  void _handleIncomingPairingRequest(Map<String, dynamic> requestJson, Socket? socket) async {
    final senderIp = socket?.remoteAddress.address ?? 'unknown';
    final senderPort = socket?.remotePort ?? 0;
    
    await _logger.info('DeviceManager', '[HANDSHAKE STEP 2] Received incoming pairing request from $senderIp:$senderPort');

    try {
      final senderMap = requestJson['device'] as Map<String, dynamic>;
      final senderDevice = DeviceModel.fromJson(senderMap);
      final pairCode = requestJson['pairCode'] as String;
      final pairingToken = requestJson['pairingToken'] as String;
      final incomingQrToken = requestJson['qrToken'] as String?;

      // Validate device identity fields
      if (senderDevice.id.isEmpty || senderDevice.name.isEmpty || senderDevice.platform.isEmpty || senderDevice.appVersion.isEmpty) {
        await _logger.error('DeviceManager', '[HANDSHAKE ERROR] Missing required device metadata fields from $senderIp');
        if (socket != null) {
          await _connectionManager.respondToRequest(socket, {
            'status': 'rejected',
            'reason': 'missing_metadata',
          });
        }
        return;
      }

      // 1. Duplicate & Block status check
      final existing = await _repository.getDeviceById(senderDevice.id);
      if (existing != null) {
        if (existing.trustStatus == 'Blocked') {
          await _logger.warning('PairCode', 'Validation Failed: Blocked connection attempt from ${senderDevice.name}');
          await _repository.addPairHistoryEntry(senderDevice.name, senderDevice.platform, 'Blocked', 'Blocked connection attempt');
          if (socket != null) {
            await _connectionManager.respondToRequest(socket, {'status': 'blocked'});
          }
          return;
        }
        if (existing.trustStatus == 'Trusted') {
          await _logger.warning('PairCode', 'Validation Failed: Already Trusted Device');
          await _repository.addPairHistoryEntry(senderDevice.name, senderDevice.platform, 'Failed', 'Already Trusted Device');
          if (socket != null) {
            await _connectionManager.respondToRequest(socket, {
              'status': 'rejected',
              'reason': 'Already Trusted Device',
            });
          }
          return;
        }
      }

      // Check if there is already a pending request for this device and remove it
      final isDuplicatePending = _pendingRequests.any((r) => r.device.id == senderDevice.id);
      if (isDuplicatePending) {
        await _logger.warning('PairCode', 'Validation Failed: Duplicate Device');
        await _repository.addPairHistoryEntry(senderDevice.name, senderDevice.platform, 'Failed', 'Duplicate Device');
        if (socket != null) {
          await _connectionManager.respondToRequest(socket, {
            'status': 'rejected',
            'reason': 'Duplicate Device',
          });
        }
        return;
      }

      // 2. Validate the pairing token from the QR payload if present
      bool isTokenValid = true;
      if (_activePairingToken != null && _activePairingToken!.isNotEmpty) {
        if (incomingQrToken == null || incomingQrToken != _activePairingToken) {
          isTokenValid = false;
        }
      }

      if (!isTokenValid) {
        await _logger.warning('DeviceManager', '[HANDSHAKE ERROR] Invalid or mismatched QR pairing token from ${senderDevice.name}');
        if (socket != null) {
          await _connectionManager.respondToRequest(socket, {
            'status': 'rejected',
            'reason': 'invalid_token',
          });
        }
        return;
      }

      // 3. Pair code verification (including expiration)
      final now = DateTime.now();
      bool isCodeExpired = _activePairCodeExpiry != null && now.isAfter(_activePairCodeExpiry!);
      if (isCodeExpired) {
        await _logger.warning('PairCode', 'Validation Failed: Expired Code');
        await _repository.addPairHistoryEntry(senderDevice.name, senderDevice.platform, 'Failed', 'Expired Code');
        if (socket != null) {
          await _connectionManager.respondToRequest(socket, {
            'status': 'rejected',
            'reason': 'Expired Code',
          });
        }
        return;
      }

      bool isCodeMatch = _activePairCode != null && _activePairCode == pairCode;
      if (!isCodeMatch && pairCode != 'direct' && pairCode.isNotEmpty) {
        await _logger.warning('PairCode', 'Validation Failed: Wrong Pair Code');
        await _repository.addPairHistoryEntry(senderDevice.name, senderDevice.platform, 'Failed', 'Wrong Pair Code');
        if (socket != null) {
          await _connectionManager.respondToRequest(socket, {
            'status': 'rejected',
            'reason': 'Wrong Pair Code',
          });
        }
        return;
      }

      await _logger.info('PairCode', 'Validation Success');
      await _logger.info('PairCode', 'Pair Code Validated');

      // Check if there is already a pending request for this device and remove it
      _pendingRequests.removeWhere((r) => r.device.id == senderDevice.id);
      _expirationTimers.remove(senderDevice.id)?.cancel();

      // 4. Add pending request
      final request = PendingPairingRequest(
        device: senderDevice,
        pairCode: pairCode,
        token: pairingToken,
        expiresAt: DateTime.now().add(const Duration(seconds: 120)),
        isIncoming: true,
        socket: socket,
      );

      _pendingRequests.add(request);
      _pendingRequestsController.add(_pendingRequests);

      // 5. Set automatic expiration timer (120 seconds)
      final timer = Timer(const Duration(seconds: 120), () {
        _handleRequestExpiration(request.device.id);
      });
      _expirationTimers[request.device.id] = timer;

      if (onIncomingRequest != null) {
        onIncomingRequest!(request);
      }
    } catch (e, s) {
      _logger.error('DeviceManager', '[HANDSHAKE ERROR] Error handling incoming pairing request: $e', s.toString());
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

      await _logger.warning('PairCode', 'Validation Failed: Expired Code due to pending timeout');
      await _repository.addPairHistoryEntry(req.device.name, req.device.platform, 'Failed', 'Expired Code (Pending Timeout)');
      
      if (req.socket != null) {
        await _connectionManager.respondToRequest(req.socket!, {'status': 'expired'});
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

    await _logger.info('DeviceManager', '[HANDSHAKE STEP 3] Approving pairing request from ${req.device.name}');
    await _logger.info('PairCode', 'Accepted pairing request from ${req.device.name}');
    await _logger.info('PairCode', 'Pair Accepted');
    await _repository.addPairHistoryEntry(req.device.name, req.device.platform, 'Accepted', 'Pairing request accepted by user');

    if (req.socket != null) {
      await _connectionManager.respondToRequest(req.socket!, response);
    }

    // Add to trusted database in SQLite
    final trustedDevice = req.device.copyWith(
      trustStatus: 'Trusted',
      connectionStatus: 'Online',
      pairingDate: DateTime.now(),
      lastSeen: DateTime.now(),
      pairingToken: secureToken,
    );

    await _repository.addOrUpdateDevice(trustedDevice);
    
    if (_ref != null) {
      final DeviceManager devManager = _ref.read(deviceManagerProvider);
      await devManager.addDevice(trustedDevice);
      
      final DiscoveryManager discManager = _ref.read(discoveryManagerProvider);
      await discManager.refresh();
    }

    await _logger.info('DeviceManager', '[HANDSHAKE STEP 3 SUCCESS] Device "${req.device.name}" marked as Trusted');
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

    await _logger.info('DeviceManager', '[HANDSHAKE REJECTED] Rejecting pairing request from ${req.device.name}');
    await _logger.info('PairCode', 'Rejected pairing request from ${req.device.name}');
    await _logger.info('PairCode', 'Pair Rejected');
    await _repository.addPairHistoryEntry(req.device.name, req.device.platform, 'Rejected', 'Pairing request rejected by user');

    if (req.socket != null) {
      await _connectionManager.respondToRequest(req.socket!, response);
    }
  }

  /// Block request/device completely
  Future<void> blockRequest(String deviceId) async {
    final index = _pendingRequests.indexWhere((r) => r.device.id == deviceId);
    PendingPairingRequest? req;
    if (index != -1) {
      req = _pendingRequests.removeAt(index);
      _pendingRequestsController.add(_pendingRequests);
      _expirationTimers.remove(deviceId)?.cancel();
    }

    final response = {
      'type': 'pairing_response',
      'status': 'blocked',
    };

    await _logger.info('DeviceManager', '[HANDSHAKE BLOCKED] Blocking device ID $deviceId');

    if (req?.socket != null) {
      await _connectionManager.respondToRequest(req!.socket!, response);
    }

    // Save as blocked in SQLite
    final blockedDevice = (req != null ? req.device : await _repository.getDeviceById(deviceId))?.copyWith(
      trustStatus: 'Blocked',
      pairingDate: DateTime.now(),
      lastSeen: DateTime.now(),
    );

    if (blockedDevice != null) {
      await _repository.addOrUpdateDevice(blockedDevice);
      
      if (_ref != null) {
        final DeviceManager devManager = _ref.read(deviceManagerProvider);
        await devManager.addDevice(blockedDevice);
        
        final DiscoveryManager discManager = _ref.read(discoveryManagerProvider);
        await discManager.refresh();
      }
    }
  }

  // Simulation support for testing
  void simulateIncomingRequest(DeviceModel sender, String code, {bool overrideCode = true}) {
    if (overrideCode) {
      _activePairCode = code;
      _activePairingToken = generatePairingToken();
      _activePairCodeExpiry = DateTime.now().add(const Duration(seconds: 300));
    }
    final payload = {
      'type': 'pairing_request',
      'device': sender.toJson(),
      'pairCode': code,
      'qrToken': _activePairingToken ?? '',
      'pairingToken': generatePairingToken(),
    };
    _handleIncomingPairingRequest(payload, null);
  }

  void setPairCodeExpiryForTest(DateTime expiry) {
    _activePairCodeExpiry = expiry;
  }

  void dispose() {
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _pendingRequestsController.close();
  }
}
