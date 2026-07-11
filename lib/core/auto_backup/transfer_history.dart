class TransferHistoryEntry {
  final String id;
  final String fileId;
  final String fileName;
  final int fileSize;
  final String sourceDevice;
  final String destDevice;
  final String status; // "Success", "Failed", "Retry"
  final DateTime timestamp;
  final String sha256;
  final String? errorMessage;
  final double speedBytesPerSec;
  final int durationMs;

  TransferHistoryEntry({
    required this.id,
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.sourceDevice,
    required this.destDevice,
    required this.status,
    required this.timestamp,
    required this.sha256,
    this.errorMessage,
    required this.speedBytesPerSec,
    required this.durationMs,
  });

  factory TransferHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TransferHistoryEntry(
      id: json['id'] as String,
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      sourceDevice: json['sourceDevice'] as String,
      destDevice: json['destDevice'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sha256: json['sha256'] as String? ?? '',
      errorMessage: json['errorMessage'] as String?,
      speedBytesPerSec: (json['speedBytesPerSec'] as num? ?? 0.0).toDouble(),
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileId': fileId,
    'fileName': fileName,
    'fileSize': fileSize,
    'sourceDevice': sourceDevice,
    'destDevice': destDevice,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'sha256': sha256,
    'errorMessage': errorMessage,
    'speedBytesPerSec': speedBytesPerSec,
    'durationMs': durationMs,
  };
}
