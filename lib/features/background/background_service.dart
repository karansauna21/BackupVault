import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win32/win32.dart';

import '../../core/services/backup_engine.dart';
import '../../core/restore/restore_engine.dart';
import '../../core/copy_engine/copy_job.dart';
import '../../core/copy_engine/copy_queue.dart';
import '../../core/restore/restore_queue.dart';
import '../../core/restore/restore_job.dart';
import '../../core/services/folder_watcher.dart';
import '../../core/services/logging_service.dart';
import '../../core/repositories/repository_providers.dart';
import '../notifications/notification_models.dart';
import '../notifications/notification_provider.dart';
import '../settings/settings_provider.dart';
import 'background_models.dart';
import 'background_repository.dart';

class BackgroundService {
  final Ref _ref;
  final BackgroundRepository _repository;
  final LoggingService _logger;

  Timer? _monitorTimer;
  DateTime? _lastTickTime;
  bool _isPaused = false;
  bool _isRunning = false;

  // Running speed tracking
  int _lastBytesSaved = 0;
  DateTime _lastSpeedCheckTime = DateTime.now();
  String _currentSpeed = '0 KB/s';

  // State callbacks
  void Function(RunningServicesState state)? onServicesChanged;
  void Function(BackgroundState state)? onStateChanged;
  void Function(TrayState state)? onTrayChanged;
  void Function(CrashState state)? onCrashChanged;

  BackgroundState _backgroundState = const BackgroundState();
  RunningServicesState _servicesState = const RunningServicesState();
  TrayState _trayState = const TrayState();
  CrashState _crashState = const CrashState();

  BackgroundService(this._ref, this._repository, this._logger);

  BackgroundState get backgroundState => _backgroundState;
  RunningServicesState get servicesState => _servicesState;
  TrayState get trayState => _trayState;
  CrashState get crashState => _crashState;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    _isPaused = false;

    _backgroundState = _backgroundState.copyWith(
      isRunning: true,
      statusMessage: 'Background monitor active',
      lastActiveTime: DateTime.now(),
    );
    onStateChanged?.call(_backgroundState);

    await _logger.info('BackgroundService', 'Starting background service...');

    // Load and recover session
    await recoverFromCrash();

    // Start periodic health check loop (every 2 seconds)
    _lastTickTime = DateTime.now();
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) => _onMonitorTick());
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;

    _backgroundState = _backgroundState.copyWith(
      isRunning: false,
      statusMessage: 'Background monitor stopped',
      lastActiveTime: DateTime.now(),
    );
    onStateChanged?.call(_backgroundState);

    await _logger.info('BackgroundService', 'Stopped background service');
  }

  void pauseBackup() {
    _isPaused = true;
    _backgroundState = _backgroundState.copyWith(isPaused: true, statusMessage: 'Backups paused');
    onStateChanged?.call(_backgroundState);

    // Pause backup queue
    _ref.read(copyQueueProvider.notifier).pauseQueue();

    // Pause restore queue
    _ref.read(restoreQueueProvider.notifier).pauseQueue();

    _logger.warning('BackgroundService', 'Backup and Restore queues paused');
  }

  void resumeBackup() {
    _isPaused = false;
    _backgroundState = _backgroundState.copyWith(isPaused: false, statusMessage: 'Backups active');
    onStateChanged?.call(_backgroundState);

    // Resume backup queue
    _ref.read(copyQueueProvider.notifier).resumeQueue();

    // Resume restore queue
    _ref.read(restoreQueueProvider.notifier).resumeQueue();

    _logger.info('BackgroundService', 'Backup and Restore queues resumed');
  }

  Future<void> shutdown() async {
    await _logger.info('BackgroundService', 'System shutdown/exit detected. Gracefully saving state...');
    await _saveQueueCheckpoint();
    await stop();
  }

  Future<void> recoverFromCrash() async {
    try {
      final pendingBackups = await _repository.loadPendingQueue();
      final pendingRestores = await _repository.loadPendingRestoreQueue();

      if (pendingBackups.isNotEmpty || pendingRestores.isNotEmpty) {
        await _logger.warning('BackgroundService', 
          'Crash recovery triggered. Restoring ${pendingBackups.length} backups and ${pendingRestores.length} restores.');
        
        // Re-initialize files and watchers
        final backupEngine = _ref.read(backupEngineProvider);
        await backupEngine.start();

        // Restore backup queue
        final backupJobs = pendingBackups.map((map) => CopyJob(
          id: map['id'],
          folderId: map['folderId'],
          folderName: map['folderName'] ?? '',
          sourcePath: map['sourcePath'],
          destinationPath: map['destinationPath'],
          fileSize: map['fileSize'] ?? 0,
          retryCount: map['retryCount'] ?? 0,
          status: CopyStatus.pending, // Reset to pending to resume execution
          progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
          error: map['error'],
        )).toList();

        if (backupJobs.isNotEmpty) {
          _ref.read(copyQueueProvider.notifier).addJobs(backupJobs);
        }

        // Restore restore queue
        final restoreJobs = pendingRestores.map((map) => RestoreJob(
          id: map['id'],
          fileId: map['fileId'],
          sourceBackupPath: map['sourceBackupPath'],
          targetRestorePath: map['targetRestorePath'] ?? map['targetBackupPath'] ?? '',
          fileSize: map['fileSize'] ?? 0,
          versionNumber: map['versionNumber'] ?? 1,
          sha256: map['sha256'] ?? '',
          status: RestoreStatus.pending, // Reset to pending
          progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
          error: map['error'],
          retryCount: map['retryCount'] ?? 0,
        )).toList();

        if (restoreJobs.isNotEmpty) {
          _ref.read(restoreQueueProvider.notifier).addJobs(restoreJobs);
        }

        _crashState = _crashState.copyWith(
          isCrashed: false,
          recoverySuccessful: true,
          autoRecoveryAttempts: _crashState.autoRecoveryAttempts + 1,
        );
        onCrashChanged?.call(_crashState);

        await _ref.read(notificationServiceProvider).triggerNotification(
          priority: NotificationPriority.success,
          category: NotificationCategory.applicationStarted,
          message: 'BackupVault auto-recovered successfully after an unexpected exit.',
        );
      }
    } catch (e, stack) {
      await _logger.error('BackgroundService', 'Crash recovery failed: $e', stack.toString());
      _crashState = _crashState.copyWith(
        isCrashed: true,
        lastCrashTime: DateTime.now(),
        lastCrashReason: e.toString(),
        autoRecoveryAttempts: _crashState.autoRecoveryAttempts + 1,
        recoverySuccessful: false,
      );
      onCrashChanged?.call(_crashState);
    }
  }

  // --- Internals ---

  Future<void> _onMonitorTick() async {
    final now = DateTime.now();

    // 1. Sleep/Wake Detection
    if (_lastTickTime != null) {
      final diff = now.difference(_lastTickTime!).inSeconds;
      if (diff > 6) { // Tick is periodic every 2 seconds. A gap of > 6 seconds implies suspension.
        await _logger.warning('BackgroundService', 'System sleep detected. Slept for $diff seconds.');
        pauseBackup();
        
        await _logger.info('BackgroundService', 'System woke up. Resuming services...');
        resumeBackup();
        
        await _ref.read(notificationServiceProvider).triggerNotification(
          priority: NotificationPriority.information,
          category: NotificationCategory.applicationStarted,
          message: 'System resumed from sleep. Backup monitoring reconnected.',
        );
      }
    }
    _lastTickTime = now;

    // 2. Battery & Power Monitoring (Windows Only)
    final runningOnBattery = _checkIfRunningOnBattery();
    if (runningOnBattery != _backgroundState.isRunningOnBattery) {
      _backgroundState = _backgroundState.copyWith(isRunningOnBattery: runningOnBattery);
      onStateChanged?.call(_backgroundState);

      final settings = _ref.read(settingsProvider);
      final pauseOnBattery = settings.performance.powerSavingMode;

      if (runningOnBattery && pauseOnBattery) {
        pauseBackup();
        await _ref.read(notificationServiceProvider).triggerNotification(
          priority: NotificationPriority.warning,
          category: NotificationCategory.folderPaused,
          message: 'Backup paused: Running on battery power.',
        );
      } else if (!runningOnBattery && _isPaused && pauseOnBattery) {
        resumeBackup();
        await _ref.read(notificationServiceProvider).triggerNotification(
          priority: NotificationPriority.information,
          category: NotificationCategory.folderResumed,
          message: 'Backup resumed: Connected to AC power.',
        );
      }
    }

    // 3. Health check of components
    await _performHealthCheck();

    // 4. Storage Space Check
    await _checkStorageCapacity();

    // 5. Update Speed & Tray State
    _calculateSpeed();
    _updateTrayState();

    // 6. Queue checkpointing (for crash recovery)
    await _saveQueueCheckpoint();
  }

  bool _checkIfRunningOnBattery() {
    if (!Platform.isWindows) return false;
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      if (GetSystemPowerStatus(status) != 0) {
        return status.ref.ACLineStatus == 0; // 0 means offline (on battery)
      }
    } catch (_) {} finally {
      calloc.free(status);
    }
    return false;
  }

  Future<void> _performHealthCheck() async {
    bool backupEngineOk = false;
    bool restoreEngineOk = false;
    bool folderWatcherOk = false;
    bool notificationServiceOk = false;
    bool databaseOk = false;
    bool queueOk = false;

    try {
      // Check database
      final folders = await _ref.read(backupFolderRepositoryProvider).getAllFolders();
      databaseOk = true;

      // Check backup & restore engines
      _ref.read(backupEngineProvider);
      backupEngineOk = true;
      _ref.read(restoreEngineProvider);
      restoreEngineOk = true;

      // Check folder watcher health
      final watcher = _ref.read(folderWatcherProvider);
      folderWatcherOk = true;
      for (final folder in folders) {
        if (folder.enabled && !watcher.isWatching(folder.id)) {
          // Reconnect folder watcher
          _ref.read(backupEngineProvider).enableFolderWatching(folder);
        }
      }

      // Check notification service
      _ref.read(notificationServiceProvider);
      notificationServiceOk = true;

      // Check queues
      _ref.read(copyQueueProvider);
      _ref.read(restoreQueueProvider);
      queueOk = true;

    } catch (e, stack) {
      await _logger.error('BackgroundService', 'Health check failed: $e', stack.toString());
      
      await _ref.read(notificationServiceProvider).triggerNotification(
        priority: NotificationPriority.critical,
        category: NotificationCategory.databaseError,
        message: 'Critical Background Health Alert: $e',
      );
    }

    _servicesState = RunningServicesState(
      backupEngine: backupEngineOk,
      restoreEngine: restoreEngineOk,
      folderWatcher: folderWatcherOk,
      notificationService: notificationServiceOk,
      database: databaseOk,
      queue: queueOk,
    );
    onServicesChanged?.call(_servicesState);
  }

  Future<void> _checkStorageCapacity() async {
    final settings = _ref.read(settingsProvider);
    if (settings.backup.defaultBackupDestination.isEmpty) return;

    final destPath = settings.backup.defaultBackupDestination;
    final space = _getDiskFreeSpace(destPath);
    
    if (space['total'] != null && space['total']! > 0) {
      final freeGb = space['free']! / (1024 * 1024 * 1024);
      final limitGb = settings.storage.minimumFreeSpaceGb;

      if (freeGb < limitGb) {
        if (!_isPaused && settings.storage.autoPauseWhenFull) {
          pauseBackup();
          await _ref.read(notificationServiceProvider).triggerNotification(
            priority: NotificationPriority.critical,
            category: NotificationCategory.storageFull,
            message: 'Backup suspended: Storage is full (${freeGb.toStringAsFixed(2)} GB free).',
          );
        } else if (settings.storage.lowStorageWarning) {
          await _ref.read(notificationServiceProvider).triggerNotification(
            priority: NotificationPriority.warning,
            category: NotificationCategory.lowStorage,
            message: 'Low disk space warning: ${freeGb.toStringAsFixed(2)} GB free.',
          );
        }
      }
    }
  }

  Map<String, int> _getDiskFreeSpace(String path) {
    if (!Platform.isWindows) return {'free': 100 * 1024 * 1024 * 1024, 'total': 500 * 1024 * 1024 * 1024};
    final lpFreeBytesAvailable = calloc<Uint64>();
    final lpTotalNumberOfBytes = calloc<Uint64>();
    final lpTotalNumberOfFreeBytes = calloc<Uint64>();

    try {
      final pathPtr = path.toNativeUtf16();
      final result = GetDiskFreeSpaceEx(
        pathPtr,
        lpFreeBytesAvailable.cast(),
        lpTotalNumberOfBytes.cast(),
        lpTotalNumberOfFreeBytes.cast(),
      );
      calloc.free(pathPtr);

      if (result != 0) {
        return {
          'free': lpFreeBytesAvailable.value,
          'total': lpTotalNumberOfBytes.value,
        };
      }
    } catch (_) {} finally {
      calloc.free(lpFreeBytesAvailable);
      calloc.free(lpTotalNumberOfBytes);
      calloc.free(lpTotalNumberOfFreeBytes);
    }
    return {'free': 0, 'total': 0};
  }

  void _calculateSpeed() {
    final now = DateTime.now();
    final durationSec = now.difference(_lastSpeedCheckTime).inSeconds;
    if (durationSec <= 0) return;

    int currentBytes = 0;
    
    // Sum active bytes of backup
    final backupJobs = _ref.read(copyQueueProvider);
    final activeBackupJob = backupJobs.where((j) => j.status == CopyStatus.copying).toList();
    for (final job in activeBackupJob) {
      currentBytes += (job.progress * job.fileSize).toInt();
    }

    // Sum active bytes of restore
    final restoreJobs = _ref.read(restoreQueueProvider);
    final activeRestoreJobs = restoreJobs.where((j) => j.status == RestoreStatus.restoring).toList();
    for (final job in activeRestoreJobs) {
      currentBytes += (job.progress * job.fileSize).toInt();
    }

    final diff = currentBytes - _lastBytesSaved;
    _lastBytesSaved = currentBytes;
    _lastSpeedCheckTime = now;

    if (diff <= 0) {
      _currentSpeed = '0 KB/s';
    } else {
      final speedKb = (diff / durationSec) / 1024;
      if (speedKb > 1024) {
        _currentSpeed = '${(speedKb / 1024).toStringAsFixed(1)} MB/s';
      } else {
        _currentSpeed = '${speedKb.toStringAsFixed(0)} KB/s';
      }
    }
  }

  void _updateTrayState() {
    final backupJobs = _ref.read(copyQueueProvider);
    final restoreJobs = _ref.read(restoreQueueProvider);

    final pendingBackups = backupJobs.where((j) => j.status == CopyStatus.pending || j.status == CopyStatus.copying).length;
    final pendingRestores = restoreJobs.where((j) => j.status == RestoreStatus.pending || j.status == RestoreStatus.restoring).length;

    String status = 'Idle';
    if (_isPaused) {
      status = 'Paused';
    } else if (pendingBackups > 0) {
      status = 'Backing up';
    } else if (pendingRestores > 0) {
      status = 'Restoring';
    }

    final settings = _ref.read(settingsProvider);
    final destPath = settings.backup.defaultBackupDestination;
    final space = _getDiskFreeSpace(destPath);
    String storage = '0 GB / 0 GB';
    if (space['total'] != null && space['total']! > 0) {
      final usedGb = (space['total']! - space['free']!) / (1024 * 1024 * 1024);
      final totalGb = space['total']! / (1024 * 1024 * 1024);
      storage = '${usedGb.toStringAsFixed(1)} GB / ${totalGb.toStringAsFixed(1)} GB';
    }

    _trayState = TrayState(
      currentStatus: status,
      filesRemaining: pendingBackups + pendingRestores,
      currentSpeed: _currentSpeed,
      storageUsage: storage,
      isVisible: true,
    );
    onTrayChanged?.call(_trayState);
  }

  Future<void> _saveQueueCheckpoint() async {
    final backupJobs = _ref.read(copyQueueProvider).where((j) => j.status == CopyStatus.pending || j.status == CopyStatus.copying).toList();
    final restoreJobs = _ref.read(restoreQueueProvider).where((j) => j.status == RestoreStatus.pending || j.status == RestoreStatus.restoring).toList();

    final backupMaps = backupJobs.map((j) => {
      'id': j.id,
      'folderId': j.folderId,
      'folderName': j.folderName,
      'sourcePath': j.sourcePath,
      'destinationPath': j.destinationPath,
      'fileSize': j.fileSize,
      'retryCount': j.retryCount,
      'status': j.status.index,
      'progress': j.progress,
      'error': j.error,
    }).toList();

    final restoreMaps = restoreJobs.map((j) => {
      'id': j.id,
      'fileId': j.fileId,
      'sourceBackupPath': j.sourceBackupPath,
      'targetRestorePath': j.targetRestorePath,
      'fileSize': j.fileSize,
      'versionNumber': j.versionNumber,
      'status': j.status.index,
      'progress': j.progress,
      'error': j.error,
      'retryCount': j.retryCount,
      'sha256': j.sha256,
    }).toList();

    await _repository.savePendingQueue(backupMaps);
    await _repository.savePendingRestoreQueue(restoreMaps);
  }
}
