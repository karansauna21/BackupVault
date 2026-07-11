import 'dart:convert';
import '../../features/settings/settings_database.dart';

class DeviceSelectionManager {
  final SettingsDatabase _db;

  DeviceSelectionManager(this._db);

  List<String> getSelectedDestinationDeviceIds() {
    final str = _db.getValue('auto_backup_dest_devices');
    if (str != null) {
      try {
        final decoded = json.decode(str) as List<dynamic>;
        return decoded.cast<String>();
      } catch (_) {}
    }
    return [];
  }

  void saveSelectedDestinationDeviceIds(List<String> deviceIds) {
    _db.setValue('auto_backup_dest_devices', json.encode(deviceIds));
  }
  
  String? getSelectedSourceDeviceId() {
    return _db.getValue('auto_backup_source_device') ?? 'local_device';
  }

  void saveSelectedSourceDeviceId(String id) {
    _db.setValue('auto_backup_source_device', id);
  }
}
