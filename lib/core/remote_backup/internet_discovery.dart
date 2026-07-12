// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import '../discovery/network_scanner.dart';
import '../services/logging_service.dart';
import '../repositories/device_repository.dart';

enum DeviceRoute {
  local,
  remote,
  offline
}

class InternetDiscovery {
  final NetworkScanner _networkScanner;
  final DeviceRepository _deviceRepository;
  final LoggingService _logger;

  final Map<String, DeviceRoute> _deviceRoutes = {};
  final StreamController<Map<String, DeviceRoute>> _routeController = StreamController.broadcast();

  Timer? _monitoringTimer;
  final List<String> _locallyDiscoveredDeviceIds = [];

  InternetDiscovery({
    required NetworkScanner networkScanner,
    required DeviceRepository deviceRepository,
    required LoggingService logger,
  })  : _networkScanner = networkScanner,
        _deviceRepository = deviceRepository,
        _logger = logger;

  Stream<Map<String, DeviceRoute>> get onRouteChanged => _routeController.stream;
  Map<String, DeviceRoute> get deviceRoutes => Map.unmodifiable(_deviceRoutes);

  void start() {
    _logger.info('InternetDiscovery', 'Starting Internet Discovery monitoring...');
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (_) => _evaluateRoutes());
    _evaluateRoutes();
  }

  void stop() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Update the list of devices discovered on the local network (LAN/Wi-Fi mDNS)
  void updateLocalDevices(List<String> deviceIds) {
    _locallyDiscoveredDeviceIds.clear();
    _locallyDiscoveredDeviceIds.addAll(deviceIds);
    _evaluateRoutes();
  }

  Future<bool> isInternetAvailable() async {
    final connType = await _networkScanner.getCurrentConnectionType();
    return connType != 'None' && connType.isNotEmpty;
  }

  Future<String> getConnectionType() async {
    return _networkScanner.getCurrentConnectionType();
  }

  Future<void> _evaluateRoutes() async {
    final connType = await _networkScanner.getCurrentConnectionType();
    final internetAvailable = connType != 'None' && connType.isNotEmpty;
    final devices = await _deviceRepository.getDevices();

    bool changed = false;
    for (final device in devices) {
      final oldRoute = _deviceRoutes[device.id] ?? DeviceRoute.offline;
      DeviceRoute newRoute = DeviceRoute.offline;

      if (_locallyDiscoveredDeviceIds.contains(device.id)) {
        newRoute = DeviceRoute.local;
      } else if (internetAvailable) {
        // If not found locally, but we have internet, they are reachable remotely
        newRoute = DeviceRoute.remote;
      }

      if (oldRoute != newRoute) {
        _deviceRoutes[device.id] = newRoute;
        changed = true;
        _logger.info('InternetDiscovery', 
          'Device ${device.name} route updated: $oldRoute -> $newRoute (Network: $connType)');
      }
    }

    if (changed && !_routeController.isClosed) {
      _routeController.add(Map.from(_deviceRoutes));
    }
  }

  void dispose() {
    stop();
    _routeController.close();
  }
}
