import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_provider.dart';
import '../../features/security/security_provider.dart';
import '../../shared/providers/device_provider.dart';
import '../services/logging_service.dart';
import '../services/backup_engine.dart';
import '../discovery/discovery_provider.dart';
import 'internet_discovery.dart';
import 'remote_connection_manager.dart';
import 'remote_transfer_queue.dart';
import 'remote_sync_manager.dart';
import 'remote_session.dart';

final internetDiscoveryProvider = Provider<InternetDiscovery>((ref) {
  final scanner = ref.watch(networkScannerProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);

  final discovery = InternetDiscovery(
    networkScanner: scanner,
    deviceRepository: deviceRepo,
    logger: logger,
  );

  discovery.start();

  ref.onDispose(() {
    discovery.dispose();
  });

  return discovery;
});

final remoteConnectionManagerProvider = Provider<RemoteConnectionManager>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final internetDiscovery = ref.watch(internetDiscoveryProvider);
  final encManager = ref.watch(encryptionManagerProvider);

  final manager = RemoteConnectionManager(
    db: db,
    deviceRepository: deviceRepo,
    logger: logger,
    internetDiscovery: internetDiscovery,
    encryptionManager: encManager,
  );

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

final remoteTransferQueueProvider = Provider<RemoteTransferQueue>((ref) {
  final queue = RemoteTransferQueue();
  ref.onDispose(() {
    queue.dispose();
  });
  return queue;
});

final remoteSyncManagerProvider = Provider<RemoteSyncManager>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  final logger = ref.watch(loggingServiceProvider);
  final internetDiscovery = ref.watch(internetDiscoveryProvider);
  final connectionManager = ref.watch(remoteConnectionManagerProvider);
  final queue = ref.watch(remoteTransferQueueProvider);
  final backupEngine = ref.watch(backupEngineProvider);

  final manager = RemoteSyncManager(
    db: db,
    logger: logger,
    internetDiscovery: internetDiscovery,
    connectionManager: connectionManager,
    queue: queue,
    backupEngine: backupEngine,
  );

  manager.start();

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

final remoteQueueStreamProvider = StreamProvider<List<RemoteQueueItem>>((ref) {
  final queue = ref.watch(remoteTransferQueueProvider);
  return queue.onQueueChanged;
});

final remoteSessionsStreamProvider = StreamProvider<Map<String, RemoteSession>>((ref) {
  final manager = ref.watch(remoteSyncManagerProvider);
  return manager.onSessionsChanged;
});

final remoteRoutesStreamProvider = StreamProvider<Map<String, DeviceRoute>>((ref) {
  final discovery = ref.watch(internetDiscoveryProvider);
  return discovery.onRouteChanged;
});

final remoteDashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final syncManager = ref.watch(remoteSyncManagerProvider);
  final queue = ref.watch(remoteTransferQueueProvider);
  final discovery = ref.watch(internetDiscoveryProvider);

  // Trigger rebuilds on stream changes
  ref.watch(remoteQueueStreamProvider);
  ref.watch(remoteSessionsStreamProvider);
  ref.watch(remoteRoutesStreamProvider);

  final remoteDevicesCount = discovery.deviceRoutes.values
      .where((r) => r == DeviceRoute.remote)
      .length;

  final pendingUploads = queue.items
      .where((i) => i.status == 'waiting' || i.status == 'syncing')
      .length;

  String currentUpload = 'None';
  double speed = 0.0;
  double progress = 0.0;

  if (syncManager.activeSessions.isNotEmpty) {
    final active = syncManager.activeSessions.values.first;
    currentUpload = active.currentProgress.currentFile;
    speed = active.currentProgress.speed;
    final total = active.currentProgress.totalBytes;
    if (total > 0) {
      progress = active.currentProgress.bytesTransferred / total;
    }
  }

  return {
    'remoteDevices': remoteDevicesCount,
    'currentUpload': currentUpload,
    'currentDownload': 'None',
    'internetSpeed': speed, // bytes/sec
    'syncProgress': progress, // 0.0 to 1.0
    'pendingUploads': pendingUploads,
  };
});
