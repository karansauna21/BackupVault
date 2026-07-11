import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_provider.dart';
import '../../shared/providers/device_provider.dart';
import '../services/logging_service.dart';
import 'discovery_manager.dart';
import 'discovery_repository.dart';
import 'discovery_service.dart';
import 'mdns_service.dart';
import 'bonjour_service.dart';
import 'network_scanner.dart';
import 'discovery_models.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  return DiscoveryRepository(db);
});

final mdnsServiceProvider = Provider<MdnsService>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  final identity = ref.watch(deviceIdentityProvider);
  return MdnsService(
    logger: logger,
    deviceId: identity.id,
    deviceName: identity.name,
    platform: identity.platform,
    appVersion: identity.appVersion,
    transportPort: 8321,
  );
});

final bonjourServiceProvider = Provider<BonjourService>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  final mdns = ref.watch(mdnsServiceProvider);
  return BonjourService(logger: logger, mdnsService: mdns);
});

final networkScannerProvider = Provider<NetworkScanner>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  final identity = ref.watch(deviceIdentityProvider);
  return NetworkScanner(
    logger: logger,
    deviceId: identity.id,
    deviceName: identity.name,
    platform: identity.platform,
    appVersion: identity.appVersion,
    transportPort: 8321,
  );
});

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final discoveryRepo = ref.watch(discoveryRepositoryProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final mdns = ref.watch(mdnsServiceProvider);
  final bonjour = ref.watch(bonjourServiceProvider);
  final scanner = ref.watch(networkScannerProvider);

  return DiscoveryService(
    discoveryRepository: discoveryRepo,
    deviceRepository: deviceRepo,
    logger: logger,
    mdnsService: mdns,
    bonjourService: bonjour,
    networkScanner: scanner,
  );
});

final discoveryManagerProvider = Provider<DiscoveryManager>((ref) {
  final discoveryRepo = ref.watch(discoveryRepositoryProvider);
  final service = ref.watch(discoveryServiceProvider);
  final logger = ref.watch(loggingServiceProvider);

  final manager = DiscoveryManager(
    discoveryRepo,
    service,
    logger,
  );
  
  // Auto-initialize Discovery Manager on startup
  manager.init();
  
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});

// StreamProvider for Discovered Devices list
final discoveredDevicesListStreamProvider = StreamProvider<List<DiscoveredDevice>>((ref) {
  final manager = ref.watch(discoveryManagerProvider);
  return manager.onDevicesChanged;
});

// StreamProvider for Discovery History entries
final discoveryHistoryStreamProvider = StreamProvider<List<DiscoveryHistoryEntry>>((ref) {
  final manager = ref.watch(discoveryManagerProvider);
  return manager.onHistoryChanged;
});
