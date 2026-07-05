class SmartRules {
  final bool runOnlyIfDestinationAvailable;
  final bool skipDuplicateJobs;
  final bool skipIfBackupAlreadyCompleted;
  final bool retryAutomaticallyAfterFailure;
  final bool pauseWhenCpuUsageIsHigh;
  final bool pauseWhenStorageIsFull;
  final bool pauseDuringGamingMode;
  final bool pauseWhenBatteryIsLow;
  final bool resumeAutomatically;
  
  // Prompt 17 additions
  final bool backupOnlyWhileCharging;
  final bool pauseOnBattery;
  final bool resumeOnCharging;
  final bool backupOnlyOnWifi;
  final bool backupOnlyWhenIdle;
  final bool pauseDuringFullScreenApps;
  final String? allowedTimeRangeStart;
  final String? allowedTimeRangeEnd;
  final String? blockedTimeRangeStart;
  final String? blockedTimeRangeEnd;
  final bool weekendOnly;
  final bool weekdaysOnly;
  final bool holidaySupport;
  final int randomDelayMinutes;
  final int maxRuntimeMinutes;
  final int retryDelayMinutes;

  const SmartRules({
    this.runOnlyIfDestinationAvailable = true,
    this.skipDuplicateJobs = true,
    this.skipIfBackupAlreadyCompleted = false,
    this.retryAutomaticallyAfterFailure = true,
    this.pauseWhenCpuUsageIsHigh = false,
    this.pauseWhenStorageIsFull = false,
    this.pauseDuringGamingMode = false,
    this.pauseWhenBatteryIsLow = false,
    this.resumeAutomatically = true,
    this.backupOnlyWhileCharging = false,
    this.pauseOnBattery = false,
    this.resumeOnCharging = true,
    this.backupOnlyOnWifi = false,
    this.backupOnlyWhenIdle = false,
    this.pauseDuringFullScreenApps = false,
    this.allowedTimeRangeStart,
    this.allowedTimeRangeEnd,
    this.blockedTimeRangeStart,
    this.blockedTimeRangeEnd,
    this.weekendOnly = false,
    this.weekdaysOnly = false,
    this.holidaySupport = false,
    this.randomDelayMinutes = 0,
    this.maxRuntimeMinutes = 0,
    this.retryDelayMinutes = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'runOnlyIfDestinationAvailable': runOnlyIfDestinationAvailable,
      'skipDuplicateJobs': skipDuplicateJobs,
      'skipIfBackupAlreadyCompleted': skipIfBackupAlreadyCompleted,
      'retryAutomaticallyAfterFailure': retryAutomaticallyAfterFailure,
      'pauseWhenCpuUsageIsHigh': pauseWhenCpuUsageIsHigh,
      'pauseWhenStorageIsFull': pauseWhenStorageIsFull,
      'pauseDuringGamingMode': pauseDuringGamingMode,
      'pauseWhenBatteryIsLow': pauseWhenBatteryIsLow,
      'resumeAutomatically': resumeAutomatically,
      'backupOnlyWhileCharging': backupOnlyWhileCharging,
      'pauseOnBattery': pauseOnBattery,
      'resumeOnCharging': resumeOnCharging,
      'backupOnlyOnWifi': backupOnlyOnWifi,
      'backupOnlyWhenIdle': backupOnlyWhenIdle,
      'pauseDuringFullScreenApps': pauseDuringFullScreenApps,
      'allowedTimeRangeStart': allowedTimeRangeStart,
      'allowedTimeRangeEnd': allowedTimeRangeEnd,
      'blockedTimeRangeStart': blockedTimeRangeStart,
      'blockedTimeRangeEnd': blockedTimeRangeEnd,
      'weekendOnly': weekendOnly,
      'weekdaysOnly': weekdaysOnly,
      'holidaySupport': holidaySupport,
      'randomDelayMinutes': randomDelayMinutes,
      'maxRuntimeMinutes': maxRuntimeMinutes,
      'retryDelayMinutes': retryDelayMinutes,
    };
  }

  factory SmartRules.fromJson(Map<String, dynamic> json) {
    return SmartRules(
      runOnlyIfDestinationAvailable: json['runOnlyIfDestinationAvailable'] as bool? ?? true,
      skipDuplicateJobs: json['skipDuplicateJobs'] as bool? ?? true,
      skipIfBackupAlreadyCompleted: json['skipIfBackupAlreadyCompleted'] as bool? ?? false,
      retryAutomaticallyAfterFailure: json['retryAutomaticallyAfterFailure'] as bool? ?? true,
      pauseWhenCpuUsageIsHigh: json['pauseWhenCpuUsageIsHigh'] as bool? ?? false,
      pauseWhenStorageIsFull: json['pauseWhenStorageIsFull'] as bool? ?? false,
      pauseDuringGamingMode: json['pauseDuringGamingMode'] as bool? ?? false,
      pauseWhenBatteryIsLow: json['pauseWhenBatteryIsLow'] as bool? ?? false,
      resumeAutomatically: json['resumeAutomatically'] as bool? ?? true,
      backupOnlyWhileCharging: json['backupOnlyWhileCharging'] as bool? ?? false,
      pauseOnBattery: json['pauseOnBattery'] as bool? ?? false,
      resumeOnCharging: json['resumeOnCharging'] as bool? ?? true,
      backupOnlyOnWifi: json['backupOnlyOnWifi'] as bool? ?? false,
      backupOnlyWhenIdle: json['backupOnlyWhenIdle'] as bool? ?? false,
      pauseDuringFullScreenApps: json['pauseDuringFullScreenApps'] as bool? ?? false,
      allowedTimeRangeStart: json['allowedTimeRangeStart'] as String?,
      allowedTimeRangeEnd: json['allowedTimeRangeEnd'] as String?,
      blockedTimeRangeStart: json['blockedTimeRangeStart'] as String?,
      blockedTimeRangeEnd: json['blockedTimeRangeEnd'] as String?,
      weekendOnly: json['weekendOnly'] as bool? ?? false,
      weekdaysOnly: json['weekdaysOnly'] as bool? ?? false,
      holidaySupport: json['holidaySupport'] as bool? ?? false,
      randomDelayMinutes: json['randomDelayMinutes'] as int? ?? 0,
      maxRuntimeMinutes: json['maxRuntimeMinutes'] as int? ?? 0,
      retryDelayMinutes: json['retryDelayMinutes'] as int? ?? 5,
    );
  }

  SmartRules copyWith({
    bool? runOnlyIfDestinationAvailable,
    bool? skipDuplicateJobs,
    bool? skipIfBackupAlreadyCompleted,
    bool? retryAutomaticallyAfterFailure,
    bool? pauseWhenCpuUsageIsHigh,
    bool? pauseWhenStorageIsFull,
    bool? pauseDuringGamingMode,
    bool? pauseWhenBatteryIsLow,
    bool? resumeAutomatically,
    bool? backupOnlyWhileCharging,
    bool? pauseOnBattery,
    bool? resumeOnCharging,
    bool? backupOnlyOnWifi,
    bool? backupOnlyWhenIdle,
    bool? pauseDuringFullScreenApps,
    String? allowedTimeRangeStart,
    String? allowedTimeRangeEnd,
    String? blockedTimeRangeStart,
    String? blockedTimeRangeEnd,
    bool? weekendOnly,
    bool? weekdaysOnly,
    bool? holidaySupport,
    int? randomDelayMinutes,
    int? maxRuntimeMinutes,
    int? retryDelayMinutes,
  }) {
    return SmartRules(
      runOnlyIfDestinationAvailable: runOnlyIfDestinationAvailable ?? this.runOnlyIfDestinationAvailable,
      skipDuplicateJobs: skipDuplicateJobs ?? this.skipDuplicateJobs,
      skipIfBackupAlreadyCompleted: skipIfBackupAlreadyCompleted ?? this.skipIfBackupAlreadyCompleted,
      retryAutomaticallyAfterFailure: retryAutomaticallyAfterFailure ?? this.retryAutomaticallyAfterFailure,
      pauseWhenCpuUsageIsHigh: pauseWhenCpuUsageIsHigh ?? this.pauseWhenCpuUsageIsHigh,
      pauseWhenStorageIsFull: pauseWhenStorageIsFull ?? this.pauseWhenStorageIsFull,
      pauseDuringGamingMode: pauseDuringGamingMode ?? this.pauseDuringGamingMode,
      pauseWhenBatteryIsLow: pauseWhenBatteryIsLow ?? this.pauseWhenBatteryIsLow,
      resumeAutomatically: resumeAutomatically ?? this.resumeAutomatically,
      backupOnlyWhileCharging: backupOnlyWhileCharging ?? this.backupOnlyWhileCharging,
      pauseOnBattery: pauseOnBattery ?? this.pauseOnBattery,
      resumeOnCharging: resumeOnCharging ?? this.resumeOnCharging,
      backupOnlyOnWifi: backupOnlyOnWifi ?? this.backupOnlyOnWifi,
      backupOnlyWhenIdle: backupOnlyWhenIdle ?? this.backupOnlyWhenIdle,
      pauseDuringFullScreenApps: pauseDuringFullScreenApps ?? this.pauseDuringFullScreenApps,
      allowedTimeRangeStart: allowedTimeRangeStart ?? this.allowedTimeRangeStart,
      allowedTimeRangeEnd: allowedTimeRangeEnd ?? this.allowedTimeRangeEnd,
      blockedTimeRangeStart: blockedTimeRangeStart ?? this.blockedTimeRangeStart,
      blockedTimeRangeEnd: blockedTimeRangeEnd ?? this.blockedTimeRangeEnd,
      weekendOnly: weekendOnly ?? this.weekendOnly,
      weekdaysOnly: weekdaysOnly ?? this.weekdaysOnly,
      holidaySupport: holidaySupport ?? this.holidaySupport,
      randomDelayMinutes: randomDelayMinutes ?? this.randomDelayMinutes,
      maxRuntimeMinutes: maxRuntimeMinutes ?? this.maxRuntimeMinutes,
      retryDelayMinutes: retryDelayMinutes ?? this.retryDelayMinutes,
    );
  }
}

class ScheduleConfig {
  final String id;
  final String name;
  final int folderId;
  final String scheduleType; // Manual, Real-time, Every Minute, Every 5 Minutes, etc.
  final String? customCronExpression;
  final List<String> triggerTypes; // Application Startup, Windows Startup, Folder Changed, etc.
  final String? triggerSpecificTime; // e.g. "18:00"
  final DateTime? triggerSpecificDate;
  final SmartRules rules;
  final bool enabled;
  final DateTime? lastRunTime;
  final DateTime? nextRunTime;

  const ScheduleConfig({
    required this.id,
    required this.name,
    required this.folderId,
    required this.scheduleType,
    this.customCronExpression,
    required this.triggerTypes,
    this.triggerSpecificTime,
    this.triggerSpecificDate,
    this.rules = const SmartRules(),
    this.enabled = true,
    this.lastRunTime,
    this.nextRunTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'folderId': folderId,
      'scheduleType': scheduleType,
      'customCronExpression': customCronExpression,
      'triggerTypes': triggerTypes,
      'triggerSpecificTime': triggerSpecificTime,
      'triggerSpecificDate': triggerSpecificDate?.toIso8601String(),
      'rules': rules.toJson(),
      'enabled': enabled,
      'lastRunTime': lastRunTime?.toIso8601String(),
      'nextRunTime': nextRunTime?.toIso8601String(),
    };
  }

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      folderId: json['folderId'] as int,
      scheduleType: json['scheduleType'] as String,
      customCronExpression: json['customCronExpression'] as String?,
      triggerTypes: List<String>.from(json['triggerTypes'] as List? ?? []),
      triggerSpecificTime: json['triggerSpecificTime'] as String?,
      triggerSpecificDate: json['triggerSpecificDate'] != null
          ? DateTime.parse(json['triggerSpecificDate'] as String)
          : null,
      rules: SmartRules.fromJson(json['rules'] as Map<String, dynamic>? ?? {}),
      enabled: json['enabled'] as bool? ?? true,
      lastRunTime: json['lastRunTime'] != null
          ? DateTime.parse(json['lastRunTime'] as String)
          : null,
      nextRunTime: json['nextRunTime'] != null
          ? DateTime.parse(json['nextRunTime'] as String)
          : null,
    );
  }

  ScheduleConfig copyWith({
    String? name,
    int? folderId,
    String? scheduleType,
    String? customCronExpression,
    List<String>? triggerTypes,
    String? triggerSpecificTime,
    DateTime? triggerSpecificDate,
    SmartRules? rules,
    bool? enabled,
    DateTime? lastRunTime,
    DateTime? nextRunTime,
  }) {
    return ScheduleConfig(
      id: id,
      name: name ?? this.name,
      folderId: folderId ?? this.folderId,
      scheduleType: scheduleType ?? this.scheduleType,
      customCronExpression: customCronExpression ?? this.customCronExpression,
      triggerTypes: triggerTypes ?? this.triggerTypes,
      triggerSpecificTime: triggerSpecificTime ?? this.triggerSpecificTime,
      triggerSpecificDate: triggerSpecificDate ?? this.triggerSpecificDate,
      rules: rules ?? this.rules,
      enabled: enabled ?? this.enabled,
      lastRunTime: lastRunTime ?? this.lastRunTime,
      nextRunTime: nextRunTime ?? this.nextRunTime,
    );
  }
}
