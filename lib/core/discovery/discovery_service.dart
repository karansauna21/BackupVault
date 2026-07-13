// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:uuid/uuid.dart';

import '../services/logging_service.dart';
import '../repositories/device_repository.dart';
import '../models/device_model.dart';
import 'discovery_models.dart';
import 'discovery_repository.dart';
import 'mdns_service.dart';
import 'bonjour_service.dart';
import 'network_scanner.dart';

class DiscoveryService {
  final DiscoveryRepository _discoveryRepository;
  final DeviceRepository _deviceRepository;
  final LoggingService _logger;
  final MdnsService _mdnsService;
  final BonjourService _bonjourService;
  final NetworkScanner _networkScanner;

  final StreamController<List<DiscoveredDevice>> _devicesStreamController = StreamController.broadcast();
  final Map<String, DiscoveredDevice> _discoveredDevices = {};
  Timer? _healthCheckTimer;
  Duration _healthCheckInterval = const Duration(seconds: 15);
  bool _isRunning = false;

  Stream<List<DiscoveredDevice>> get onDevicesChanged => _devicesStreamController.stream;
  List<DiscoveredDevice> get discoveredDevicesList => _discoveredDevices.values.toList();
  Duration get healthCheckInterval => _healthCheckInterval;

  DiscoveryService({
    required DiscoveryRepository discoveryRepository,
    required DeviceRepository deviceRepository,
    required LoggingService logger,
    required MdnsService mdnsService,
    required BonjourService bonjourService,
    required NetworkScanner networkScanner,
  })  : _discoveryRepository = discoveryRepository,
        _deviceRepository = deviceRepository,
        _logger = logger,
        _mdnsService = mdnsService,
        _bonjourService = bonjourService,
        _networkScanner = networkScanner;

  void setHealthCheckInterval(Duration duration) {
    _healthCheckInterval = duration;
    if (_isRunning) {
      _startHealthCheckTimer();
    }
  }

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Load initial known devices
    final known = await _discoveryRepository.getKnownDevices();
    for (final dev in known) {
      // Mark as initially offline/unreachable until scanned
      _discoveredDevices[dev.device.id] = dev.copyWith(
        isOnline: false,
        connectionQuality: ConnectionQuality.unreachable,
        latencyMs: null,
      );
    }
    _devicesStreamController.add(discoveredDevicesList);

    // Listen to mDNS discovery
    _mdnsService.onDeviceDiscovered.listen(_onDeviceDiscovered);

    // Listen to UDP Broadcast discovery
    _networkScanner.onDeviceDiscovered.listen(_onDeviceDiscovered);

    // Register Bonjour service and start mDNS/broadcast advertising
    await _bonjourService.registerService();
    await _networkScanner.start();

    // Start health check pings
    _startHealthCheckTimer();

    _logger.info('DiscoveryService', 'Network discovery service fully initialized.');
  }

  void stop() {
    _isRunning = false;
    _healthCheckTimer?.cancel();
    _bonjourService.unregisterService();
    _networkScanner.stop();
    _logger.info('DiscoveryService', 'Stopped Network discovery service.');
  }

  Future<void> refresh() async {
    _logger.info('DiscoveryService', 'Manually triggering network discovery refresh.');
    _mdnsService.query();
    await _networkScanner.broadcastPresence();
    await runHealthCheck();
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) {
      runHealthCheck();
    });
  }

  Future<void> runHealthCheck() async {
    if (!_isRunning) return;

    final pairedDevices = await _deviceRepository.getDevices();
    final connectionType = await _networkScanner.getCurrentConnectionType();

    for (final paired in pairedDevices) {
      // Check if we already have it in discovery cache, else create initial entry
      var current = _discoveredDevices[paired.id] ?? DiscoveredDevice(
        device: paired,
        isOnline: false,
        connectionType: connectionType,
        connectionQuality: ConnectionQuality.unreachable,
        lastSeen: DateTime.now().subtract(const Duration(days: 30)),
      );

      final ipToPing = current.device.ipAddress.isNotEmpty ? current.device.ipAddress : paired.ipAddress;
      final portToPing = current.device.port > 0 ? current.device.port : paired.port;

      if (ipToPing.isEmpty || ipToPing == '0.0.0.0') {
        // No IP address available yet
        continue;
      }

      final stopwatch = Stopwatch()..start();
      final success = await _networkScanner.pingAddress(ipToPing, portToPing);
      stopwatch.stop();

      final oldOnline = current.isOnline;
      final newOnline = success;

      int? latency;
      ConnectionQuality quality;

      if (success) {
        latency = stopwatch.elapsedMilliseconds;
        if (latency < 100) {
          quality = ConnectionQuality.excellent;
        } else if (latency < 250) {
          quality = ConnectionQuality.good;
        } else if (latency < 500) {
          quality = ConnectionQuality.highLatency;
        } else {
          quality = ConnectionQuality.poor;
        }
      } else {
        quality = ConnectionQuality.unreachable;
      }

      current = current.copyWith(
        isOnline: newOnline,
        latencyMs: latency,
        connectionQuality: quality,
        lastSeen: newOnline ? DateTime.now() : current.lastSeen,
        connectionType: connectionType,
      );

      _discoveredDevices[paired.id] = current;

      // Handle logs and state changes
      if (!oldOnline && newOnline) {
        _logger.info('DiscoveryService', 'Device online: ${paired.name} ($ipToPing)');
        await _discoveryRepository.addHistoryEntry(DiscoveryHistoryEntry(
          id: const Uuid().v4(),
          deviceId: paired.id,
          deviceName: paired.name,
          eventType: 'Device Found',
          timestamp: DateTime.now(),
          ipAddress: ipToPing,
          details: 'Discovered device on subnet with latency $latency ms ($quality)',
        ));
      } else if (oldOnline && !newOnline) {
        _logger.warning('DiscoveryService', 'Device offline: ${paired.name}');
        await _discoveryRepository.addHistoryEntry(DiscoveryHistoryEntry(
          id: const Uuid().v4(),
          deviceId: paired.id,
          deviceName: paired.name,
          eventType: 'Device Lost',
          timestamp: DateTime.now(),
          ipAddress: ipToPing,
          details: 'Device unreachable during heartbeat check.',
        ));
      }
    }

    // Save updated state to persistent database
    await _discoveryRepository.saveKnownDevices(discoveredDevicesList);

    // Notify listeners
    _devicesStreamController.add(discoveredDevicesList);
  }

  Future<void> _onDeviceDiscovered(Map<String, dynamic> info) async {
    final String id = info['id'] as String;
    final String name = info['name'] as String;
    final String platform = info['platform'] as String;
    final String version = info['version'] as String;
    final String ip = info['ip'] as String;
    final int port = info['port'] as int;

    // Check if the device is paired
    final paired = await _deviceRepository.getDeviceById(id);
    final connectionType = await _networkScanner.getCurrentConnectionType();

    // Verify if IP or port changed
    if (paired != null) {
      final ipChanged = paired.ipAddress != ip || paired.port != port;
      if (ipChanged) {
        _logger.info('DiscoveryService', 'Device IP/Port changed: ${paired.name} is now at $ip:$port');
        final updatedDevice = paired.copyWith(ipAddress: ip, port: port, lastSeen: DateTime.now());
        await _deviceRepository.addOrUpdateDevice(updatedDevice);

        await _discoveryRepository.addHistoryEntry(DiscoveryHistoryEntry(
          id: const Uuid().v4(),
          deviceId: id,
          deviceName: name,
          eventType: 'Network Changed',
          timestamp: DateTime.now(),
          ipAddress: ip,
          details: 'IP or Port changed from ${paired.ipAddress}:${paired.port} to $ip:$port',
        ));
      }
    } else {
      _logger.info('DiscoveryService', 'Discovered unpaired nearby device: $name ($ip) | Platform: $platform | Version: $version');
    }

    // Perform validation and ping to compute quality metrics
    final stopwatch = Stopwatch()..start();
    final success = await _networkScanner.pingAddress(ip, port);
    stopwatch.stop();

    int? latency;
    ConnectionQuality quality;

    if (success) {
      latency = stopwatch.elapsedMilliseconds;
      if (latency < 100) {
        quality = ConnectionQuality.excellent;
      } else if (latency < 250) {
        quality = ConnectionQuality.good;
      } else if (latency < 500) {
        quality = ConnectionQuality.highLatency;
      } else {
        quality = ConnectionQuality.poor;
      }
    } else {
      quality = ConnectionQuality.unreachable;
    }

    final DeviceModel deviceModel = paired ?? DeviceModel(
      id: id,
      name: name,
      platform: platform,
      osVersion: version,
      appVersion: version,
      deviceModel: 'Generic',
      pairingDate: DateTime.fromMillisecondsSinceEpoch(0),
      lastSeen: DateTime.now(),
      trustStatus: 'Pending',
      connectionStatus: success ? 'Online' : 'Offline',
      ipAddress: ip,
      port: port,
      storageInfo: 'Unknown',
    );

    final current = DiscoveredDevice(
      device: deviceModel,
      isOnline: success,
      latencyMs: latency,
      connectionQuality: quality,
      lastSeen: success ? DateTime.now() : (paired?.lastSeen ?? DateTime.now()),
      connectionType: connectionType,
    );

    _discoveredDevices[id] = current;
    await _discoveryRepository.saveKnownDevices(discoveredDevicesList);
    _devicesStreamController.add(discoveredDevicesList);
  }

  /// Manually add a device IP address (Manual IP Entry fallback)
  Future<bool> addDeviceManually(String ip, int port) async {
    _logger.info('DiscoveryService', 'Attempting manual device connection check for $ip:$port');
    
    final success = await _networkScanner.pingAddress(ip, port);
    if (!success) {
      _logger.warning('DiscoveryService', 'Manual connection failed to $ip:$port');
      return false;
    }

    // Connect to the device to query its ID and name (mock/handshake or get existing paired device)
    // For manual fallback, we check if there's a paired device that matches this IP/Port
    final paired = await _deviceRepository.getDevices();
    DeviceModel? targetDevice;
    for (final dev in paired) {
      if (dev.ipAddress == ip && dev.port == port) {
        targetDevice = dev;
        break;
      }
    }

    if (targetDevice != null) {
      final discovered = DiscoveredDevice(
        device: targetDevice,
        isOnline: true,
        connectionType: 'Manual',
        connectionQuality: ConnectionQuality.excellent,
        lastSeen: DateTime.now(),
      );
      _discoveredDevices[targetDevice.id] = discovered;
      _devicesStreamController.add(discoveredDevicesList);
      await _discoveryRepository.saveKnownDevices(discoveredDevicesList);
      return true;
    }

    _logger.warning('DiscoveryService', 'Manual IP entered is reachable but device is not paired.');
    return true;
  }
}
