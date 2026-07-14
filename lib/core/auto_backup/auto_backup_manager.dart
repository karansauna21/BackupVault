import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../file_watcher/file_event.dart';
import '../repositories/device_repository.dart';
import '../services/logging_service.dart';
import '../services/backup_engine.dart';
import '../../features/settings/settings_database.dart';
import 'device_selection_manager.dart';
import 'sync_queue.dart';
import 'transfer_scheduler.dart';

class AutoBackupManager {
  final SettingsDatabase db;
  final DeviceRepository deviceRepository;
  final LoggingService logger;
  final DeviceSelectionManager selectionManager;
  final SyncQueue queue;
  final TransferScheduler scheduler;
  final BackupEngine backupEngine;

  StreamSubscription<FileEvent>? _watcherSubscription;

  AutoBackupManager({
    required this.db,
    required this.deviceRepository,
    required this.logger,
    required this.selectionManager,
    required this.queue,
    required this.scheduler,
    required this.backupEngine,
  });

  void init() {
    scheduler.start();
    _watcherSubscription = backupEngine.onWatcherEvent.listen((event) {
      handleFileEvent(event);
    });
    logger.info('AutoBackupManager', 'Automatic backup manager initialized.');
  }

  void dispose() {
    scheduler.stop();
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
  }

  /// Intercepts and processes file events from FolderMonitor
  Future<void> handleFileEvent(FileEvent event) async {
    final enabled = db.getValue('auto_backup_enabled') == 'true';
    if (!enabled) return;

    // Check if this event represents a new, modified, renamed, or deleted file
    final isTargetEvent = event.type == FileEventType.newFile ||
                          event.type == FileEventType.modifiedFile ||
                          event.type == FileEventType.renamedFile ||
                          event.type == FileEventType.movedFile ||
                          event.type == FileEventType.deletedFile;

    if (!isTargetEvent || event.isDir) return;

    final targetPath = event.type == FileEventType.renamedFile || event.type == FileEventType.movedFile
        ? event.destinationPath
        : event.path;

    if (targetPath == null) return;
    final isDeleted = event.type == FileEventType.deletedFile;
    if (!isDeleted && !File(targetPath).existsSync()) return;

    // Retrieve active destination devices selected by the user
    final selectedDevices = selectionManager.getSelectedDestinationDeviceIds();
    if (selectedDevices.isEmpty) return;

    final size = isDeleted ? 0 : await File(targetPath).length();
    final fileName = p.basename(targetPath);

    logger.info('AutoBackupManager', 'Watcher event detected: ${event.type}. Queueing $fileName for ${selectedDevices.length} destination devices.');

    // Add transfer queue items
    for (final deviceId in selectedDevices) {
      final queueItem = QueueItem(
        id: const Uuid().v4(),
        filePath: targetPath,
        fileName: fileName,
        fileSize: size,
        destDeviceId: deviceId,
        addedAt: DateTime.now(),
        priority: 1, // Normal priority by default
        status: isDeleted ? 'completed' : 'waiting',
      );
      queue.enqueue(queueItem);
    }
  }

  // --- Queue Actions ---

  void pauseBackup() {
    queue.pause();
    logger.info('AutoBackupManager', 'Auto backup queue paused.');
  }

  void resumeBackup() {
    queue.resume();
    logger.info('AutoBackupManager', 'Auto backup queue resumed.');
  }

  void retryItem(String itemId) {
    queue.retry(itemId);
    logger.info('AutoBackupManager', 'Retry triggered for queue item $itemId.');
  }

  void cancelItem(String itemId) {
    queue.cancel(itemId);
    logger.info('AutoBackupManager', 'Cancelled queue item $itemId.');
  }

  void updatePriority(String itemId, int priority) {
    queue.updatePriority(itemId, priority);
  }

  // --- Settings Getters & Setters ---

  bool get isAutoBackupEnabled => db.getValue('auto_backup_enabled') == 'true';

  void setAutoBackupEnabled(bool enabled) {
    db.setValue('auto_backup_enabled', enabled ? 'true' : 'false');
    logger.info('AutoBackupManager', 'Auto Backup settings: setAutoBackupEnabled = $enabled');
  }

  bool get backupOnlyWhileCharging => db.getValue('auto_backup_charging_only') == 'true';

  void setBackupOnlyWhileCharging(bool charging) {
    db.setValue('auto_backup_charging_only', charging ? 'true' : 'false');
  }

  bool get backupOnlyOnWifi => db.getValue('auto_backup_wifi_only') == 'true';

  void setBackupOnlyOnWifi(bool wifi) {
    db.setValue('auto_backup_wifi_only', wifi ? 'true' : 'false');
  }

  int get bandwidthLimit => int.tryParse(db.getValue('auto_backup_bandwidth_limit') ?? '0') ?? 0;

  void setBandwidthLimit(int limitInKBs) {
    db.setValue('auto_backup_bandwidth_limit', limitInKBs.toString());
  }

  int get retryCount => int.tryParse(db.getValue('auto_backup_retry_count') ?? '3') ?? 3;

  void setRetryCount(int count) {
    db.setValue('auto_backup_retry_count', count.toString());
  }

  // --- Dashboard Statistics Getter ---

  Map<String, dynamic> getDashboardStats() {
    final pendingCount = queue.items.where((i) => i.status == 'waiting').length;
    final syncingItems = queue.items.where((i) => i.status == 'syncing').toList();
    final filesRemaining = pendingCount + syncingItems.length;

    double speed = 0.0;
    int eta = 0;
    String? currentFile;
    String? currentFolder;
    
    // Sum active session metrics
    for (final session in scheduler.activeSessions.values) {
      if (session.status == 'Syncing') {
        speed += session.currentSpeed;
        eta = session.etaSeconds > eta ? session.etaSeconds : eta;
        currentFile = session.currentFile;
      }
    }

    if (syncingItems.isNotEmpty) {
      final item = syncingItems.first;
      currentFolder = p.dirname(item.filePath);
    }

    final lastSyncStr = db.getValue('last_successful_sync');
    final lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

    final lastFailedStr = db.getValue('failed_sync');
    final lastFailed = lastFailedStr != null ? DateTime.tryParse(lastFailedStr) : null;

    // Compute overall status
    String overallStatus = 'Connected';
    if (!isAutoBackupEnabled) {
      overallStatus = 'Paused';
    } else if (syncingItems.isNotEmpty) {
      overallStatus = 'Syncing';
    } else if (pendingCount > 0) {
      overallStatus = 'Waiting';
    } else if (lastFailed != null && lastSync != null && lastFailed.isAfter(lastSync)) {
      overallStatus = 'Failed';
    }

    return {
      'connectedDevices': scheduler.activeSessions.length,
      'pendingFiles': pendingCount,
      'currentTransfer': currentFile ?? (syncingItems.isNotEmpty ? syncingItems.first.fileName : 'None'),
      'currentFolder': currentFolder ?? 'None',
      'filesRemaining': filesRemaining,
      'currentSpeed': speed, // bytes/sec
      'eta': eta, // seconds
      'lastSync': lastSync,
      'syncStatus': overallStatus,
    };
  }
}
