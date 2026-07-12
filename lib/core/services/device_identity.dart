import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../features/settings/settings_database.dart';
import '../models/device_model.dart';
import 'storage_provider.dart';

class DeviceIdentity {
  final SettingsDatabase _db;
  final StorageProvider _storageProvider;
  
  late final String _uuid;
  late String _name;
  late final String _platform;
  late final String _osVersion;
  late final String _appVersion;
  late final String _deviceModel;
  late final DateTime _createdAt;
  late DateTime _lastSeen;
  
  bool _isInitialized = false;
  
  DeviceIdentity(this._db, this._storageProvider);

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Load or generate unique Device UUID
    String? storedUuid = _db.getValue('self_device_uuid');
    if (storedUuid == null) {
      storedUuid = const Uuid().v4();
      _db.setValue('self_device_uuid', storedUuid);
    }
    _uuid = storedUuid;

    // 2. Load or generate Device Name
    String? storedName = _db.getValue('self_device_name');
    if (storedName == null) {
      storedName = Platform.localHostname;
      // Filter out empty or localhost hostnames
      if (storedName.isEmpty || storedName == 'localhost') {
        storedName = Platform.isWindows ? 'Windows PC' : 'Android Device';
      }
      _db.setValue('self_device_name', storedName);
    }
    _name = storedName;

    // 3. Platform
    String? storedPlatform = _db.getValue('self_device_platform');
    if (storedPlatform == null) {
      if (Platform.isWindows) {
        storedPlatform = 'Windows';
      } else if (Platform.isAndroid) {
        storedPlatform = 'Android';
      } else if (Platform.isLinux) {
        storedPlatform = 'Linux';
      } else if (Platform.isMacOS) {
        storedPlatform = 'macOS';
      } else {
        storedPlatform = Platform.operatingSystem;
      }
      _db.setValue('self_device_platform', storedPlatform);
    }
    _platform = storedPlatform;

    // 4. OS Version
    String? storedOsVersion = _db.getValue('self_device_os_version');
    if (storedOsVersion == null) {
      storedOsVersion = Platform.operatingSystemVersion;
      _db.setValue('self_device_os_version', storedOsVersion);
    }
    _osVersion = storedOsVersion;

    // 5. App Version
    String? storedAppVersion = _db.getValue('self_device_app_version');
    if (storedAppVersion == null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        storedAppVersion = packageInfo.version;
      } catch (_) {
        storedAppVersion = '1.0.0';
      }
      _db.setValue('self_device_app_version', storedAppVersion);
    }
    _appVersion = storedAppVersion;

    // 6. Device Model
    String? storedDeviceModel = _db.getValue('self_device_model');
    if (storedDeviceModel == null) {
      if (Platform.isWindows) {
        storedDeviceModel = 'PC Desktop';
      } else if (Platform.isAndroid) {
        storedDeviceModel = 'Mobile Phone';
      } else {
        storedDeviceModel = 'BackupVault Device';
      }
      _db.setValue('self_device_model', storedDeviceModel);
    }
    _deviceModel = storedDeviceModel;

    // 7. Created Date
    String? storedCreatedAt = _db.getValue('self_device_created_at');
    if (storedCreatedAt == null) {
      storedCreatedAt = DateTime.now().toIso8601String();
      _db.setValue('self_device_created_at', storedCreatedAt);
    }
    _createdAt = DateTime.parse(storedCreatedAt);

    // 8. Last Seen
    final now = DateTime.now();
    _db.setValue('self_device_last_seen', now.toIso8601String());
    _lastSeen = now;
  }

  String get id => _uuid;
  String get name => _name;
  String get platform => _platform;
  String get osVersion => _osVersion;
  String get appVersion => _appVersion;
  String get deviceModel => _deviceModel;
  DateTime get createdAt => _createdAt;
  DateTime get lastSeen => _lastSeen;

  void rename(String newName) {
    _name = newName;
    _db.setValue('self_device_name', newName);
  }

  Future<String> getStorageInfo() async {
    try {
      final path = Platform.isWindows ? 'C:\\' : '/sdcard';
      final stats = await _storageProvider.getDiskFreeSpace(path);
      if (stats != null) {
        final totalBytes = stats['total'] ?? 0;
        final freeBytes = stats['free'] ?? 0;
        final usedBytes = totalBytes - freeBytes;
        
        final usedGb = (usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
        final totalGb = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
        return "$usedGb GB / $totalGb GB";
      }
    } catch (_) {}
    return "Unknown";
  }

  Future<DeviceModel> toModel({String ip = '127.0.0.1', int port = 8321}) async {
    final storage = await getStorageInfo();
    return DeviceModel(
      id: id,
      name: name,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      deviceModel: deviceModel,
      pairingDate: createdAt,
      lastSeen: lastSeen,
      trustStatus: 'Trusted',
      connectionStatus: 'Online',
      ipAddress: ip,
      port: port,
      storageInfo: storage,
    );
  }
}
