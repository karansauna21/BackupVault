import '../models/device_model.dart';

enum ConnectionQuality {
  excellent,
  good,
  poor,
  highLatency,
  unreachable
}

class DiscoveredDevice {
  final DeviceModel device;
  final int? latencyMs;
  final String connectionType; // 'Wi-Fi', 'Ethernet', 'Hotspot', 'Local Router'
  final ConnectionQuality connectionQuality;
  final DateTime lastSeen;
  final bool isOnline;

  DiscoveredDevice({
    required this.device,
    this.latencyMs,
    required this.connectionType,
    required this.connectionQuality,
    required this.lastSeen,
    required this.isOnline,
  });

  DiscoveredDevice copyWith({
    DeviceModel? device,
    int? latencyMs,
    String? connectionType,
    ConnectionQuality? connectionQuality,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return DiscoveredDevice(
      device: device ?? this.device,
      latencyMs: latencyMs ?? this.latencyMs,
      connectionType: connectionType ?? this.connectionType,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device.toJson(),
      'latencyMs': latencyMs,
      'connectionType': connectionType,
      'connectionQuality': connectionQuality.name,
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory DiscoveredDevice.fromJson(Map<String, dynamic> json) {
    return DiscoveredDevice(
      device: DeviceModel.fromJson(Map<String, dynamic>.from(json['device'] as Map)),
      latencyMs: json['latencyMs'] as int?,
      connectionType: json['connectionType'] as String? ?? 'Wi-Fi',
      connectionQuality: ConnectionQuality.values.byName(json['connectionQuality'] as String? ?? 'unreachable'),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}

class DiscoveryHistoryEntry {
  final String id;
  final String deviceId;
  final String deviceName;
  final String eventType; // 'Device Found', 'Device Lost', 'Network Changed', 'Reconnect Event', 'Discovery Error'
  final DateTime timestamp;
  final String ipAddress;
  final String details;

  DiscoveryHistoryEntry({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.eventType,
    required this.timestamp,
    required this.ipAddress,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'eventType': eventType,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'details': details,
    };
  }

  factory DiscoveryHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DiscoveryHistoryEntry(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      eventType: json['eventType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ipAddress'] as String? ?? '0.0.0.0',
      details: json['details'] as String? ?? '',
    );
  }
}
