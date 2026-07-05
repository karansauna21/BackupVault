class SystemHealthStatus {
  final String backupEngineStatus;
  final String restoreEngineStatus;
  final String fileWatcherStatus;
  final String schedulerStatus;
  final String notificationStatus;
  final String databaseStatus;
  final String backgroundStatus;
  final String systemTrayStatus;
  final String storageStatus;
  final String configurationStatus;

  const SystemHealthStatus({
    this.backupEngineStatus = 'Healthy',
    this.restoreEngineStatus = 'Healthy',
    this.fileWatcherStatus = 'Healthy',
    this.schedulerStatus = 'Healthy',
    this.notificationStatus = 'Healthy',
    this.databaseStatus = 'Healthy',
    this.backgroundStatus = 'Healthy',
    this.systemTrayStatus = 'Healthy',
    this.storageStatus = 'Healthy',
    this.configurationStatus = 'Healthy',
  });

  Map<String, dynamic> toJson() => {
    'backupEngineStatus': backupEngineStatus,
    'restoreEngineStatus': restoreEngineStatus,
    'fileWatcherStatus': fileWatcherStatus,
    'schedulerStatus': schedulerStatus,
    'notificationStatus': notificationStatus,
    'databaseStatus': databaseStatus,
    'backgroundStatus': backgroundStatus,
    'systemTrayStatus': systemTrayStatus,
    'storageStatus': storageStatus,
    'configurationStatus': configurationStatus,
  };

  factory SystemHealthStatus.fromJson(Map<String, dynamic> json) => SystemHealthStatus(
    backupEngineStatus: json['backupEngineStatus'] ?? 'Healthy',
    restoreEngineStatus: json['restoreEngineStatus'] ?? 'Healthy',
    fileWatcherStatus: json['fileWatcherStatus'] ?? 'Healthy',
    schedulerStatus: json['schedulerStatus'] ?? 'Healthy',
    notificationStatus: json['notificationStatus'] ?? 'Healthy',
    databaseStatus: json['databaseStatus'] ?? 'Healthy',
    backgroundStatus: json['backgroundStatus'] ?? 'Healthy',
    systemTrayStatus: json['systemTrayStatus'] ?? 'Healthy',
    storageStatus: json['storageStatus'] ?? 'Healthy',
    configurationStatus: json['configurationStatus'] ?? 'Healthy',
  );

  SystemHealthStatus copyWith({
    String? backupEngineStatus,
    String? restoreEngineStatus,
    String? fileWatcherStatus,
    String? schedulerStatus,
    String? notificationStatus,
    String? databaseStatus,
    String? backgroundStatus,
    String? systemTrayStatus,
    String? storageStatus,
    String? configurationStatus,
  }) => SystemHealthStatus(
    backupEngineStatus: backupEngineStatus ?? this.backupEngineStatus,
    restoreEngineStatus: restoreEngineStatus ?? this.restoreEngineStatus,
    fileWatcherStatus: fileWatcherStatus ?? this.fileWatcherStatus,
    schedulerStatus: schedulerStatus ?? this.schedulerStatus,
    notificationStatus: notificationStatus ?? this.notificationStatus,
    databaseStatus: databaseStatus ?? this.databaseStatus,
    backgroundStatus: backgroundStatus ?? this.backgroundStatus,
    systemTrayStatus: systemTrayStatus ?? this.systemTrayStatus,
    storageStatus: storageStatus ?? this.storageStatus,
    configurationStatus: configurationStatus ?? this.configurationStatus,
  );
}

class PerformanceMetrics {
  final double cpuUsagePercent;
  final double ramUsageMb;
  final double diskUsagePercent;
  final double diskReadSpeedMbPerSec;
  final double diskWriteSpeedMbPerSec;
  final double backupSpeedMbPerSec;
  final double restoreSpeedMbPerSec;
  final int activeQueueLength;
  final int fileWatcherEventsHandled;
  final double databaseQuerySpeedMs;

  const PerformanceMetrics({
    this.cpuUsagePercent = 0.0,
    this.ramUsageMb = 0.0,
    this.diskUsagePercent = 0.0,
    this.diskReadSpeedMbPerSec = 0.0,
    this.diskWriteSpeedMbPerSec = 0.0,
    this.backupSpeedMbPerSec = 0.0,
    this.restoreSpeedMbPerSec = 0.0,
    this.activeQueueLength = 0,
    this.fileWatcherEventsHandled = 0,
    this.databaseQuerySpeedMs = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'cpuUsagePercent': cpuUsagePercent,
    'ramUsageMb': ramUsageMb,
    'diskUsagePercent': diskUsagePercent,
    'diskReadSpeedMbPerSec': diskReadSpeedMbPerSec,
    'diskWriteSpeedMbPerSec': diskWriteSpeedMbPerSec,
    'backupSpeedMbPerSec': backupSpeedMbPerSec,
    'restoreSpeedMbPerSec': restoreSpeedMbPerSec,
    'activeQueueLength': activeQueueLength,
    'fileWatcherEventsHandled': fileWatcherEventsHandled,
    'databaseQuerySpeedMs': databaseQuerySpeedMs,
  };

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) => PerformanceMetrics(
    cpuUsagePercent: (json['cpuUsagePercent'] as num?)?.toDouble() ?? 0.0,
    ramUsageMb: (json['ramUsageMb'] as num?)?.toDouble() ?? 0.0,
    diskUsagePercent: (json['diskUsagePercent'] as num?)?.toDouble() ?? 0.0,
    diskReadSpeedMbPerSec: (json['diskReadSpeedMbPerSec'] as num?)?.toDouble() ?? 0.0,
    diskWriteSpeedMbPerSec: (json['diskWriteSpeedMbPerSec'] as num?)?.toDouble() ?? 0.0,
    backupSpeedMbPerSec: (json['backupSpeedMbPerSec'] as num?)?.toDouble() ?? 0.0,
    restoreSpeedMbPerSec: (json['restoreSpeedMbPerSec'] as num?)?.toDouble() ?? 0.0,
    activeQueueLength: json['activeQueueLength'] as int? ?? 0,
    fileWatcherEventsHandled: json['fileWatcherEventsHandled'] as int? ?? 0,
    databaseQuerySpeedMs: (json['databaseQuerySpeedMs'] as num?)?.toDouble() ?? 0.0,
  );
}

class DiagnosticsReport {
  final int healthScore;
  final int performanceScore;
  final int storageScore;
  final int databaseScore;
  final int overallSystemScore;
  final List<String> recommendations;
  final DateTime generatedAt;

  const DiagnosticsReport({
    this.healthScore = 100,
    this.performanceScore = 100,
    this.storageScore = 100,
    this.databaseScore = 100,
    this.overallSystemScore = 100,
    this.recommendations = const [],
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'healthScore': healthScore,
    'performanceScore': performanceScore,
    'storageScore': storageScore,
    'databaseScore': databaseScore,
    'overallSystemScore': overallSystemScore,
    'recommendations': recommendations,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory DiagnosticsReport.fromJson(Map<String, dynamic> json) => DiagnosticsReport(
    healthScore: json['healthScore'] as int? ?? 100,
    performanceScore: json['performanceScore'] as int? ?? 100,
    storageScore: json['storageScore'] as int? ?? 100,
    databaseScore: json['databaseScore'] as int? ?? 100,
    overallSystemScore: json['overallSystemScore'] as int? ?? 100,
    recommendations: List<String>.from(json['recommendations'] ?? []),
    generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
  );
}

class CrashReport {
  final String id;
  final String type;
  final String message;
  final String stackTrace;
  final DateTime timestamp;
  final String recoveryStatus; // Pending, Recovered, Failed

  const CrashReport({
    required this.id,
    required this.type,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    required this.recoveryStatus,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'message': message,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'recoveryStatus': recoveryStatus,
  };

  factory CrashReport.fromJson(Map<String, dynamic> json) => CrashReport(
    id: json['id'] ?? '',
    type: json['type'] ?? 'Unknown',
    message: json['message'] ?? '',
    stackTrace: json['stackTrace'] ?? '',
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    recoveryStatus: json['recoveryStatus'] ?? 'Pending',
  );

  CrashReport copyWith({
    String? id,
    String? type,
    String? message,
    String? stackTrace,
    DateTime? timestamp,
    String? recoveryStatus,
  }) => CrashReport(
    id: id ?? this.id,
    type: type ?? this.type,
    message: message ?? this.message,
    stackTrace: stackTrace ?? this.stackTrace,
    timestamp: timestamp ?? this.timestamp,
    recoveryStatus: recoveryStatus ?? this.recoveryStatus,
  );
}

class BenchmarkResult {
  final String id;
  final String name;
  final DateTime date;
  final double speedMbPerSec;
  final int filesCount;
  final double totalSizeMb;
  final double durationSeconds;
  final String type; // daily, weekly, monthly, custom

  const BenchmarkResult({
    required this.id,
    required this.name,
    required this.date,
    required this.speedMbPerSec,
    required this.filesCount,
    required this.totalSizeMb,
    required this.durationSeconds,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'speedMbPerSec': speedMbPerSec,
    'filesCount': filesCount,
    'totalSizeMb': totalSizeMb,
    'durationSeconds': durationSeconds,
    'type': type,
  };

  factory BenchmarkResult.fromJson(Map<String, dynamic> json) => BenchmarkResult(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    speedMbPerSec: (json['speedMbPerSec'] as num?)?.toDouble() ?? 0.0,
    filesCount: json['filesCount'] as int? ?? 0,
    totalSizeMb: (json['totalSizeMb'] as num?)?.toDouble() ?? 0.0,
    durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
    type: json['type'] ?? 'custom',
  );
}
