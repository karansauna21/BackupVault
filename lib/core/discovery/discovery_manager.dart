import 'dart:async';
import 'package:uuid/uuid.dart';

import '../services/logging_service.dart';
import 'discovery_models.dart';
import 'discovery_repository.dart';
import 'discovery_service.dart';

class DiscoveryManager {
  final DiscoveryRepository _repository;
  final DiscoveryService _service;
  final LoggingService _logger;

  final StreamController<List<DiscoveredDevice>> _deviceListController = StreamController.broadcast();
  final StreamController<List<DiscoveryHistoryEntry>> _historyController = StreamController.broadcast();

  List<DiscoveredDevice> _cachedDevices = [];
  List<DiscoveryHistoryEntry> _cachedHistory = [];
  bool _initialized = false;

  Stream<List<DiscoveredDevice>> get onDevicesChanged => _deviceListController.stream;
  Stream<List<DiscoveryHistoryEntry>> get onHistoryChanged => _historyController.stream;

  List<DiscoveredDevice> get devices => _cachedDevices;
  List<DiscoveryHistoryEntry> get history => _cachedHistory;

  DiscoveryManager(
    this._repository,
    this._service,
    this._logger,
  );

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load caches from DB
    _cachedDevices = await _repository.getKnownDevices();
    _cachedHistory = await _repository.getDiscoveryHistory();

    _deviceListController.add(_cachedDevices);
    _historyController.add(_cachedHistory);

    // Listen to changes from service
    _service.onDevicesChanged.listen((updatedList) async {
      _cachedDevices = updatedList;
      _deviceListController.add(_cachedDevices);
      
      // Reload history to capture new log events
      _cachedHistory = await _repository.getDiscoveryHistory();
      _historyController.add(_cachedHistory);
    });

    await _service.start();
    _logger.info('DiscoveryManager', 'Discovery Manager fully initialized and started.');
  }

  void dispose() {
    _service.stop();
  }

  Future<void> startDiscovery() async {
    await _service.start();
  }

  void stopDiscovery() {
    _service.stop();
  }

  Future<void> refresh() async {
    await _service.refresh();
  }

  Future<bool> pingDevice(String deviceId) async {
    _logger.info('DiscoveryManager', 'Manually pinging device $deviceId');
    final device = _cachedDevices.firstWhere((d) => d.device.id == deviceId);
    final stopwatch = Stopwatch()..start();
    final success = await _service.addDeviceManually(device.device.ipAddress, device.device.port);
    stopwatch.stop();

    await _repository.addHistoryEntry(DiscoveryHistoryEntry(
      id: const Uuid().v4(),
      deviceId: deviceId,
      deviceName: device.device.name,
      eventType: 'Reconnect Event',
      timestamp: DateTime.now(),
      ipAddress: device.device.ipAddress,
      details: success 
          ? 'Manual ping succeeded. Latency: ${stopwatch.elapsedMilliseconds} ms.'
          : 'Manual ping failed. Device is unreachable.',
    ));

    await refresh();
    return success;
  }

  Future<bool> connectDevice(String deviceId) async {
    _logger.info('DiscoveryManager', 'Connecting to device $deviceId');
    // Simulated connection state update (actual transfers not required)
    final index = _cachedDevices.indexWhere((d) => d.device.id == deviceId);
    if (index != -1) {
      final dev = _cachedDevices[index];
      final updated = dev.copyWith(
        isOnline: true,
        connectionQuality: ConnectionQuality.excellent,
      );
      _cachedDevices[index] = updated;
      _deviceListController.add(_cachedDevices);
      await _repository.saveKnownDevices(_cachedDevices);

      await _repository.addHistoryEntry(DiscoveryHistoryEntry(
        id: const Uuid().v4(),
        deviceId: deviceId,
        deviceName: dev.device.name,
        eventType: 'Reconnect Event',
        timestamp: DateTime.now(),
        ipAddress: dev.device.ipAddress,
        details: 'Connected successfully.',
      ));
      return true;
    }
    return false;
  }

  Future<void> disconnectDevice(String deviceId) async {
    _logger.info('DiscoveryManager', 'Disconnecting from device $deviceId');
    final index = _cachedDevices.indexWhere((d) => d.device.id == deviceId);
    if (index != -1) {
      final dev = _cachedDevices[index];
      final updated = dev.copyWith(
        isOnline: false,
        connectionQuality: ConnectionQuality.unreachable,
      );
      _cachedDevices[index] = updated;
      _deviceListController.add(_cachedDevices);
      await _repository.saveKnownDevices(_cachedDevices);

      await _repository.addHistoryEntry(DiscoveryHistoryEntry(
        id: const Uuid().v4(),
        deviceId: deviceId,
        deviceName: dev.device.name,
        eventType: 'Device Lost',
        timestamp: DateTime.now(),
        ipAddress: dev.device.ipAddress,
        details: 'Disconnected manually.',
      ));
    }
  }

  Future<bool> addManualDevice(String ip, int port) async {
    final success = await _service.addDeviceManually(ip, port);
    if (success) {
      _cachedHistory = await _repository.getDiscoveryHistory();
      _historyController.add(_cachedHistory);
    }
    return success;
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    _cachedHistory = [];
    _historyController.add(_cachedHistory);
  }
}
