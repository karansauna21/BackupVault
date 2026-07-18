class SyncPolicy {
  final bool autoBackupEnabled;
  final bool backupOnlyWhileCharging;
  final bool backupOnlyOnWifi;
  final int bandwidthLimit; // in KB/s (0 = unlimited)
  final int retryCount;
  final bool batterySaverCompatible;
  final bool ignoreSmallChanges;
  final int ignoreChangesUnderMb;
  final bool enableBackgroundNotifications;

  SyncPolicy({
    required this.autoBackupEnabled,
    required this.backupOnlyWhileCharging,
    required this.backupOnlyOnWifi,
    required this.bandwidthLimit,
    required this.retryCount,
    this.batterySaverCompatible = true,
    this.ignoreSmallChanges = false,
    this.ignoreChangesUnderMb = 1,
    this.enableBackgroundNotifications = true,
  });

  factory SyncPolicy.defaultPolicy() {
    return SyncPolicy(
      autoBackupEnabled: false,
      backupOnlyWhileCharging: false,
      backupOnlyOnWifi: true,
      bandwidthLimit: 0,
      retryCount: 3,
      batterySaverCompatible: true,
      ignoreSmallChanges: false,
      ignoreChangesUnderMb: 1,
      enableBackgroundNotifications: true,
    );
  }

  factory SyncPolicy.fromJson(Map<String, dynamic> json) {
    return SyncPolicy(
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? false,
      backupOnlyWhileCharging: json['backupOnlyWhileCharging'] as bool? ?? false,
      backupOnlyOnWifi: json['backupOnlyOnWifi'] as bool? ?? true,
      bandwidthLimit: json['bandwidthLimit'] as int? ?? 0,
      retryCount: json['retryCount'] as int? ?? 3,
      batterySaverCompatible: json['batterySaverCompatible'] as bool? ?? true,
      ignoreSmallChanges: json['ignoreSmallChanges'] as bool? ?? false,
      ignoreChangesUnderMb: json['ignoreChangesUnderMb'] as int? ?? 1,
      enableBackgroundNotifications: json['enableBackgroundNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'autoBackupEnabled': autoBackupEnabled,
    'backupOnlyWhileCharging': backupOnlyWhileCharging,
    'backupOnlyOnWifi': backupOnlyOnWifi,
    'bandwidthLimit': bandwidthLimit,
    'retryCount': retryCount,
    'batterySaverCompatible': batterySaverCompatible,
    'ignoreSmallChanges': ignoreSmallChanges,
    'ignoreChangesUnderMb': ignoreChangesUnderMb,
    'enableBackgroundNotifications': enableBackgroundNotifications,
  };
}
