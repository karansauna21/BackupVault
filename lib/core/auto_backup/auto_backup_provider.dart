import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../discovery/discovery_provider.dart';
import '../services/logging_service.dart';
import '../transport/transport_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../shared/providers/device_provider.dart';

import '../services/backup_engine.dart';
import 'auto_backup_manager.dart';
import 'device_selection_manager.dart';
import 'sync_queue.dart';
import 'sync_session.dart';
import 'transfer_scheduler.dart';

import '../../shared/providers/platform_providers.dart';
import '../../shared/providers/notification_provider.dart';

import 'sync_queue_manager.dart';

final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueueManager();
});

final syncQueueManagerProvider = Provider<SyncQueueManager>((ref) {
  return ref.watch(syncQueueProvider) as SyncQueueManager;
});

final deviceSelectionManagerProvider = Provider<DeviceSelectionManager>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  return DeviceSelectionManager(db);
});

final transferSchedulerProvider = Provider<TransferScheduler>((ref) {
  final queue = ref.watch(syncQueueProvider);
  final transport = ref.watch(transportManagerProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final db = ref.watch(settingsDatabaseProvider);
  final scanner = ref.watch(networkScannerProvider);
  final platformInfo = ref.watch(platformInfoProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  final scheduler = TransferScheduler(
    queue: queue,
    transportManager: transport,
    deviceRepository: deviceRepo,
    logger: logger,
    db: db,
    networkScanner: scanner,
    platformInfo: platformInfo,
    notificationService: notificationService,
  );

  scheduler.start();
  
  ref.onDispose(() {
    scheduler.stop();
  });

  return scheduler;
});

final autoBackupManagerProvider = Provider<AutoBackupManager>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final selection = ref.watch(deviceSelectionManagerProvider);
  final queue = ref.watch(syncQueueProvider);
  final scheduler = ref.watch(transferSchedulerProvider);
  final backupEngine = ref.watch(backupEngineProvider);

  final manager = AutoBackupManager(
    db: db,
    deviceRepository: deviceRepo,
    logger: logger,
    selectionManager: selection,
    queue: queue,
    scheduler: scheduler,
    backupEngine: backupEngine,
  );

  manager.init();

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

// StreamProvider to watch queue modifications
final autoBackupQueueStreamProvider = StreamProvider<List<QueueItem>>((ref) {
  final queue = ref.watch(syncQueueProvider);
  return queue.onQueueChanged;
});

// StreamProvider to watch sync sessions updates
final autoBackupSessionsStreamProvider = StreamProvider<Map<String, SyncSession>>((ref) {
  final scheduler = ref.watch(transferSchedulerProvider);
  return scheduler.onSessionsChanged;
});

// Auto-updating provider for dashboard statistics
final autoBackupDashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final manager = ref.watch(autoBackupManagerProvider);
  // Watch queue and sessions stream providers to trigger rebuilds on state change
  ref.watch(autoBackupQueueStreamProvider);
  ref.watch(autoBackupSessionsStreamProvider);
  
  return manager.getDashboardStats();
});
