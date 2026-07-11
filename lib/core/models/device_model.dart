class DeviceModel {
  final String id; // UUID
  final String name;
  final String platform; // 'Android', 'Windows', 'Linux', 'macOS'
  final String osVersion;
  final String appVersion;
  final String deviceModel;
  final DateTime pairingDate;
  final DateTime lastSeen;
  final String trustStatus; // 'Trusted', 'Pending', 'Blocked'
  final String connectionStatus; // 'Online', 'Offline'
  final String ipAddress;
  final int port;
  final String storageInfo; // e.g. "120 GB / 256 GB"
  final String? pairingToken;
  final DateTime? pairingTokenExpiry;

  DeviceModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.deviceModel,
    required this.pairingDate,
    required this.lastSeen,
    required this.trustStatus,
    required this.connectionStatus,
    required this.ipAddress,
    required this.port,
    required this.storageInfo,
    this.pairingToken,
    this.pairingTokenExpiry,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'deviceModel': deviceModel,
      'pairingDate': pairingDate.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'trustStatus': trustStatus,
      'connectionStatus': connectionStatus,
      'ipAddress': ipAddress,
      'port': port,
      'storageInfo': storageInfo,
      'pairingToken': pairingToken,
      'pairingTokenExpiry': pairingTokenExpiry?.toIso8601String(),
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      osVersion: json['osVersion'] as String,
      appVersion: json['appVersion'] as String,
      deviceModel: json['deviceModel'] as String,
      pairingDate: DateTime.parse(json['pairingDate'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      trustStatus: json['trustStatus'] as String,
      connectionStatus: json['connectionStatus'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      storageInfo: json['storageInfo'] as String? ?? 'Unknown',
      pairingToken: json['pairingToken'] as String?,
      pairingTokenExpiry: json['pairingTokenExpiry'] != null
          ? DateTime.parse(json['pairingTokenExpiry'] as String)
          : null,
    );
  }

  DeviceModel copyWith({
    String? name,
    String? platform,
    String? osVersion,
    String? appVersion,
    String? deviceModel,
    DateTime? pairingDate,
    DateTime? lastSeen,
    String? trustStatus,
    String? connectionStatus,
    String? ipAddress,
    int? port,
    String? storageInfo,
    String? pairingToken,
    DateTime? pairingTokenExpiry,
  }) {
    return DeviceModel(
      id: id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      deviceModel: deviceModel ?? this.deviceModel,
      pairingDate: pairingDate ?? this.pairingDate,
      lastSeen: lastSeen ?? this.lastSeen,
      trustStatus: trustStatus ?? this.trustStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      storageInfo: storageInfo ?? this.storageInfo,
      pairingToken: pairingToken ?? this.pairingToken,
      pairingTokenExpiry: pairingTokenExpiry ?? this.pairingTokenExpiry,
    );
  }
}
