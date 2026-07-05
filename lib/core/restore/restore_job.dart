enum RestoreStatus {
  pending,
  restoring,
  completed,
  failed,
  paused,
  canceled
}

class RestoreJob {
  final String id;
  final int fileId;
  final String sourceBackupPath;
  final String targetRestorePath;
  final int fileSize;
  final int versionNumber;
  final RestoreStatus status;
  final double progress;
  final String? error;
  final int retryCount;
  final String sha256;
  final Duration? duration;
  final DateTime? restoreTime;

  RestoreJob({
    required this.id,
    required this.fileId,
    required this.sourceBackupPath,
    required this.targetRestorePath,
    required this.fileSize,
    required this.versionNumber,
    required this.sha256,
    this.status = RestoreStatus.pending,
    this.progress = 0.0,
    this.error,
    this.retryCount = 0,
    this.duration,
    this.restoreTime,
  });

  RestoreJob copyWith({
    RestoreStatus? status,
    double? progress,
    String? error,
    int? retryCount,
    Duration? duration,
    DateTime? restoreTime,
    String? targetRestorePath,
  }) {
    return RestoreJob(
      id: id,
      fileId: fileId,
      sourceBackupPath: sourceBackupPath,
      targetRestorePath: targetRestorePath ?? this.targetRestorePath,
      fileSize: fileSize,
      versionNumber: versionNumber,
      sha256: sha256,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      retryCount: retryCount ?? this.retryCount,
      duration: duration ?? this.duration,
      restoreTime: restoreTime ?? this.restoreTime,
    );
  }
}
