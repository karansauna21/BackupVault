import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backup_engine.dart';
import '../restore/restore_engine.dart';
import '../copy_engine/copy_job.dart';
import '../copy_engine/copy_queue.dart';
import '../restore/restore_queue.dart';
import '../restore/restore_job.dart';
import 'folder_watcher.dart';
import 'logging_service.dart';
import '../repositories/repository_providers.dart';
import '../models/notification_models.dart';
import '../../shared/providers/notification_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../models/background_models.dart';
import '../repositories/background_repository.dart';
import 'platform_info.dart';
import 'storage_provider.dart';

class BackgroundService {
  final Ref _ref;
  final BackgroundRepository _repository;
  final LoggingService _logger;
  final PlatformInfo _platformInfo;
  final StorageProvider _storageProvider;

  Timer? _monitorTimer;
  DateTime? _lastTickTime;
  DateTime _lastSpeedCheckTime = DateTime.now();
  int _lastBytesSaved = 0;
  String _currentSpeed = '0 KB/s';
  bool _isPaused = false;

  BackgroundState _backgroundState = const BackgroundState();
  TrayState _trayState = const TrayState();
  StartupState _startupState = const StartupState();
  WindowState _windowState = const WindowState();
  RunningServicesState _servicesState = const RunningServicesState();
  CrashState _crashState = const CrashState();

  // Callbacks for UI updates
  void Function(BackgroundState)? onStateChanged;
  void Function(TrayState)? onTrayChanged;
  void Function(StartupState)? onStartupChanged;
  void Function(WindowState)? onWindowChanged;
  void Function(RunningServicesState)? onServicesChanged;
  void Function(CrashState)? onCrashChanged;

  BackgroundService(
    this._ref,
    this._repository,
    this._logger,
    this._platformInfo,
    this._storageProvider,
  );

  BackgroundState get backgroundState => _backgroundState;
  TrayState get trayState => _trayState;
  StartupState get startupState => _startupState;
  WindowState get windowState => _windowState;
  RunningServicesState get servicesState => _servicesState;
  CrashState get crashState => _crashState;
  bool get isPaused => _isPaused;

  Future<void> start() async {
    if (_backgroundState.isRunning) return;

    await _logger.info('BackgroundService', 'Starting BackupVault Background Services...');

    if (Platform.isAndroid) {
      try {
        await const MethodChannel('com.backupvault.backup_vault/foreground_service')
            .invokeMethod('startService', {'message': 'Auto backup active'});
      } catch (e) {
        await _logger.error('BackgroundService', 'Failed to start Android Foreground Service: $e');
      }
    }

    // Load persisted state
    _startupState = await _repository.loadStartupState();
    _windowState = await _repository.loadWindowState();

    // Check if recovery is needed (previous session interrupted)
    final pendingBackups = await _repository.loadPendingQueue();
    final pendingRestores = await _repository.loadPendingRestoreQueue();
    final wasInterrupted = pendingBackups.isNotEmpty || pendingRestores.isNotEmpty;

    _backgroundState = BackgroundState(
      isRunning: true,
      statusMessage: wasInterrupted ? 'Recovering previous session...' : 'Running...',
      lastActiveTime: DateTime.now(),
    );
    onStateChanged?.call(_backgroundState);
    onStartupChanged?.call(_startupState);
    onWindowChanged?.call(_windowState);

    // Initial health check
    await _performHealthCheck();

    // Start background monitor ticker (Runs every 2 seconds)
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _onMonitorTick();
    });

    if (wasInterrupted) {
      await _handleCrashRecovery(pendingBackups, pendingRestores);
    }
  }

  Future<void> stop() async {
    _monitorTimer?.cancel();
    _monitorTimer = null;

    if (Platform.isAndroid) {
      try {
        await const MethodChannel('com.backupvault.backup_vault/foreground_service')
            .invokeMethod('stopService');
      } catch (e) {
        await _logger.error('BackgroundService', 'Failed to stop Android Foreground Service: $e');
      }
    }

    // Save final state
    await _repository.saveWindowState(_windowState);
    await _repository.saveStartupState(_startupState);

    // Clear queue persistence (normal shutdown doesn't need crash recovery)
    await _repository.savePendingQueue([]);
    await _repository.savePendingRestoreQueue([]);

    _backgroundState = const BackgroundState(
      isRunning: false,
      statusMessage: 'Stopped',
    );
    onStateChanged?.call(_backgroundState);

    await _logger.info('BackgroundService', 'Background Services stopped successfully.');
  }

  // --- External Control APIs ---

  void pauseBackup() {
    if (_isPaused) return;
    _isPaused = true;
    _ref.read(copyQueueProvider.notifier).pauseQueue();
    _ref.read(restoreQueueProvider.notifier).pauseQueue();

    _backgroundState = _backgroundState.copyWith(
      isPaused: true,
      statusMessage: 'Paused',
    );
    onStateChanged?.call(_backgroundState);
    _logger.info('BackgroundService', 'Backup processing paused.');
  }

  void resumeBackup() {
    if (!_isPaused) return;
    _isPaused = false;
    _ref.read(copyQueueProvider.notifier).resumeQueue();
    _ref.read(restoreQueueProvider.notifier).resumeQueue();

    _backgroundState = _backgroundState.copyWith(
      isPaused: false,
      statusMessage: 'Running...',
    );
    onStateChanged?.call(_backgroundState);
    _logger.info('BackgroundService', 'Backup processing resumed.');
  }

  Future<void> updateStartupConfig(StartupState newState) async {
    _startupState = newState;
    await _repository.saveStartupState(_startupState);
    onStartupChanged?.call(_startupState);
  }

  Future<void> updateWindowState(WindowState newState) async {
    _windowState = newState;
    await _repository.saveWindowState(_windowState);
    onWindowChanged?.call(_windowState);
  }

  // --- Crash Recovery Logic ---

  Future<void> _handleCrashRecovery(
    List<Map<String, dynamic>> pendingBackups,
    List<Map<String, dynamic>> pendingRestores,
  ) async {
    await _logger.warning('BackgroundService', 'Crash detected! Recovering active tasks...');
    _crashState = const CrashState(
      isCrashed: true,
      lastCrashTime: null,
    );
    onCrashChanged?.call(_crashState);

    try {
      final settings = _ref.read(settingsProvider);
      if (settings.security.autoRepairInterruptedBackups) {
        // Re-inject backup queue jobs
        final backupJobs = pendingBackups.map((map) => CopyJob(
          id: map['id'],
          folderId: map['folderId'],
          folderName: map['folderName'] ?? '',
          sourcePath: map['sourcePath'],
          destinationPath: map['destinationPath'],
          fileSize: map['fileSize'] ?? 0,
          retryCount: map['retryCount'] ?? 0,
          status: CopyStatus.pending,
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
          status: RestoreStatus.pending,
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
      if (diff > 6) {
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

    // 2. Battery & Power Monitoring
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
    await _updateTrayState();

    // 6. Queue checkpointing (for crash recovery)
    await _saveQueueCheckpoint();
  }

  bool _checkIfRunningOnBattery() {
    return !_platformInfo.isCharging;
  }

  Future<void> _performHealthCheck() async {
    bool backupEngineOk = false;
    bool restoreEngineOk = false;
    bool folderWatcherOk = false;
    bool notificationServiceOk = false;
    bool databaseOk = false;
    bool queueOk = false;

    try {
      final folders = await _ref.read(backupFolderRepositoryProvider).getAllFolders();
      databaseOk = true;

      _ref.read(backupEngineProvider);
      backupEngineOk = true;
      _ref.read(restoreEngineProvider);
      restoreEngineOk = true;

      final watcher = _ref.read(folderWatcherProvider);
      folderWatcherOk = true;
      for (final folder in folders) {
        if (folder.enabled && !watcher.isWatching(folder.id)) {
          _ref.read(backupEngineProvider).enableFolderWatching(folder);
        }
      }

      _ref.read(notificationServiceProvider);
      notificationServiceOk = true;

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
    final space = await _storageProvider.getDiskFreeSpace(destPath);
    
    if (space != null && space['total'] != null && space['total']! > 0) {
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

  void _calculateSpeed() {
    final now = DateTime.now();
    final durationSec = now.difference(_lastSpeedCheckTime).inSeconds;
    if (durationSec <= 0) return;

    int currentBytes = 0;
    
    final backupJobs = _ref.read(copyQueueProvider);
    final activeBackupJob = backupJobs.where((j) => j.status == CopyStatus.copying).toList();
    for (final job in activeBackupJob) {
      currentBytes += (job.progress * job.fileSize).toInt();
    }

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

  Future<void> _updateTrayState() async {
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
    String storage = '0 GB / 0 GB';
    if (destPath.isNotEmpty) {
      final space = await _storageProvider.getDiskFreeSpace(destPath);
      if (space != null && space['total'] != null && space['total']! > 0) {
        final usedGb = (space['total']! - space['free']!) / (1024 * 1024 * 1024);
        final totalGb = space['total']! / (1024 * 1024 * 1024);
        storage = '${usedGb.toStringAsFixed(1)} GB / ${totalGb.toStringAsFixed(1)} GB';
      }
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
