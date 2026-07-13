import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_model.dart';
import '../../core/services/device_identity.dart';
import '../../core/repositories/device_repository.dart';
import '../../core/services/connection_manager.dart';
import '../../core/services/device_pairing_service.dart';
import '../../core/services/device_manager.dart';
import '../../features/settings/settings_provider.dart';
import '../../core/services/logging_service.dart';
import '../../core/database/database_provider.dart';
import 'platform_providers.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  final driftDb = ref.watch(databaseProvider);
  return DeviceRepository(db, driftDb);
});

final deviceIdentityProvider = Provider<DeviceIdentity>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  final storage = ref.watch(storageProvider);
  return DeviceIdentity(db, storage);
});

final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  return ConnectionManager(logger);
});

final devicePairingServiceProvider = Provider<DevicePairingService>((ref) {
  final repo = ref.watch(deviceRepositoryProvider);
  final identity = ref.watch(deviceIdentityProvider);
  final conn = ref.watch(connectionManagerProvider);
  final logger = ref.watch(loggingServiceProvider);
  return DevicePairingService(repo, identity, conn, logger, ref);
});

final deviceManagerProvider = Provider<DeviceManager>((ref) {
  final repo = ref.watch(deviceRepositoryProvider);
  final identity = ref.watch(deviceIdentityProvider);
  final conn = ref.watch(connectionManagerProvider);
  final logger = ref.watch(loggingServiceProvider);
  
  final manager = DeviceManager(repo, identity, conn, logger);
  // Auto-init
  manager.init();
  ref.onDispose(() => manager.dispose());
  return manager;
});

// StreamProvider for Paired Devices
final pairedDevicesStreamProvider = StreamProvider<List<DeviceModel>>((ref) {
  final manager = ref.watch(deviceManagerProvider);
  return manager.pairedDevicesStream;
});

// StreamProvider for Discovered Devices
final discoveredDevicesStreamProvider = StreamProvider<List<DeviceModel>>((ref) {
  final manager = ref.watch(deviceManagerProvider);
  return manager.discoveredDevicesStream;
});

// StreamProvider for Pending Requests
final pendingRequestsStreamProvider = StreamProvider<List<PendingPairingRequest>>((ref) {
  final pairing = ref.watch(devicePairingServiceProvider);
  return pairing.pendingRequestsStream;
});
