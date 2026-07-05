enum CopyStatus {
  pending,
  copying,
  completed,
  failed,
  paused,
  canceled
}

class CopyJob {
  final String id;
  final int folderId;
  final String folderName;
  final String sourcePath;
  final String destinationPath;
  final int fileSize;
  final CopyStatus status;
  final double progress;
  final double speed; // Bytes per second
  final String? error;
  final int retryCount;
  final String? workerId;
  final String? sha256;
  final Duration? duration;
  final DateTime? backupTime;

  CopyJob({
    required this.id,
    required this.folderId,
    required this.folderName,
    required this.sourcePath,
    required this.destinationPath,
    required this.fileSize,
    this.status = CopyStatus.pending,
    this.progress = 0.0,
    this.speed = 0.0,
    this.error,
    this.retryCount = 0,
    this.workerId,
    this.sha256,
    this.duration,
    this.backupTime,
  });

  CopyJob copyWith({
    CopyStatus? status,
    double? progress,
    double? speed,
    String? error,
    int? retryCount,
    String? workerId,
    String? sha256,
    Duration? duration,
    DateTime? backupTime,
    String? destinationPath,
  }) {
    return CopyJob(
      id: id,
      folderId: folderId,
      folderName: folderName,
      sourcePath: sourcePath,
      destinationPath: destinationPath ?? this.destinationPath,
      fileSize: fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      error: error ?? this.error,
      retryCount: retryCount ?? this.retryCount,
      workerId: workerId ?? this.workerId,
      sha256: sha256 ?? this.sha256,
      duration: duration ?? this.duration,
      backupTime: backupTime ?? this.backupTime,
    );
  }
}
