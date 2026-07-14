import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';
import 'connection_manager.dart';
import 'device_identity.dart';
import 'logging_service.dart';
import '../../shared/providers/device_provider.dart';
import '../discovery/discovery_provider.dart';

class DeviceManager {
  final DeviceRepository _repository;
  final DeviceIdentity _identity;
  final ConnectionManager _connectionManager;
  final LoggingService _logger;
  final Ref? _ref;

  final List<DeviceModel> _pairedDevices = [];
  final List<DeviceModel> _discoveredDevices = [];
  
  final StreamController<List<DeviceModel>> _pairedDevicesController = StreamController<List<DeviceModel>>.broadcast();
  final StreamController<List<DeviceModel>> _discoveredDevicesController = StreamController<List<DeviceModel>>.broadcast();

  Timer? _statusCheckTimer;

  DeviceManager(
    this._repository,
    this._identity,
    this._connectionManager,
    this._logger, [
    this._ref,
  ]) {
    _connectionManager.onDeviceDiscovered = _handleDiscoveredDevice;
    _connectionManager.onManualHandshakeReceived = _handleManualHandshake;
  }

  Stream<List<DeviceModel>> get pairedDevicesStream => _pairedDevicesController.stream;
  Stream<List<DeviceModel>> get discoveredDevicesStream => _discoveredDevicesController.stream;

  List<DeviceModel> get pairedDevices => List.unmodifiable(_pairedDevices);
  List<DeviceModel> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  Future<void> init() async {
    // 1. Initialize self identity
    await _identity.init();

    // 2. Load stored paired devices
    final loaded = await _repository.getDevices();
    _pairedDevices.addAll(loaded);
    _pairedDevicesController.add(_pairedDevices);

    // 3. Start LAN discovery & Server listener
    final selfModel = await _identity.toModel();
    await _connectionManager.startServer();
    await _connectionManager.startDiscovery(selfModel);

    // 4. Listen to Discovery Service health updates to sync paired devices status
    if (_ref != null) {
      try {
        final discoveryService = _ref.read(discoveryServiceProvider);
        discoveryService.onDevicesChanged.listen((discoveredList) {
          bool changed = false;
          for (final disc in discoveredList) {
            final idx = _pairedDevices.indexWhere((d) => d.id == disc.device.id);
            if (idx != -1) {
              final old = _pairedDevices[idx];
              if (old.connectionStatus != (disc.isOnline ? 'Online' : 'Offline') ||
                  old.lastSeen != disc.lastSeen ||
                  old.ipAddress != disc.device.ipAddress ||
                  old.port != disc.device.port) {
                _pairedDevices[idx] = old.copyWith(
                  connectionStatus: disc.isOnline ? 'Online' : 'Offline',
                  lastSeen: disc.lastSeen,
                  ipAddress: disc.device.ipAddress,
                  port: disc.device.port,
                );
                changed = true;
              }
            }
          }
          if (changed) {
            _pairedDevicesController.add(_pairedDevices);
          }
        });
      } catch (_) {}
    }

    // 5. Start periodic online status health checker (every 10 seconds)
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkOnlineStatus());
  }

  Future<void> connectManualIP(String ip, int port) async {
    await _logger.info('ManualConnection', 'Connecting to $ip:$port');
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      await _logger.info('ManualConnection', 'Connected to $ip:$port');

      final selfModel = await _identity.toModel();
      final handshake = {
        'type': 'manual_handshake',
        'deviceUuid': selfModel.id,
        'deviceName': selfModel.name,
        'platform': selfModel.platform,
        'appVersion': selfModel.appVersion,
      };

      socket.write(json.encode(handshake));
      await socket.flush();
      await _logger.info('ManualConnection', 'Handshake Sent: $handshake');

      final completer = Completer<String>();
      socket.listen(
        (data) {
          try {
            final message = utf8.decode(data);
            completer.complete(message);
          } catch (e) {
            completer.completeError(e);
          }
        },
        onError: (err) {
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          if (!completer.isCompleted) completer.completeError(Exception('Connection closed before ACK received'));
        },
      );

      final responseStr = await completer.future.timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Timed out waiting for Handshake ACK');
      });

      final ackJson = json.decode(responseStr) as Map<String, dynamic>;
      final status = ackJson['status'] as String?;
      final windowsUuid = ackJson['deviceUuid'] as String?;
      final windowsName = ackJson['deviceName'] as String?;
      final windowsPlatform = ackJson['platform'] as String?;
      final windowsAppVersion = ackJson['appVersion'] as String?;

      if (status != 'ACK' || windowsUuid == null || windowsUuid.isEmpty || windowsName == null || windowsName.isEmpty) {
        final reason = ackJson['reason'] as String? ?? 'Invalid ACK status';
        throw Exception('Server rejected connection: $reason');
      }

      await _logger.info('ManualConnection', 'ACK Received from $windowsName ($windowsUuid): $ackJson');

      // Save connection in SQLite
      final windowsDevice = DeviceModel(
        id: windowsUuid,
        name: windowsName,
        platform: windowsPlatform ?? 'Windows',
        osVersion: '1.0',
        appVersion: windowsAppVersion ?? '1.0.0',
        deviceModel: 'Generic',
        pairingDate: DateTime.now(),
        lastSeen: DateTime.now(),
        trustStatus: 'Trusted',
        connectionStatus: 'Online',
        ipAddress: ip,
        port: port,
        storageInfo: 'Unknown',
      );
      await addDevice(windowsDevice);

      // Trigger global notification event
      if (_ref != null) {
        _ref.read(manualConnectionEventProvider.notifier).trigger(windowsName, 'Connected');
      }
    } catch (e) {
      await _logger.error('ManualConnection', 'Connection Failed: $e');
      rethrow;
    } finally {
      if (socket != null) {
        await socket.close();
      }
    }
  }

  Future<void> _handleManualHandshake(Map<String, dynamic> handshakeJson, Socket socket) async {
    final senderIp = socket.remoteAddress.address;
    final senderPort = socket.remotePort;
    
    await _logger.info('ManualConnection', 'Handshake Received from $senderIp:$senderPort');

    try {
      final remoteUuid = handshakeJson['deviceUuid'] as String?;
      final remoteName = handshakeJson['deviceName'] as String?;
      final remotePlatform = handshakeJson['platform'] as String?;
      final remoteAppVersion = handshakeJson['appVersion'] as String?;

      // Validate the handshake details
      if (remoteUuid == null || remoteUuid.isEmpty ||
          remoteName == null || remoteName.isEmpty ||
          remotePlatform == null || remotePlatform.isEmpty ||
          remoteAppVersion == null || remoteAppVersion.isEmpty) {
        await _logger.error('ManualConnection', 'Connection Failed: Invalid handshake metadata');
        socket.write(json.encode({
          'type': 'manual_handshake_ack',
          'status': 'ERROR',
          'reason': 'Invalid handshake metadata'
        }));
        await socket.flush();
        socket.close();
        return;
      }

      await _logger.info('ManualConnection', 'Connected device validated: $remoteName ($remoteUuid)');

      // Save connection in SQLite
      final remoteDevice = DeviceModel(
        id: remoteUuid,
        name: remoteName,
        platform: remotePlatform,
        osVersion: '1.0',
        appVersion: remoteAppVersion,
        deviceModel: 'Generic',
        pairingDate: DateTime.now(),
        lastSeen: DateTime.now(),
        trustStatus: 'Trusted',
        connectionStatus: 'Online',
        ipAddress: senderIp,
        port: 8321,
        storageInfo: 'Unknown',
      );
      await addDevice(remoteDevice);

      // Reply with ACK containing local details
      final selfModel = await _identity.toModel();
      final ackPayload = {
        'type': 'manual_handshake_ack',
        'status': 'ACK',
        'deviceUuid': selfModel.id,
        'deviceName': selfModel.name,
        'platform': selfModel.platform,
        'appVersion': selfModel.appVersion,
      };

      socket.write(json.encode(ackPayload));
      await socket.flush();
      await _logger.info('ManualConnection', 'ACK Sent to $remoteName ($remoteUuid): $ackPayload');

      // Trigger global notification event on Windows (server)
      if (_ref != null) {
        _ref.read(manualConnectionEventProvider.notifier).trigger(remoteName, 'Connected');
      }
    } catch (e) {
      await _logger.error('ManualConnection', 'Connection Failed: $e');
    } finally {
      socket.close();
    }
  }

  void _handleDiscoveredDevice(DeviceModel device) async {
    // Ignore self
    if (device.id == _identity.id) return;

    // Check if device is already paired
    final existingIndex = _pairedDevices.indexWhere((d) => d.id == device.id);
    if (existingIndex != -1) {
      final old = _pairedDevices[existingIndex];
      // Update IP, Port, last seen, and mark as Online
      final updated = old.copyWith(
        ipAddress: device.ipAddress,
        port: device.port,
        lastSeen: DateTime.now(),
        connectionStatus: 'Online',
        storageInfo: device.storageInfo,
        osVersion: device.osVersion,
        appVersion: device.appVersion,
      );
      _pairedDevices[existingIndex] = updated;
      _pairedDevicesController.add(_pairedDevices);
      await _repository.addOrUpdateDevice(updated);
      return;
    }

    // Add to discovered devices if not already there
    final discIndex = _discoveredDevices.indexWhere((d) => d.id == device.id);
    if (discIndex != -1) {
      _discoveredDevices[discIndex] = device.copyWith(lastSeen: DateTime.now());
    } else {
      _discoveredDevices.add(device);
    }
    _discoveredDevicesController.add(_discoveredDevices);
  }

  Future<void> renameDevice(String id, String newName) async {
    final index = _pairedDevices.indexWhere((d) => d.id == id);
    if (index == -1) return;

    final old = _pairedDevices[index];
    final updated = old.copyWith(name: newName);
    _pairedDevices[index] = updated;
    _pairedDevicesController.add(_pairedDevices);
    await _repository.addOrUpdateDevice(updated);

    await _logger.info('DeviceManager', 'Device "${old.name}" renamed to "$newName"');
  }

  Future<void> setTrustStatus(String id, String trustStatus) async {
    final index = _pairedDevices.indexWhere((d) => d.id == id);
    if (index == -1) {
      var device = await _repository.getDeviceById(id);
      if (device == null) {
        final discIndex = _discoveredDevices.indexWhere((d) => d.id == id);
        if (discIndex != -1) {
          device = _discoveredDevices[discIndex];
        }
      }
      if (device != null) {
        final updated = device.copyWith(trustStatus: trustStatus);
        _pairedDevices.add(updated);
        _pairedDevicesController.add(_pairedDevices);
        await _repository.addOrUpdateDevice(updated);
        await _logger.info('DeviceManager', 'Trust status of "${updated.name}" changed to $trustStatus');
      }
      return;
    }

    final old = _pairedDevices[index];
    final updated = old.copyWith(trustStatus: trustStatus);
    _pairedDevices[index] = updated;
    _pairedDevicesController.add(_pairedDevices);
    await _repository.addOrUpdateDevice(updated);

    await _logger.info('DeviceManager', 'Trust status of "${old.name}" changed to $trustStatus');
  }

  Future<void> approveDevice(String id) async {
    await setTrustStatus(id, 'Trusted');
  }

  Future<void> rejectDevice(String id) async {
    await setTrustStatus(id, 'Rejected');
  }

  Future<void> blockDevice(String id) async {
    await setTrustStatus(id, 'Blocked');
  }

  Future<void> unblockDevice(String id) async {
    await setTrustStatus(id, 'Pending');
  }

  String getDeviceTrustStatus(String id) {
    final index = _pairedDevices.indexWhere((d) => d.id == id);
    if (index != -1) {
      return _pairedDevices[index].trustStatus;
    }
    return 'Pending';
  }

  Future<void> disconnectDevice(String id) async {
    final index = _pairedDevices.indexWhere((d) => d.id == id);
    if (index == -1) return;

    final old = _pairedDevices[index];
    final updated = old.copyWith(connectionStatus: 'Offline');
    _pairedDevices[index] = updated;
    _pairedDevicesController.add(_pairedDevices);
    await _repository.addOrUpdateDevice(updated);

    await _logger.info('DeviceManager', 'Disconnected device "${old.name}"');
  }

  Future<void> removeDevice(String id) async {
    final index = _pairedDevices.indexWhere((d) => d.id == id);
    if (index == -1) return;

    final removed = _pairedDevices.removeAt(index);
    _pairedDevicesController.add(_pairedDevices);
    await _repository.removeDevice(id);

    await _logger.info('DeviceManager', 'Device "${removed.name}" removed');
  }

  Future<void> addDevice(DeviceModel device) async {
    final index = _pairedDevices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _pairedDevices[index] = device;
    } else {
      _pairedDevices.add(device);
    }
    _pairedDevicesController.add(_pairedDevices);
    await _repository.addOrUpdateDevice(device);
    await _logger.info('DeviceManager', 'Device "${device.name}" added');
  }

  Future<void> updateLastSeen(String id, DateTime lastSeen) async {
    final index = _pairedDevices.indexWhere((d) => d.id == id);
    if (index == -1) return;
    final old = _pairedDevices[index];
    final updated = old.copyWith(lastSeen: lastSeen);
    _pairedDevices[index] = updated;
    _pairedDevicesController.add(_pairedDevices);
    await _repository.addOrUpdateDevice(updated);
  }

  Future<List<DeviceModel>> loadDevices() async {
    final loaded = await _repository.getDevices();
    _pairedDevices.clear();
    _pairedDevices.addAll(loaded);
    _pairedDevicesController.add(_pairedDevices);
    return _pairedDevices;
  }

  Future<void> saveDevices(List<DeviceModel> devices) async {
    _pairedDevices.clear();
    _pairedDevices.addAll(devices);
    _pairedDevicesController.add(_pairedDevices);
    await _repository.saveDevices(devices);
  }

  Future<void> refreshDevices() async {
    // Clear temporary discovered list and trigger UDP refresh broadcast
    _discoveredDevices.clear();
    _discoveredDevicesController.add(_discoveredDevices);
    
    final selfModel = await _identity.toModel();
    await _connectionManager.startDiscovery(selfModel);
    
    await _logger.info('DeviceManager', 'Refreshed discovered devices');
  }

  void _checkOnlineStatus() {
    final threshold = DateTime.now().subtract(const Duration(seconds: 15));
    bool changed = false;

    for (int i = 0; i < _pairedDevices.length; i++) {
      final dev = _pairedDevices[i];
      if (dev.connectionStatus == 'Online' && dev.lastSeen.isBefore(threshold)) {
        _pairedDevices[i] = dev.copyWith(connectionStatus: 'Offline');
        changed = true;
      }
    }

    if (changed) {
      _pairedDevicesController.add(_pairedDevices);
    }
  }

  // Simulation mode support for automated testing
  void setSimulationMode(bool enabled) {
    _connectionManager.isSimulationMode = enabled;
  }

  void dispose() {
    _statusCheckTimer?.cancel();
    _pairedDevicesController.close();
    _discoveredDevicesController.close();
    _connectionManager.stop();
  }
}
