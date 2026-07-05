class AppSettings {
  final String themeMode; // 'light', 'dark', 'system'
  final String defaultDestinationPath;
  final bool autoBackupEnabled;
  final String backupInterval; // 'daily', 'weekly', 'manual'
  final bool notifyOnSuccess;
  final bool notifyOnFailure;

  const AppSettings({
    required this.themeMode,
    required this.defaultDestinationPath,
    required this.autoBackupEnabled,
    required this.backupInterval,
    required this.notifyOnSuccess,
    required this.notifyOnFailure,
  });

  AppSettings copyWith({
    String? themeMode,
    String? defaultDestinationPath,
    bool? autoBackupEnabled,
    String? backupInterval,
    bool? notifyOnSuccess,
    bool? notifyOnFailure,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultDestinationPath: defaultDestinationPath ?? this.defaultDestinationPath,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupInterval: backupInterval ?? this.backupInterval,
      notifyOnSuccess: notifyOnSuccess ?? this.notifyOnSuccess,
      notifyOnFailure: notifyOnFailure ?? this.notifyOnFailure,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'defaultDestinationPath': defaultDestinationPath,
      'autoBackupEnabled': autoBackupEnabled,
      'backupInterval': backupInterval,
      'notifyOnSuccess': notifyOnSuccess,
      'notifyOnFailure': notifyOnFailure,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] ?? 'system',
      defaultDestinationPath: json['defaultDestinationPath'] ?? '',
      autoBackupEnabled: json['autoBackupEnabled'] ?? false,
      backupInterval: json['backupInterval'] ?? 'manual',
      notifyOnSuccess: json['notifyOnSuccess'] ?? true,
      notifyOnFailure: json['notifyOnFailure'] ?? true,
    );
  }

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      themeMode: 'system',
      defaultDestinationPath: '',
      autoBackupEnabled: false,
      backupInterval: 'manual',
      notifyOnSuccess: true,
      notifyOnFailure: true,
    );
  }
}
