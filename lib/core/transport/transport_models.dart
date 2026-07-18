import 'dart:typed_data';

enum SessionStatus {
  active,
  completed,
  interrupted,
  failed
}

class TransferSessionModel {
  final String id;
  final String deviceId;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final int totalFiles;
  final int completedFiles;
  final int totalBytes;
  final int completedBytes;
  final int bandwidthLimit; // in bytes/sec, 0 for unlimited

  TransferSessionModel({
    required this.id,
    required this.deviceId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.totalFiles,
    required this.completedFiles,
    required this.totalBytes,
    required this.completedBytes,
    required this.bandwidthLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'totalFiles': totalFiles,
      'completedFiles': completedFiles,
      'totalBytes': totalBytes,
      'completedBytes': completedBytes,
      'bandwidthLimit': bandwidthLimit,
    };
  }

  factory TransferSessionModel.fromJson(Map<String, dynamic> json) {
    return TransferSessionModel(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      status: SessionStatus.values.byName(json['status'] as String),
      totalFiles: json['totalFiles'] as int,
      completedFiles: json['completedFiles'] as int,
      totalBytes: json['totalBytes'] as int,
      completedBytes: json['completedBytes'] as int,
      bandwidthLimit: json['bandwidthLimit'] as int,
    );
  }

  TransferSessionModel copyWith({
    DateTime? endTime,
    SessionStatus? status,
    int? totalFiles,
    int? completedFiles,
    int? totalBytes,
    int? completedBytes,
    int? bandwidthLimit,
  }) {
    return TransferSessionModel(
      id: id,
      deviceId: deviceId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalFiles: totalFiles ?? this.totalFiles,
      completedFiles: completedFiles ?? this.completedFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      completedBytes: completedBytes ?? this.completedBytes,
      bandwidthLimit: bandwidthLimit ?? this.bandwidthLimit,
    );
  }
}

enum TransferStatus {
  pending,
  transferring,
  completed,
  failed,
  cancelled
}

class TransferHistoryModel {
  final String id;
  final String sessionId;
  final String fileName;
  final String relativePath;
  final int fileSize;
  final int bytesTransferred;
  final TransferStatus status;
  final String? errorMessage;
  final int durationMs;
  final DateTime timestamp;

  TransferHistoryModel({
    required this.id,
    required this.sessionId,
    required this.fileName,
    required this.relativePath,
    required this.fileSize,
    required this.bytesTransferred,
    required this.status,
    this.errorMessage,
    required this.durationMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'fileName': fileName,
      'relativePath': relativePath,
      'fileSize': fileSize,
      'bytesTransferred': bytesTransferred,
      'status': status.name,
      'errorMessage': errorMessage,
      'durationMs': durationMs,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransferHistoryModel.fromJson(Map<String, dynamic> json) {
    return TransferHistoryModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      fileName: json['fileName'] as String,
      relativePath: json['relativePath'] as String,
      fileSize: json['fileSize'] as int,
      bytesTransferred: json['bytesTransferred'] as int,
      status: TransferStatus.values.byName(json['status'] as String),
      errorMessage: json['errorMessage'] as String?,
      durationMs: json['durationMs'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

enum ConnectionEventType {
  connected,
  disconnected,
  reconnected,
  reconnectFailed
}

class ConnectionHistoryModel {
  final String id;
  final String deviceId;
  final DateTime timestamp;
  final ConnectionEventType eventType;
  final String ipAddress;
  final int port;

  ConnectionHistoryModel({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.eventType,
    required this.ipAddress,
    required this.port,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.name,
      'ipAddress': ipAddress,
      'port': port,
    };
  }

  factory ConnectionHistoryModel.fromJson(Map<String, dynamic> json) {
    return ConnectionHistoryModel(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventType: ConnectionEventType.values.byName(json['eventType'] as String),
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
    );
  }
}

class TransferStatisticsModel {
  final int totalBytesSent;
  final int totalBytesReceived;
  final int totalFilesSent;
  final int totalFilesReceived;
  final double averageSpeedBytesPerSec;
  final int activeTransfersCount;

  TransferStatisticsModel({
    required this.totalBytesSent,
    required this.totalBytesReceived,
    required this.totalFilesSent,
    required this.totalFilesReceived,
    required this.averageSpeedBytesPerSec,
    required this.activeTransfersCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalBytesSent': totalBytesSent,
      'totalBytesReceived': totalBytesReceived,
      'totalFilesSent': totalFilesSent,
      'totalFilesReceived': totalFilesReceived,
      'averageSpeedBytesPerSec': averageSpeedBytesPerSec,
      'activeTransfersCount': activeTransfersCount,
    };
  }

  factory TransferStatisticsModel.fromJson(Map<String, dynamic> json) {
    return TransferStatisticsModel(
      totalBytesSent: json['totalBytesSent'] as int,
      totalBytesReceived: json['totalBytesReceived'] as int,
      totalFilesSent: json['totalFilesSent'] as int,
      totalFilesReceived: json['totalFilesReceived'] as int,
      averageSpeedBytesPerSec: (json['averageSpeedBytesPerSec'] as num).toDouble(),
      activeTransfersCount: json['activeTransfersCount'] as int,
    );
  }

  TransferStatisticsModel copyWith({
    int? totalBytesSent,
    int? totalBytesReceived,
    int? totalFilesSent,
    int? totalFilesReceived,
    double? averageSpeedBytesPerSec,
    int? activeTransfersCount,
  }) {
    return TransferStatisticsModel(
      totalBytesSent: totalBytesSent ?? this.totalBytesSent,
      totalBytesReceived: totalBytesReceived ?? this.totalBytesReceived,
      totalFilesSent: totalFilesSent ?? this.totalFilesSent,
      totalFilesReceived: totalFilesReceived ?? this.totalFilesReceived,
      averageSpeedBytesPerSec: averageSpeedBytesPerSec ?? this.averageSpeedBytesPerSec,
      activeTransfersCount: activeTransfersCount ?? this.activeTransfersCount,
    );
  }
}

class TransportErrorModel {
  final String id;
  final String deviceId;
  final DateTime timestamp;
  final String errorType;
  final String errorMessage;
  final String? stackTrace;

  TransportErrorModel({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'errorType': errorType,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
    };
  }

  factory TransportErrorModel.fromJson(Map<String, dynamic> json) {
    return TransportErrorModel(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      errorType: json['errorType'] as String,
      errorMessage: json['errorMessage'] as String,
      stackTrace: json['stackTrace'] as String?,
    );
  }
}

enum PacketType {
  handshakeChallenge,
  handshakeResponse,
  authVerify,
  heartbeat,
  heartbeatAck,
  sessionStart,
  fileMetadata,
  fileData,
  fileAck,
  fileNack,
  sessionEnd,
  disconnectNotice,
  remoteFoldersRequest,
  remoteFoldersResponse,
  createFolderRequest,
  createFolderResponse,
  renameFolderRequest,
  renameFolderResponse,
  syncDestinationMetadata
}

class TransportPacket {
  final String sessionId;
  final PacketType type;
  final int packetIndex;
  final int totalPackets;
  final int payloadLength;
  final Uint8List payload;
  final String checksum; // SHA-256 checksum of payload
  final int timestampMs;

  TransportPacket({
    required this.sessionId,
    required this.type,
    required this.packetIndex,
    required this.totalPackets,
    required this.payloadLength,
    required this.payload,
    required this.checksum,
    required this.timestampMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'type': type.name,
      'packetIndex': packetIndex,
      'totalPackets': totalPackets,
      'payloadLength': payloadLength,
      'payload': payload.toList(),
      'checksum': checksum,
      'timestampMs': timestampMs,
    };
  }

  factory TransportPacket.fromJson(Map<String, dynamic> json) {
    final list = json['payload'] as List<dynamic>;
    return TransportPacket(
      sessionId: json['sessionId'] as String,
      type: PacketType.values.byName(json['type'] as String),
      packetIndex: json['packetIndex'] as int,
      totalPackets: json['totalPackets'] as int,
      payloadLength: json['payloadLength'] as int,
      payload: Uint8List.fromList(list.cast<int>()),
      checksum: json['checksum'] as String,
      timestampMs: json['timestampMs'] as int,
    );
  }
}
