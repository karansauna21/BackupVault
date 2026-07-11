
class GeneralSettings {
  final String appName;
  final String appVersion;
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'en', 'es', 'de', 'fr'
  final bool autoSaveSettings;
  final bool checkForUpdates;

  const GeneralSettings({
    this.appName = 'BackupVault',
    this.appVersion = '1.0.0',
    this.theme = 'system',
    this.language = 'en',
    this.autoSaveSettings = true,
    this.checkForUpdates = false,
  });

  GeneralSettings copyWith({
    String? appName,
    String? appVersion,
    String? theme,
    String? language,
    bool? autoSaveSettings,
    bool? checkForUpdates,
  }) {
    return GeneralSettings(
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      autoSaveSettings: autoSaveSettings ?? this.autoSaveSettings,
      checkForUpdates: checkForUpdates ?? this.checkForUpdates,
    );
  }

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'appVersion': appVersion,
        'theme': theme,
        'language': language,
        'autoSaveSettings': autoSaveSettings,
        'checkForUpdates': checkForUpdates,
      };

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      appName: json['appName'] ?? 'BackupVault',
      appVersion: json['appVersion'] ?? '1.0.0',
      theme: json['theme'] ?? 'system',
      language: json['language'] ?? 'en',
      autoSaveSettings: json['autoSaveSettings'] ?? true,
      checkForUpdates: json['checkForUpdates'] ?? false,
    );
  }
}

class StartupSettings {
  final bool launchAtStartup;
  final bool startMinimized;
  final bool startInSystemTray;
  final bool autoStartBackupEngine;
  final bool autoResumePendingJobs;
  final bool restorePreviousSession;

  const StartupSettings({
    this.launchAtStartup = false,
    this.startMinimized = false,
    this.startInSystemTray = false,
    this.autoStartBackupEngine = true,
    this.autoResumePendingJobs = true,
    this.restorePreviousSession = false,
  });

  StartupSettings copyWith({
    bool? launchAtStartup,
    bool? startMinimized,
    bool? startInSystemTray,
    bool? autoStartBackupEngine,
    bool? autoResumePendingJobs,
    bool? restorePreviousSession,
  }) {
    return StartupSettings(
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      startMinimized: startMinimized ?? this.startMinimized,
      startInSystemTray: startInSystemTray ?? this.startInSystemTray,
      autoStartBackupEngine: autoStartBackupEngine ?? this.autoStartBackupEngine,
      autoResumePendingJobs: autoResumePendingJobs ?? this.autoResumePendingJobs,
      restorePreviousSession: restorePreviousSession ?? this.restorePreviousSession,
    );
  }

  Map<String, dynamic> toJson() => {
        'launchAtStartup': launchAtStartup,
        'startMinimized': startMinimized,
        'startInSystemTray': startInSystemTray,
        'autoStartBackupEngine': autoStartBackupEngine,
        'autoResumePendingJobs': autoResumePendingJobs,
        'restorePreviousSession': restorePreviousSession,
      };

  factory StartupSettings.fromJson(Map<String, dynamic> json) {
    return StartupSettings(
      launchAtStartup: json['launchAtStartup'] ?? false,
      startMinimized: json['startMinimized'] ?? false,
      startInSystemTray: json['startInSystemTray'] ?? false,
      autoStartBackupEngine: json['autoStartBackupEngine'] ?? true,
      autoResumePendingJobs: json['autoResumePendingJobs'] ?? true,
      restorePreviousSession: json['restorePreviousSession'] ?? false,
    );
  }
}

class BackupSettings {
  final String defaultBackupDestination;
  final bool enableVersioning;
  final int maxVersions;
  final bool keepForever;
  final bool verifySha256;
  final bool retryFailedBackup;
  final int maxRetryCount;
  final String overwritePolicy; // 'overwrite', 'skip', 'rename'
  final String duplicatePolicy; // 'keep_both', 'replace', 'ask'
  final String dateFolderFormat; // 'yyyy-MM-dd', 'yyyyMMdd', 'dd-MM-yyyy'
  final String backupNamingFormat; // 'original_date', 'date_original', 'original'
  final String backupOrganizationMode; // 'mirror', 'smart', 'hybrid'

  const BackupSettings({
    this.defaultBackupDestination = '',
    this.enableVersioning = true,
    this.maxVersions = 5,
    this.keepForever = false,
    this.verifySha256 = true,
    this.retryFailedBackup = true,
    this.maxRetryCount = 3,
    this.overwritePolicy = 'overwrite',
    this.duplicatePolicy = 'keep_both',
    this.dateFolderFormat = 'yyyy-MM-dd',
    this.backupNamingFormat = 'original_date',
    this.backupOrganizationMode = 'mirror',
  });

  BackupSettings copyWith({
    String? defaultBackupDestination,
    bool? enableVersioning,
    int? maxVersions,
    bool? keepForever,
    bool? verifySha256,
    bool? retryFailedBackup,
    int? maxRetryCount,
    String? overwritePolicy,
    String? duplicatePolicy,
    String? dateFolderFormat,
    String? backupNamingFormat,
    String? backupOrganizationMode,
  }) {
    return BackupSettings(
      defaultBackupDestination: defaultBackupDestination ?? this.defaultBackupDestination,
      enableVersioning: enableVersioning ?? this.enableVersioning,
      maxVersions: maxVersions ?? this.maxVersions,
      keepForever: keepForever ?? this.keepForever,
      verifySha256: verifySha256 ?? this.verifySha256,
      retryFailedBackup: retryFailedBackup ?? this.retryFailedBackup,
      maxRetryCount: maxRetryCount ?? this.maxRetryCount,
      overwritePolicy: overwritePolicy ?? this.overwritePolicy,
      duplicatePolicy: duplicatePolicy ?? this.duplicatePolicy,
      dateFolderFormat: dateFolderFormat ?? this.dateFolderFormat,
      backupNamingFormat: backupNamingFormat ?? this.backupNamingFormat,
      backupOrganizationMode: backupOrganizationMode ?? this.backupOrganizationMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultBackupDestination': defaultBackupDestination,
        'enableVersioning': enableVersioning,
        'maxVersions': maxVersions,
        'keepForever': keepForever,
        'verifySha256': verifySha256,
        'retryFailedBackup': retryFailedBackup,
        'maxRetryCount': maxRetryCount,
        'overwritePolicy': overwritePolicy,
        'duplicatePolicy': duplicatePolicy,
        'dateFolderFormat': dateFolderFormat,
        'backupNamingFormat': backupNamingFormat,
        'backupOrganizationMode': backupOrganizationMode,
      };

  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      defaultBackupDestination: json['defaultBackupDestination'] ?? '',
      enableVersioning: json['enableVersioning'] ?? true,
      maxVersions: json['maxVersions'] ?? 5,
      keepForever: json['keepForever'] ?? false,
      verifySha256: json['verifySha256'] ?? true,
      retryFailedBackup: json['retryFailedBackup'] ?? true,
      maxRetryCount: json['maxRetryCount'] ?? 3,
      overwritePolicy: json['overwritePolicy'] ?? 'overwrite',
      duplicatePolicy: json['duplicatePolicy'] ?? 'keep_both',
      dateFolderFormat: json['dateFolderFormat'] ?? 'yyyy-MM-dd',
      backupNamingFormat: json['backupNamingFormat'] ?? 'original_date',
      backupOrganizationMode: json['backupOrganizationMode'] ?? 'mirror',
    );
  }
}

class MonitoringSettings {
  final bool enableRealtimeMonitoring;
  final bool pauseMonitoring;
  final bool backgroundMonitoring;
  final int maxWorkerThreads;
  final int scanDelayMs;
  final int eventQueueSize;
  final int folderScanIntervalSecs;

  const MonitoringSettings({
    this.enableRealtimeMonitoring = true,
    this.pauseMonitoring = false,
    this.backgroundMonitoring = true,
    this.maxWorkerThreads = 4,
    this.scanDelayMs = 100,
    this.eventQueueSize = 1000,
    this.folderScanIntervalSecs = 300,
  });

  MonitoringSettings copyWith({
    bool? enableRealtimeMonitoring,
    bool? pauseMonitoring,
    bool? backgroundMonitoring,
    int? maxWorkerThreads,
    int? scanDelayMs,
    int? eventQueueSize,
    int? folderScanIntervalSecs,
  }) {
    return MonitoringSettings(
      enableRealtimeMonitoring: enableRealtimeMonitoring ?? this.enableRealtimeMonitoring,
      pauseMonitoring: pauseMonitoring ?? this.pauseMonitoring,
      backgroundMonitoring: backgroundMonitoring ?? this.backgroundMonitoring,
      maxWorkerThreads: maxWorkerThreads ?? this.maxWorkerThreads,
      scanDelayMs: scanDelayMs ?? this.scanDelayMs,
      eventQueueSize: eventQueueSize ?? this.eventQueueSize,
      folderScanIntervalSecs: folderScanIntervalSecs ?? this.folderScanIntervalSecs,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableRealtimeMonitoring': enableRealtimeMonitoring,
        'pauseMonitoring': pauseMonitoring,
        'backgroundMonitoring': backgroundMonitoring,
        'maxWorkerThreads': maxWorkerThreads,
        'scanDelayMs': scanDelayMs,
        'eventQueueSize': eventQueueSize,
        'folderScanIntervalSecs': folderScanIntervalSecs,
      };

  factory MonitoringSettings.fromJson(Map<String, dynamic> json) {
    return MonitoringSettings(
      enableRealtimeMonitoring: json['enableRealtimeMonitoring'] ?? true,
      pauseMonitoring: json['pauseMonitoring'] ?? false,
      backgroundMonitoring: json['backgroundMonitoring'] ?? true,
      maxWorkerThreads: json['maxWorkerThreads'] ?? 4,
      scanDelayMs: json['scanDelayMs'] ?? 100,
      eventQueueSize: json['eventQueueSize'] ?? 1000,
      folderScanIntervalSecs: json['folderScanIntervalSecs'] ?? 300,
    );
  }
}

class RestoreSettings {
  final String defaultRestoreFolder;
  final bool restoreToOriginalLocation;
  final String conflictPolicy; // 'overwrite', 'skip', 'rename'
  final bool verifyRestoredFiles;
  final bool restoreHistory;

  const RestoreSettings({
    this.defaultRestoreFolder = '',
    this.restoreToOriginalLocation = false,
    this.conflictPolicy = 'rename',
    this.verifyRestoredFiles = true,
    this.restoreHistory = true,
  });

  RestoreSettings copyWith({
    String? defaultRestoreFolder,
    bool? restoreToOriginalLocation,
    String? conflictPolicy,
    bool? verifyRestoredFiles,
    bool? restoreHistory,
  }) {
    return RestoreSettings(
      defaultRestoreFolder: defaultRestoreFolder ?? this.defaultRestoreFolder,
      restoreToOriginalLocation: restoreToOriginalLocation ?? this.restoreToOriginalLocation,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
      verifyRestoredFiles: verifyRestoredFiles ?? this.verifyRestoredFiles,
      restoreHistory: restoreHistory ?? this.restoreHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultRestoreFolder': defaultRestoreFolder,
        'restoreToOriginalLocation': restoreToOriginalLocation,
        'conflictPolicy': conflictPolicy,
        'verifyRestoredFiles': verifyRestoredFiles,
        'restoreHistory': restoreHistory,
      };

  factory RestoreSettings.fromJson(Map<String, dynamic> json) {
    return RestoreSettings(
      defaultRestoreFolder: json['defaultRestoreFolder'] ?? '',
      restoreToOriginalLocation: json['restoreToOriginalLocation'] ?? false,
      conflictPolicy: json['conflictPolicy'] ?? 'rename',
      verifyRestoredFiles: json['verifyRestoredFiles'] ?? true,
      restoreHistory: json['restoreHistory'] ?? true,
    );
  }
}

class NotificationSettings {
  final bool enableNotifications;
  final bool notifyBackupComplete;
  final bool notifyBackupFailed;
  final bool notifyRestoreComplete;
  final bool notifyLowStorage;
  final bool notifyFolderOffline;
  final bool notifyBackgroundErrors;
  final bool notifyWarningMessages;

  const NotificationSettings({
    this.enableNotifications = true,
    this.notifyBackupComplete = true,
    this.notifyBackupFailed = true,
    this.notifyRestoreComplete = true,
    this.notifyLowStorage = true,
    this.notifyFolderOffline = true,
    this.notifyBackgroundErrors = true,
    this.notifyWarningMessages = false,
  });

  NotificationSettings copyWith({
    bool? enableNotifications,
    bool? notifyBackupComplete,
    bool? notifyBackupFailed,
    bool? notifyRestoreComplete,
    bool? notifyLowStorage,
    bool? notifyFolderOffline,
    bool? notifyBackgroundErrors,
    bool? notifyWarningMessages,
  }) {
    return NotificationSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notifyBackupComplete: notifyBackupComplete ?? this.notifyBackupComplete,
      notifyBackupFailed: notifyBackupFailed ?? this.notifyBackupFailed,
      notifyRestoreComplete: notifyRestoreComplete ?? this.notifyRestoreComplete,
      notifyLowStorage: notifyLowStorage ?? this.notifyLowStorage,
      notifyFolderOffline: notifyFolderOffline ?? this.notifyFolderOffline,
      notifyBackgroundErrors: notifyBackgroundErrors ?? this.notifyBackgroundErrors,
      notifyWarningMessages: notifyWarningMessages ?? this.notifyWarningMessages,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableNotifications': enableNotifications,
        'notifyBackupComplete': notifyBackupComplete,
        'notifyBackupFailed': notifyBackupFailed,
        'notifyRestoreComplete': notifyRestoreComplete,
        'notifyLowStorage': notifyLowStorage,
        'notifyFolderOffline': notifyFolderOffline,
        'notifyBackgroundErrors': notifyBackgroundErrors,
        'notifyWarningMessages': notifyWarningMessages,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableNotifications: json['enableNotifications'] ?? true,
      notifyBackupComplete: json['notifyBackupComplete'] ?? true,
      notifyBackupFailed: json['notifyBackupFailed'] ?? true,
      notifyRestoreComplete: json['notifyRestoreComplete'] ?? true,
      notifyLowStorage: json['notifyLowStorage'] ?? true,
      notifyFolderOffline: json['notifyFolderOffline'] ?? true,
      notifyBackgroundErrors: json['notifyBackgroundErrors'] ?? true,
      notifyWarningMessages: json['notifyWarningMessages'] ?? false,
    );
  }
}

class LoggingSettings {
  final bool enableLogging;
  final bool debugLogging;
  final int maxLogSizeMb;
  final int logRetentionDays;

  const LoggingSettings({
    this.enableLogging = true,
    this.debugLogging = false,
    this.maxLogSizeMb = 10,
    this.logRetentionDays = 30,
  });

  LoggingSettings copyWith({
    bool? enableLogging,
    bool? debugLogging,
    int? maxLogSizeMb,
    int? logRetentionDays,
  }) {
    return LoggingSettings(
      enableLogging: enableLogging ?? this.enableLogging,
      debugLogging: debugLogging ?? this.debugLogging,
      maxLogSizeMb: maxLogSizeMb ?? this.maxLogSizeMb,
      logRetentionDays: logRetentionDays ?? this.logRetentionDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableLogging': enableLogging,
        'debugLogging': debugLogging,
        'maxLogSizeMb': maxLogSizeMb,
        'logRetentionDays': logRetentionDays,
      };

  factory LoggingSettings.fromJson(Map<String, dynamic> json) {
    return LoggingSettings(
      enableLogging: json['enableLogging'] ?? true,
      debugLogging: json['debugLogging'] ?? false,
      maxLogSizeMb: json['maxLogSizeMb'] ?? 10,
      logRetentionDays: json['logRetentionDays'] ?? 30,
    );
  }
}

class PerformanceSettings {
  final int cpuLimitPercent;
  final int ramLimitMb;
  final int threadLimit;
  final int maxParallelJobs;
  final int fileBufferSizeKb;
  final bool largeFileMode;
  final bool powerSavingMode;

  const PerformanceSettings({
    this.cpuLimitPercent = 80,
    this.ramLimitMb = 512,
    this.threadLimit = 4,
    this.maxParallelJobs = 2,
    this.fileBufferSizeKb = 64,
    this.largeFileMode = false,
    this.powerSavingMode = false,
  });

  PerformanceSettings copyWith({
    int? cpuLimitPercent,
    int? ramLimitMb,
    int? threadLimit,
    int? maxParallelJobs,
    int? fileBufferSizeKb,
    bool? largeFileMode,
    bool? powerSavingMode,
  }) {
    return PerformanceSettings(
      cpuLimitPercent: cpuLimitPercent ?? this.cpuLimitPercent,
      ramLimitMb: ramLimitMb ?? this.ramLimitMb,
      threadLimit: threadLimit ?? this.threadLimit,
      maxParallelJobs: maxParallelJobs ?? this.maxParallelJobs,
      fileBufferSizeKb: fileBufferSizeKb ?? this.fileBufferSizeKb,
      largeFileMode: largeFileMode ?? this.largeFileMode,
      powerSavingMode: powerSavingMode ?? this.powerSavingMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'cpuLimitPercent': cpuLimitPercent,
        'ramLimitMb': ramLimitMb,
        'threadLimit': threadLimit,
        'maxParallelJobs': maxParallelJobs,
        'fileBufferSizeKb': fileBufferSizeKb,
        'largeFileMode': largeFileMode,
        'powerSavingMode': powerSavingMode,
      };

  factory PerformanceSettings.fromJson(Map<String, dynamic> json) {
    return PerformanceSettings(
      cpuLimitPercent: json['cpuLimitPercent'] ?? 80,
      ramLimitMb: json['ramLimitMb'] ?? 512,
      threadLimit: json['threadLimit'] ?? 4,
      maxParallelJobs: json['maxParallelJobs'] ?? 2,
      fileBufferSizeKb: json['fileBufferSizeKb'] ?? 64,
      largeFileMode: json['largeFileMode'] ?? false,
      powerSavingMode: json['powerSavingMode'] ?? false,
    );
  }
}

class SecuritySettings {
  final bool verifyIntegrity;
  final bool enableFutureEncryption;
  final bool requireConfirmationBeforeDelete;
  final bool protectBackupDatabase;
  final bool lockSettings;
  final bool autoRepairInterruptedBackups;

  const SecuritySettings({
    this.verifyIntegrity = true,
    this.enableFutureEncryption = false,
    this.requireConfirmationBeforeDelete = true,
    this.protectBackupDatabase = true,
    this.lockSettings = false,
    this.autoRepairInterruptedBackups = true,
  });

  SecuritySettings copyWith({
    bool? verifyIntegrity,
    bool? enableFutureEncryption,
    bool? requireConfirmationBeforeDelete,
    bool? protectBackupDatabase,
    bool? lockSettings,
    bool? autoRepairInterruptedBackups,
  }) {
    return SecuritySettings(
      verifyIntegrity: verifyIntegrity ?? this.verifyIntegrity,
      enableFutureEncryption: enableFutureEncryption ?? this.enableFutureEncryption,
      requireConfirmationBeforeDelete: requireConfirmationBeforeDelete ?? this.requireConfirmationBeforeDelete,
      protectBackupDatabase: protectBackupDatabase ?? this.protectBackupDatabase,
      lockSettings: lockSettings ?? this.lockSettings,
      autoRepairInterruptedBackups: autoRepairInterruptedBackups ?? this.autoRepairInterruptedBackups,
    );
  }

  Map<String, dynamic> toJson() => {
        'verifyIntegrity': verifyIntegrity,
        'enableFutureEncryption': enableFutureEncryption,
        'requireConfirmationBeforeDelete': requireConfirmationBeforeDelete,
        'protectBackupDatabase': protectBackupDatabase,
        'lockSettings': lockSettings,
        'autoRepairInterruptedBackups': autoRepairInterruptedBackups,
      };

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      verifyIntegrity: json['verifyIntegrity'] ?? true,
      enableFutureEncryption: json['enableFutureEncryption'] ?? false,
      requireConfirmationBeforeDelete: json['requireConfirmationBeforeDelete'] ?? true,
      protectBackupDatabase: json['protectBackupDatabase'] ?? true,
      lockSettings: json['lockSettings'] ?? false,
      autoRepairInterruptedBackups: json['autoRepairInterruptedBackups'] ?? true,
    );
  }
}

class StorageSettings {
  final bool showAvailableSpace;
  final bool lowStorageWarning;
  final int minimumFreeSpaceGb;
  final bool autoPauseWhenFull;

  const StorageSettings({
    this.showAvailableSpace = true,
    this.lowStorageWarning = true,
    this.minimumFreeSpaceGb = 5,
    this.autoPauseWhenFull = true,
  });

  StorageSettings copyWith({
    bool? showAvailableSpace,
    bool? lowStorageWarning,
    int? minimumFreeSpaceGb,
    bool? autoPauseWhenFull,
  }) {
    return StorageSettings(
      showAvailableSpace: showAvailableSpace ?? this.showAvailableSpace,
      lowStorageWarning: lowStorageWarning ?? this.lowStorageWarning,
      minimumFreeSpaceGb: minimumFreeSpaceGb ?? this.minimumFreeSpaceGb,
      autoPauseWhenFull: autoPauseWhenFull ?? this.autoPauseWhenFull,
    );
  }

  Map<String, dynamic> toJson() => {
        'showAvailableSpace': showAvailableSpace,
        'lowStorageWarning': lowStorageWarning,
        'minimumFreeSpaceGb': minimumFreeSpaceGb,
        'autoPauseWhenFull': autoPauseWhenFull,
      };

  factory StorageSettings.fromJson(Map<String, dynamic> json) {
    return StorageSettings(
      showAvailableSpace: json['showAvailableSpace'] ?? true,
      lowStorageWarning: json['lowStorageWarning'] ?? true,
      minimumFreeSpaceGb: json['minimumFreeSpaceGb'] ?? 5,
      autoPauseWhenFull: json['autoPauseWhenFull'] ?? true,
    );
  }
}

class SettingsState {
  final GeneralSettings general;
  final StartupSettings startup;
  final BackupSettings backup;
  final MonitoringSettings monitoring;
  final RestoreSettings restore;
  final NotificationSettings notifications;
  final LoggingSettings logging;
  final PerformanceSettings performance;
  final SecuritySettings security;
  final StorageSettings storage;

  const SettingsState({
    this.general = const GeneralSettings(),
    this.startup = const StartupSettings(),
    this.backup = const BackupSettings(),
    this.monitoring = const MonitoringSettings(),
    this.restore = const RestoreSettings(),
    this.notifications = const NotificationSettings(),
    this.logging = const LoggingSettings(),
    this.performance = const PerformanceSettings(),
    this.security = const SecuritySettings(),
    this.storage = const StorageSettings(),
  });

  SettingsState copyWith({
    GeneralSettings? general,
    StartupSettings? startup,
    BackupSettings? backup,
    MonitoringSettings? monitoring,
    RestoreSettings? restore,
    NotificationSettings? notifications,
    LoggingSettings? logging,
    PerformanceSettings? performance,
    SecuritySettings? security,
    StorageSettings? storage,
  }) {
    return SettingsState(
      general: general ?? this.general,
      startup: startup ?? this.startup,
      backup: backup ?? this.backup,
      monitoring: monitoring ?? this.monitoring,
      restore: restore ?? this.restore,
      notifications: notifications ?? this.notifications,
      logging: logging ?? this.logging,
      performance: performance ?? this.performance,
      security: security ?? this.security,
      storage: storage ?? this.storage,
    );
  }

  Map<String, dynamic> toJson() => {
        'general': general.toJson(),
        'startup': startup.toJson(),
        'backup': backup.toJson(),
        'monitoring': monitoring.toJson(),
        'restore': restore.toJson(),
        'notifications': notifications.toJson(),
        'logging': logging.toJson(),
        'performance': performance.toJson(),
        'security': security.toJson(),
        'storage': storage.toJson(),
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      general: json['general'] != null ? GeneralSettings.fromJson(json['general']) : const GeneralSettings(),
      startup: json['startup'] != null ? StartupSettings.fromJson(json['startup']) : const StartupSettings(),
      backup: json['backup'] != null ? BackupSettings.fromJson(json['backup']) : const BackupSettings(),
      monitoring: json['monitoring'] != null ? MonitoringSettings.fromJson(json['monitoring']) : const MonitoringSettings(),
      restore: json['restore'] != null ? RestoreSettings.fromJson(json['restore']) : const RestoreSettings(),
      notifications: json['notifications'] != null ? NotificationSettings.fromJson(json['notifications']) : const NotificationSettings(),
      logging: json['logging'] != null ? LoggingSettings.fromJson(json['logging']) : const LoggingSettings(),
      performance: json['performance'] != null ? PerformanceSettings.fromJson(json['performance']) : const PerformanceSettings(),
      security: json['security'] != null ? SecuritySettings.fromJson(json['security']) : const SecuritySettings(),
      storage: json['storage'] != null ? StorageSettings.fromJson(json['storage']) : const StorageSettings(),
    );
  }
}
