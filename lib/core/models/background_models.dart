import 'package:flutter/foundation.dart';

@immutable
class BackgroundState {
  final bool isRunning;
  final bool isPaused;
  final String statusMessage;
  final DateTime? lastActiveTime;
  final bool isRunningOnBattery;
  final double cpuUsagePercent;
  final double ramUsageMb;

  const BackgroundState({
    this.isRunning = false,
    this.isPaused = false,
    this.statusMessage = 'Initializing...',
    this.lastActiveTime,
    this.isRunningOnBattery = false,
    this.cpuUsagePercent = 0.0,
    this.ramUsageMb = 0.0,
  });

  BackgroundState copyWith({
    bool? isRunning,
    bool? isPaused,
    String? statusMessage,
    DateTime? lastActiveTime,
    bool? isRunningOnBattery,
    double? cpuUsagePercent,
    double? ramUsageMb,
  }) {
    return BackgroundState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      statusMessage: statusMessage ?? this.statusMessage,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      isRunningOnBattery: isRunningOnBattery ?? this.isRunningOnBattery,
      cpuUsagePercent: cpuUsagePercent ?? this.cpuUsagePercent,
      ramUsageMb: ramUsageMb ?? this.ramUsageMb,
    );
  }
}

@immutable
class TrayState {
  final String currentStatus;
  final int filesRemaining;
  final String currentSpeed;
  final String storageUsage;
  final bool isVisible;

  const TrayState({
    this.currentStatus = 'Idle',
    this.filesRemaining = 0,
    this.currentSpeed = '0 KB/s',
    this.storageUsage = '0 GB / 0 GB',
    this.isVisible = false,
  });

  TrayState copyWith({
    String? currentStatus,
    int? filesRemaining,
    String? currentSpeed,
    String? storageUsage,
    bool? isVisible,
  }) {
    return TrayState(
      currentStatus: currentStatus ?? this.currentStatus,
      filesRemaining: filesRemaining ?? this.filesRemaining,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      storageUsage: storageUsage ?? this.storageUsage,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

@immutable
class StartupState {
  final bool isEnabled;
  final bool startMinimized;
  final bool startInSystemTray;
  final bool restorePreviousSession;
  final int startupDelaySeconds;
  final bool isDelayActive;

  const StartupState({
    this.isEnabled = false,
    this.startMinimized = false,
    this.startInSystemTray = false,
    this.restorePreviousSession = false,
    this.startupDelaySeconds = 0,
    this.isDelayActive = false,
  });

  StartupState copyWith({
    bool? isEnabled,
    bool? startMinimized,
    bool? startInSystemTray,
    bool? restorePreviousSession,
    int? startupDelaySeconds,
    bool? isDelayActive,
  }) {
    return StartupState(
      isEnabled: isEnabled ?? this.isEnabled,
      startMinimized: startMinimized ?? this.startMinimized,
      startInSystemTray: startInSystemTray ?? this.startInSystemTray,
      restorePreviousSession: restorePreviousSession ?? this.restorePreviousSession,
      startupDelaySeconds: startupDelaySeconds ?? this.startupDelaySeconds,
      isDelayActive: isDelayActive ?? this.isDelayActive,
    );
  }
}

@immutable
class WindowState {
  final double width;
  final double height;
  final double? x;
  final double? y;
  final bool isVisible;
  final bool isMinimized;
  final bool isMaximized;

  const WindowState({
    this.width = 1000,
    this.height = 700,
    this.x,
    this.y,
    this.isVisible = true,
    this.isMinimized = false,
    this.isMaximized = false,
  });

  WindowState copyWith({
    double? width,
    double? height,
    double? x,
    double? y,
    bool? isVisible,
    bool? isMinimized,
    bool? isMaximized,
  }) {
    return WindowState(
      width: width ?? this.width,
      height: height ?? this.height,
      x: x ?? this.x,
      y: y ?? this.y,
      isVisible: isVisible ?? this.isVisible,
      isMinimized: isMinimized ?? this.isMinimized,
      isMaximized: isMaximized ?? this.isMaximized,
    );
  }
}

@immutable
class RunningServicesState {
  final bool backupEngine;
  final bool restoreEngine;
  final bool folderWatcher;
  final bool notificationService;
  final bool database;
  final bool queue;

  const RunningServicesState({
    this.backupEngine = false,
    this.restoreEngine = false,
    this.folderWatcher = false,
    this.notificationService = false,
    this.database = false,
    this.queue = false,
  });

  RunningServicesState copyWith({
    bool? backupEngine,
    bool? restoreEngine,
    bool? folderWatcher,
    bool? notificationService,
    bool? database,
    bool? queue,
  }) {
    return RunningServicesState(
      backupEngine: backupEngine ?? this.backupEngine,
      restoreEngine: restoreEngine ?? this.restoreEngine,
      folderWatcher: folderWatcher ?? this.folderWatcher,
      notificationService: notificationService ?? this.notificationService,
      database: database ?? this.database,
      queue: queue ?? this.queue,
    );
  }
}

@immutable
class CrashState {
  final bool isCrashed;
  final DateTime? lastCrashTime;
  final String? lastCrashReason;
  final int autoRecoveryAttempts;
  final bool recoverySuccessful;

  const CrashState({
    this.isCrashed = false,
    this.lastCrashTime,
    this.lastCrashReason,
    this.autoRecoveryAttempts = 0,
    this.recoverySuccessful = false,
  });

  CrashState copyWith({
    bool? isCrashed,
    DateTime? lastCrashTime,
    String? lastCrashReason,
    int? autoRecoveryAttempts,
    bool? recoverySuccessful,
  }) {
    return CrashState(
      isCrashed: isCrashed ?? this.isCrashed,
      lastCrashTime: lastCrashTime ?? this.lastCrashTime,
      lastCrashReason: lastCrashReason ?? this.lastCrashReason,
      autoRecoveryAttempts: autoRecoveryAttempts ?? this.autoRecoveryAttempts,
      recoverySuccessful: recoverySuccessful ?? this.recoverySuccessful,
    );
  }
}

@immutable
class BackgroundModuleState {
  final BackgroundState background;
  final TrayState tray;
  final StartupState startup;
  final WindowState window;
  final RunningServicesState services;
  final CrashState crash;

  const BackgroundModuleState({
    this.background = const BackgroundState(),
    this.tray = const TrayState(),
    this.startup = const StartupState(),
    this.window = const WindowState(),
    this.services = const RunningServicesState(),
    this.crash = const CrashState(),
  });

  BackgroundModuleState copyWith({
    BackgroundState? background,
    TrayState? tray,
    StartupState? startup,
    WindowState? window,
    RunningServicesState? services,
    CrashState? crash,
  }) {
    return BackgroundModuleState(
      background: background ?? this.background,
      tray: tray ?? this.tray,
      startup: startup ?? this.startup,
      window: window ?? this.window,
      services: services ?? this.services,
      crash: crash ?? this.crash,
    );
  }
}
