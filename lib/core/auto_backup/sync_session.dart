class SyncSession {
  final String id;
  final String sourceDeviceId;
  final String destDeviceId;
  final String status; // "Connected", "Syncing", "Waiting", "Paused", "Offline", "Failed"
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalFiles;
  final int completedFiles;
  final int totalBytes;
  final int completedBytes;
  final String? currentFile;
  final double currentSpeed; // in bytes/second
  final int etaSeconds;

  SyncSession({
    required this.id,
    required this.sourceDeviceId,
    required this.destDeviceId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.totalFiles,
    required this.completedFiles,
    required this.totalBytes,
    required this.completedBytes,
    this.currentFile,
    required this.currentSpeed,
    required this.etaSeconds,
  });

  SyncSession copyWith({
    String? status,
    DateTime? completedAt,
    int? totalFiles,
    int? completedFiles,
    int? totalBytes,
    int? completedBytes,
    String? currentFile,
    double? currentSpeed,
    int? etaSeconds,
  }) {
    return SyncSession(
      id: id,
      sourceDeviceId: sourceDeviceId,
      destDeviceId: destDeviceId,
      status: status ?? this.status,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalFiles: totalFiles ?? this.totalFiles,
      completedFiles: completedFiles ?? this.completedFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      completedBytes: completedBytes ?? this.completedBytes,
      currentFile: currentFile ?? this.currentFile,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      etaSeconds: etaSeconds ?? this.etaSeconds,
    );
  }

  factory SyncSession.fromJson(Map<String, dynamic> json) {
    return SyncSession(
      id: json['id'] as String,
      sourceDeviceId: json['sourceDeviceId'] as String,
      destDeviceId: json['destDeviceId'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      totalFiles: json['totalFiles'] as int? ?? 0,
      completedFiles: json['completedFiles'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      completedBytes: json['completedBytes'] as int? ?? 0,
      currentFile: json['currentFile'] as String?,
      currentSpeed: (json['currentSpeed'] as num? ?? 0).toDouble(),
      etaSeconds: json['etaSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceDeviceId': sourceDeviceId,
    'destDeviceId': destDeviceId,
    'status': status,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'totalFiles': totalFiles,
    'completedFiles': completedFiles,
    'totalBytes': totalBytes,
    'completedBytes': completedBytes,
    'currentFile': currentFile,
    'currentSpeed': currentSpeed,
    'etaSeconds': etaSeconds,
  };
}
