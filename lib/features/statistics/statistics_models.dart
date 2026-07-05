import 'package:flutter/material.dart';

/// Overall metrics state for the dashboard cards
class BackupStats {
  final int totalBackupSize;
  final int todaysBackupSize;
  final int weeklyBackupSize;
  final int monthlyBackupSize;
  final int totalFiles;
  final int backedUpToday;
  final int versionedFilesCount;
  final int duplicateFilesCount;
  final int duplicateStorageBytes;
  final int skippedFilesCount;
  final int failedFilesCount;
  final int restoredFilesCount;
  final int foldersMonitored;
  final int currentQueueCount;
  final int storageUsedBytes;
  final int storageAvailableBytes;
  final double averageBackupSpeed; // in MB/s
  final double averageRestoreSpeed; // in MB/s

  const BackupStats({
    this.totalBackupSize = 0,
    this.todaysBackupSize = 0,
    this.weeklyBackupSize = 0,
    this.monthlyBackupSize = 0,
    this.totalFiles = 0,
    this.backedUpToday = 0,
    this.versionedFilesCount = 0,
    this.duplicateFilesCount = 0,
    this.duplicateStorageBytes = 0,
    this.skippedFilesCount = 0,
    this.failedFilesCount = 0,
    this.restoredFilesCount = 0,
    this.foldersMonitored = 0,
    this.currentQueueCount = 0,
    this.storageUsedBytes = 0,
    this.storageAvailableBytes = 0,
    this.averageBackupSpeed = 0.0,
    this.averageRestoreSpeed = 0.0,
  });

  BackupStats copyWith({
    int? totalBackupSize,
    int? todaysBackupSize,
    int? weeklyBackupSize,
    int? monthlyBackupSize,
    int? totalFiles,
    int? backedUpToday,
    int? versionedFilesCount,
    int? duplicateFilesCount,
    int? duplicateStorageBytes,
    int? skippedFilesCount,
    int? failedFilesCount,
    int? restoredFilesCount,
    int? foldersMonitored,
    int? currentQueueCount,
    int? storageUsedBytes,
    int? storageAvailableBytes,
    double? averageBackupSpeed,
    double? averageRestoreSpeed,
  }) {
    return BackupStats(
      totalBackupSize: totalBackupSize ?? this.totalBackupSize,
      todaysBackupSize: todaysBackupSize ?? this.todaysBackupSize,
      weeklyBackupSize: weeklyBackupSize ?? this.weeklyBackupSize,
      monthlyBackupSize: monthlyBackupSize ?? this.monthlyBackupSize,
      totalFiles: totalFiles ?? this.totalFiles,
      backedUpToday: backedUpToday ?? this.backedUpToday,
      versionedFilesCount: versionedFilesCount ?? this.versionedFilesCount,
      duplicateFilesCount: duplicateFilesCount ?? this.duplicateFilesCount,
      duplicateStorageBytes: duplicateStorageBytes ?? this.duplicateStorageBytes,
      skippedFilesCount: skippedFilesCount ?? this.skippedFilesCount,
      failedFilesCount: failedFilesCount ?? this.failedFilesCount,
      restoredFilesCount: restoredFilesCount ?? this.restoredFilesCount,
      foldersMonitored: foldersMonitored ?? this.foldersMonitored,
      currentQueueCount: currentQueueCount ?? this.currentQueueCount,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      storageAvailableBytes: storageAvailableBytes ?? this.storageAvailableBytes,
      averageBackupSpeed: averageBackupSpeed ?? this.averageBackupSpeed,
      averageRestoreSpeed: averageRestoreSpeed ?? this.averageRestoreSpeed,
    );
  }
}

/// A single data point on a chart
class ChartDataPoint {
  final String label; // e.g. "Mon", "07/04", "TXT"
  final double value; // e.g. size in MB, duration in ms, count
  final DateTime? date;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
  });
}

/// Representation of interactive chart options and data
class AnalyticsCharts {
  final List<ChartDataPoint> dailyBackupTrend;
  final List<ChartDataPoint> weeklyBackupTrend;
  final List<ChartDataPoint> monthlyBackupTrend;
  final List<ChartDataPoint> yearlyBackupTrend;
  final List<ChartDataPoint> storageGrowth;
  final List<ChartDataPoint> backupSpeed;
  final List<ChartDataPoint> restoreSpeed;
  final List<ChartDataPoint> fileTypeDistribution;
  final List<ChartDataPoint> folderSizeDistribution;
  final List<ChartDataPoint> backupSuccessRate; // Success vs Fail Donut
  final List<ChartDataPoint> restoreSuccessRate;
  final List<ChartDataPoint> errorTrend;
  final List<ChartDataPoint> versionHistoryGrowth;
  final List<ChartDataPoint> workerUtilization;
  final List<ChartDataPoint> queuePerformance;

  const AnalyticsCharts({
    this.dailyBackupTrend = const [],
    this.weeklyBackupTrend = const [],
    this.monthlyBackupTrend = const [],
    this.yearlyBackupTrend = const [],
    this.storageGrowth = const [],
    this.backupSpeed = const [],
    this.restoreSpeed = const [],
    this.fileTypeDistribution = const [],
    this.folderSizeDistribution = const [],
    this.backupSuccessRate = const [],
    this.restoreSuccessRate = const [],
    this.errorTrend = const [],
    this.versionHistoryGrowth = const [],
    this.workerUtilization = const [],
    this.queuePerformance = const [],
  });
}

/// Storage Analysis data holder
class StorageAnalysis {
  final List<FolderSizeInfo> largestFolders;
  final List<FileSizeInfo> largestFiles;
  final String mostActiveFolder;
  final String leastActiveFolder;
  final int duplicateStorageSavedBytes;
  final int estimatedFutureStorageBytes30Days;
  final bool isLowStoragePredicted;
  final int estimatedRemainingDays; // -1 if stable or infinite

  const StorageAnalysis({
    this.largestFolders = const [],
    this.largestFiles = const [],
    this.mostActiveFolder = 'N/A',
    this.leastActiveFolder = 'N/A',
    this.duplicateStorageSavedBytes = 0,
    this.estimatedFutureStorageBytes30Days = 0,
    this.isLowStoragePredicted = false,
    this.estimatedRemainingDays = -1,
  });
}

class FolderSizeInfo {
  final String name;
  final String path;
  final int sizeBytes;

  const FolderSizeInfo({required this.name, required this.path, required this.sizeBytes});
}

class FileSizeInfo {
  final String name;
  final String path;
  final int sizeBytes;

  const FileSizeInfo({required this.name, required this.path, required this.sizeBytes});
}

/// Performance analysis details
class PerformanceAnalysis {
  final double averageCopySpeedMbps;
  final double averageVerifyTimeSeconds;
  final double averageRestoreTimeSeconds;
  final Map<String, double> workerUtilizationPercent;
  final double cpuUsagePercent;
  final double ramUsagePercent;
  final List<JobSpeedInfo> slowestJobs;
  final List<JobSpeedInfo> fastestJobs;
  final double queueEfficiencyPercent;

  const PerformanceAnalysis({
    this.averageCopySpeedMbps = 0.0,
    this.averageVerifyTimeSeconds = 0.0,
    this.averageRestoreTimeSeconds = 0.0,
    this.workerUtilizationPercent = const {},
    this.cpuUsagePercent = 0.0,
    this.ramUsagePercent = 0.0,
    this.slowestJobs = const [],
    this.fastestJobs = const [],
    this.queueEfficiencyPercent = 100.0,
  });
}

class JobSpeedInfo {
  final String jobName;
  final double speedMbps;
  final int durationMs;
  final int sizeBytes;

  const JobSpeedInfo({
    required this.jobName,
    required this.speedMbps,
    required this.durationMs,
    required this.sizeBytes,
  });
}

/// Recommendations for improving score
class HealthRecommendation {
  final String title;
  final String description;
  final String severity; // low, medium, high
  final IconData icon;

  const HealthRecommendation({
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
  });
}

/// Backup Health report card
class BackupHealth {
  final int score; // 0 to 100
  final Map<String, int> scoreFactors;
  final List<HealthRecommendation> recommendations;

  const BackupHealth({
    this.score = 100,
    this.scoreFactors = const {},
    this.recommendations = const [],
  });
}

/// Selection criteria for stats filters
class StatisticsFilter {
  final int? folderId;
  final DateTimeRange? dateRange;
  final String? backupJobId;
  final String? fileType;
  final String? status;
  final String? workerId;
  final String? storageDevice;

  const StatisticsFilter({
    this.folderId,
    this.dateRange,
    this.backupJobId,
    this.fileType,
    this.status,
    this.workerId,
    this.storageDevice,
  });

  bool get isEmpty =>
      folderId == null &&
      dateRange == null &&
      backupJobId == null &&
      fileType == null &&
      status == null &&
      workerId == null &&
      storageDevice == null;

  StatisticsFilter copyWith({
    int? folderId,
    DateTimeRange? dateRange,
    String? backupJobId,
    String? fileType,
    String? status,
    String? workerId,
    String? storageDevice,
    bool clearFolder = false,
    bool clearDateRange = false,
  }) {
    return StatisticsFilter(
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      backupJobId: backupJobId ?? this.backupJobId,
      fileType: fileType ?? this.fileType,
      status: status ?? this.status,
      workerId: workerId ?? this.workerId,
      storageDevice: storageDevice ?? this.storageDevice,
    );
  }
}
