class SyncPolicy {
  final bool autoBackupEnabled;
  final bool backupOnlyWhileCharging;
  final bool backupOnlyOnWifi;
  final int bandwidthLimit; // in KB/s (0 = unlimited)
  final int retryCount;

  SyncPolicy({
    required this.autoBackupEnabled,
    required this.backupOnlyWhileCharging,
    required this.backupOnlyOnWifi,
    required this.bandwidthLimit,
    required this.retryCount,
  });

  factory SyncPolicy.defaultPolicy() {
    return SyncPolicy(
      autoBackupEnabled: false,
      backupOnlyWhileCharging: false,
      backupOnlyOnWifi: true,
      bandwidthLimit: 0,
      retryCount: 3,
    );
  }

  factory SyncPolicy.fromJson(Map<String, dynamic> json) {
    return SyncPolicy(
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? false,
      backupOnlyWhileCharging: json['backupOnlyWhileCharging'] as bool? ?? false,
      backupOnlyOnWifi: json['backupOnlyOnWifi'] as bool? ?? true,
      bandwidthLimit: json['bandwidthLimit'] as int? ?? 0,
      retryCount: json['retryCount'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
    'autoBackupEnabled': autoBackupEnabled,
    'backupOnlyWhileCharging': backupOnlyWhileCharging,
    'backupOnlyOnWifi': backupOnlyOnWifi,
    'bandwidthLimit': bandwidthLimit,
    'retryCount': retryCount,
  };
}
