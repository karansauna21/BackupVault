import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

enum V2PacketType {
  handshake,
  sessionStart,
  fileMetadata,
  chunkData,
  chunkAck,
  fileCompleted,
  sessionEnd,
  nack
}

class V2Packet {
  final V2PacketType type;
  final String sessionId;
  final String? fileId;
  final int index; // chunk index or status
  final int total; // total chunks or status
  final Uint8List payload;
  final String checksum;

  V2Packet({
    required this.type,
    required this.sessionId,
    this.fileId,
    required this.index,
    required this.total,
    required this.payload,
    required this.checksum,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sessionId': sessionId,
      'fileId': fileId,
      'index': index,
      'total': total,
      'payload': base64Encode(payload),
      'checksum': checksum,
    };
  }

  factory V2Packet.fromJson(Map<String, dynamic> json) {
    final payloadBytes = base64Decode(json['payload'] as String);
    return V2Packet(
      type: V2PacketType.values.byName(json['type'] as String),
      sessionId: json['sessionId'] as String,
      fileId: json['fileId'] as String?,
      index: json['index'] as int,
      total: json['total'] as int,
      payload: Uint8List.fromList(payloadBytes),
      checksum: json['checksum'] as String,
    );
  }

  static String calculateChecksum(Uint8List data) {
    return sha256.convert(data).toString();
  }
}
