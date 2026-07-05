class DashboardStats {
  final String backupStatus; // "Idle", "Backing Up", "Paused", "Error"
  final String engineStatus;
  final int totalBackupSize;
  final int todaysBackupSize;
  final int totalFiles;
  final int filesBackedUpToday;
  final int failedFiles;
  final int pendingQueueSize;
  final int restoreJobsCount;
  final int watchedFoldersCount;
  final int totalStorageBytes;
  final int availableStorageBytes;
  final DateTime? lastBackupTime;
  final double averageBackupSpeed;

  DashboardStats({
    required this.backupStatus,
    required this.engineStatus,
    required this.totalBackupSize,
    required this.todaysBackupSize,
    required this.totalFiles,
    required this.filesBackedUpToday,
    required this.failedFiles,
    required this.pendingQueueSize,
    required this.restoreJobsCount,
    required this.watchedFoldersCount,
    required this.totalStorageBytes,
    required this.availableStorageBytes,
    this.lastBackupTime,
    required this.averageBackupSpeed,
  });

  factory DashboardStats.initial() {
    return DashboardStats(
      backupStatus: 'Idle',
      engineStatus: 'Running',
      totalBackupSize: 0,
      todaysBackupSize: 0,
      totalFiles: 0,
      filesBackedUpToday: 0,
      failedFiles: 0,
      pendingQueueSize: 0,
      restoreJobsCount: 0,
      watchedFoldersCount: 0,
      totalStorageBytes: 1, // Prevent division by zero
      availableStorageBytes: 1,
      lastBackupTime: null,
      averageBackupSpeed: 0.0,
    );
  }

  DashboardStats copyWith({
    String? backupStatus,
    String? engineStatus,
    int? totalBackupSize,
    int? todaysBackupSize,
    int? totalFiles,
    int? filesBackedUpToday,
    int? failedFiles,
    int? pendingQueueSize,
    int? restoreJobsCount,
    int? watchedFoldersCount,
    int? totalStorageBytes,
    int? availableStorageBytes,
    DateTime? lastBackupTime,
    double? averageBackupSpeed,
  }) {
    return DashboardStats(
      backupStatus: backupStatus ?? this.backupStatus,
      engineStatus: engineStatus ?? this.engineStatus,
      totalBackupSize: totalBackupSize ?? this.totalBackupSize,
      todaysBackupSize: todaysBackupSize ?? this.todaysBackupSize,
      totalFiles: totalFiles ?? this.totalFiles,
      filesBackedUpToday: filesBackedUpToday ?? this.filesBackedUpToday,
      failedFiles: failedFiles ?? this.failedFiles,
      pendingQueueSize: pendingQueueSize ?? this.pendingQueueSize,
      restoreJobsCount: restoreJobsCount ?? this.restoreJobsCount,
      watchedFoldersCount: watchedFoldersCount ?? this.watchedFoldersCount,
      totalStorageBytes: totalStorageBytes ?? this.totalStorageBytes,
      availableStorageBytes: availableStorageBytes ?? this.availableStorageBytes,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      averageBackupSpeed: averageBackupSpeed ?? this.averageBackupSpeed,
    );
  }
}

class ActivityEvent {
  final String id;
  final String title;
  final String description;
  final String type; // 'info', 'warning', 'error', 'success'
  final DateTime timestamp;

  ActivityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });
}
