import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_routes.dart';
import 'backup_engine.dart';
import 'logging_service.dart';
import '../../features/settings/settings_provider.dart';
import '../../shared/providers/platform_providers.dart';
import '../models/background_models.dart';
import '../repositories/background_repository.dart';
import '../../platform/windows/startup/auto_start_manager.dart';
import '../../platform/windows/startup/startup_manager.dart';
import '../../platform/windows/system_tray/system_tray_manager.dart';
import '../../platform/windows/ui/window_manager.dart';
import 'background_service.dart';
import '../../shared/providers/scheduler_provider.dart';
import '../backup_job/backup_scheduler.dart';

class BackgroundController extends Notifier<BackgroundModuleState> {
  late final BackgroundRepository _repository;
  AutoStartManager? _autoStartManager;
  StartupManager? _startupManager;
  SystemTrayManager? _trayManager;
  WindowManager? _windowManager;
  late final BackgroundService _backgroundService;

  @override
  BackgroundModuleState build() {
    return const BackgroundModuleState();
  }

  BackgroundService get backgroundService => _backgroundService;

  Future<void> init() async {
    final settingsDb = ref.read(settingsDatabaseProvider);
    _repository = BackgroundRepository(settingsDb);
    await _repository.init();

    final isWindows = Platform.isWindows;

    if (isWindows) {
      _autoStartManager = AutoStartManager();
      await _autoStartManager!.init();

      _startupManager = StartupManager(_autoStartManager!, _repository);
      await _startupManager!.init();
    }

    final initialStartupState = isWindows
        ? await _startupManager!.loadStartupState()
        : const StartupState();

    if (isWindows) {
      _windowManager = WindowManager(
        _repository,
        onStateChanged: (winState) {
          state = state.copyWith(window: winState);
        },
      );
      await _windowManager!.init();

      _trayManager = SystemTrayManager(
        onOpenDashboard: () async {
          await _windowManager?.showWindow();
          goRouter.go('/dashboard');
        },
        onPauseBackup: () => pauseBackup(),
        onResumeBackup: () => resumeBackup(),
        onStartBackup: () => startBackup(),
        onStopBackup: () => stopBackup(),
        onOpenBackupFolder: () => openBackupFolder(),
        onRestore: () async {
          await _windowManager?.showWindow();
          goRouter.go('/restore');
        },
        onLogs: () async {
          await _windowManager?.showWindow();
          goRouter.go('/logs');
        },
        onSettings: () async {
          await _windowManager?.showWindow();
          goRouter.go('/settings');
        },
        onExit: () => exitApp(),
      );
      await _trayManager!.init();
    }

    _backgroundService = BackgroundService(
      ref,
      _repository,
      ref.read(loggingServiceProvider),
      ref.read(platformInfoProvider),
      ref.read(storageProvider),
    );

    _backgroundService.onStateChanged = (bgState) {
      state = state.copyWith(background: bgState);
    };
    _backgroundService.onServicesChanged = (servState) {
      state = state.copyWith(services: servState);
    };
    _backgroundService.onTrayChanged = (trayState) {
      state = state.copyWith(tray: trayState);
      _trayManager?.updateTooltip(trayState);
      _trayManager?.updateMenu(
        isBackupRunning: trayState.currentStatus == 'Backing up',
        isPaused: trayState.currentStatus == 'Paused',
      );
    };
    _backgroundService.onCrashChanged = (crashState) {
      state = state.copyWith(crash: crashState);
    };

    state = state.copyWith(
      startup: initialStartupState,
      window: isWindows ? _windowManager!.currentState : const WindowState(),
    );

    if (isWindows && initialStartupState.isEnabled) {
      if (initialStartupState.startInSystemTray) {
        await _windowManager?.hideWindow();
      } else if (initialStartupState.startMinimized) {
        await _windowManager?.minimizeWindow();
      }
    }

    await _backgroundService.start();

    try {
      final schedulerRepo = ref.read(schedulerRepositoryProvider);
      await schedulerRepo.init();
      final backupEngine = ref.read(backupEngineProvider);
      await ref
          .read(schedulerJobManagerProvider.notifier)
          .init(schedulerRepo, backupEngine);
      await ref.read(schedulerEngineProvider).init();
      
      // Start the backup job scheduler
      ref.read(backupSchedulerProvider).start();
    } catch (_) {}

    if (isWindows && initialStartupState.restorePreviousSession) {
      await _startupManager?.executeDelayedStartup(
        initialStartupState,
        () {
          ref.read(backupEngineProvider).start();
        },
        (remaining) {
          state = state.copyWith(
            startup: state.startup.copyWith(
              isDelayActive: true,
              startupDelaySeconds: remaining,
            ),
          );
        },
      );
    }
  }

  void pauseBackup() {
    _backgroundService.pauseBackup();
  }

  void resumeBackup() {
    _backgroundService.resumeBackup();
  }

  void startBackup() {
    ref.read(backupEngineProvider).start();
  }

  void stopBackup() {
    ref.read(backupEngineProvider).stop();
  }

  Future<void> openBackupFolder() async {
    final settings = ref.read(settingsProvider);
    final path = settings.backup.defaultBackupDestination;
    if (path.isNotEmpty && await Directory(path).exists()) {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [path]);
      }
    }
  }

  Future<void> updateStartupSettings({
    required bool enabled,
    required bool startMinimized,
    required bool startInSystemTray,
    required bool restorePreviousSession,
    required int startupDelaySeconds,
  }) async {
    if (!Platform.isWindows) return;
    final newState = await _startupManager!.updateStartupSettings(
      enabled: enabled,
      startMinimized: startMinimized,
      startInSystemTray: startInSystemTray,
      restorePreviousSession: restorePreviousSession,
      startupDelaySeconds: startupDelaySeconds,
    );
    state = state.copyWith(startup: newState);
  }

  Future<void> startService() async {
    await _backgroundService.start();
  }

  Future<void> stopService() async {
    await _backgroundService.stop();
  }

  Future<void> exitApp() async {
    await _backgroundService.stop();
    if (Platform.isWindows) {
      await _windowManager?.forceExit();
    } else {
      exit(0);
    }
  }
}
