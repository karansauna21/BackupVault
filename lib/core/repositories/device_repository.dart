import 'dart:convert';
import 'package:drift/drift.dart';
import '../../features/settings/settings_database.dart';
import '../models/device_model.dart';
import '../database/app_database.dart';

class DeviceRepository {
  final SettingsDatabase _db;
  final AppDatabase? _driftDb;

  DeviceRepository(this._db, [this._driftDb]);

  Future<void> init() async {
    // Already initialized in app startup, but safe hook
  }

  Future<List<DeviceModel>> getDevices() async {
    if (_driftDb != null) {
      try {
        final records = await _driftDb.pairedDevicesDao.getAllDevices();
        return records.map((record) => DeviceModel(
          id: record.deviceUuid,
          name: record.deviceName,
          platform: record.platform,
          osVersion: record.osVersion,
          appVersion: record.appVersion,
          deviceModel: record.deviceModel,
          pairingDate: record.createdAt,
          lastSeen: record.lastSeen,
          trustStatus: record.status,
          connectionStatus: 'Offline',
          ipAddress: '127.0.0.1',
          port: 8321,
          storageInfo: 'Unknown',
        )).toList();
      } catch (_) {}
    }

    try {
      final jsonStr = _db.getValue('paired_devices');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => DeviceModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveDevices(List<DeviceModel> devices) async {
    if (_driftDb != null) {
      try {
        for (final device in devices) {
          final companion = PairedDevicesCompanion(
            deviceUuid: Value(device.id),
            deviceName: Value(device.name),
            platform: Value(device.platform),
            osVersion: Value(device.osVersion),
            appVersion: Value(device.appVersion),
            deviceModel: Value(device.deviceModel),
            createdAt: Value(device.pairingDate),
            lastSeen: Value(device.lastSeen),
            status: Value(device.trustStatus),
          );
          final existing = await _driftDb.pairedDevicesDao.getDeviceByUuid(device.id);
          if (existing != null) {
            await _driftDb.pairedDevicesDao.updateDevice(
              PairedDevice(
                deviceUuid: device.id,
                deviceName: device.name,
                platform: device.platform,
                osVersion: device.osVersion,
                appVersion: device.appVersion,
                deviceModel: device.deviceModel,
                createdAt: device.pairingDate,
                lastSeen: device.lastSeen,
                status: device.trustStatus,
              ),
            );
          } else {
            await _driftDb.pairedDevicesDao.insertDevice(companion);
          }
        }
      } catch (_) {}
    }

    final list = devices.map((e) => e.toJson()).toList();
    _db.setValue('paired_devices', json.encode(list));
  }

  Future<void> addOrUpdateDevice(DeviceModel device) async {
    if (_driftDb != null) {
      try {
        final companion = PairedDevicesCompanion(
          deviceUuid: Value(device.id),
          deviceName: Value(device.name),
          platform: Value(device.platform),
          osVersion: Value(device.osVersion),
          appVersion: Value(device.appVersion),
          deviceModel: Value(device.deviceModel),
          createdAt: Value(device.pairingDate),
          lastSeen: Value(device.lastSeen),
          status: Value(device.trustStatus),
        );
        final existing = await _driftDb.pairedDevicesDao.getDeviceByUuid(device.id);
        if (existing != null) {
          await _driftDb.pairedDevicesDao.updateDevice(
            PairedDevice(
              deviceUuid: device.id,
              deviceName: device.name,
              platform: device.platform,
              osVersion: device.osVersion,
              appVersion: device.appVersion,
              deviceModel: device.deviceModel,
              createdAt: device.pairingDate,
              lastSeen: device.lastSeen,
              status: device.trustStatus,
            ),
          );
        } else {
          await _driftDb.pairedDevicesDao.insertDevice(companion);
        }
      } catch (_) {}
    }

    final current = await getDevices();
    final index = current.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      current[index] = device;
    } else {
      current.add(device);
    }
    final list = current.map((e) => e.toJson()).toList();
    _db.setValue('paired_devices', json.encode(list));
  }

  Future<void> removeDevice(String id) async {
    if (_driftDb != null) {
      try {
        await _driftDb.pairedDevicesDao.deleteDeviceByUuid(id);
      } catch (_) {}
    }

    final current = await getDevices();
    current.removeWhere((d) => d.id == id);
    final list = current.map((e) => e.toJson()).toList();
    _db.setValue('paired_devices', json.encode(list));
  }

  Future<DeviceModel?> getDeviceById(String id) async {
    if (_driftDb != null) {
      try {
        final record = await _driftDb.pairedDevicesDao.getDeviceByUuid(id);
        if (record != null) {
          return DeviceModel(
            id: record.deviceUuid,
            name: record.deviceName,
            platform: record.platform,
            osVersion: record.osVersion,
            appVersion: record.appVersion,
            deviceModel: record.deviceModel,
            pairingDate: record.createdAt,
            lastSeen: record.lastSeen,
            trustStatus: record.status,
            connectionStatus: 'Offline',
            ipAddress: '127.0.0.1',
            port: 8321,
            storageInfo: 'Unknown',
          );
        }
      } catch (_) {}
    }

    final current = await getDevices();
    for (final d in current) {
      if (d.id == id) return d;
    }
    return null;
  }
}
