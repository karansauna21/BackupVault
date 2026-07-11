import 'dart:convert';
import '../../features/settings/settings_database.dart';
import 'discovery_models.dart';

class DiscoveryRepository {
  final SettingsDatabase _db;

  DiscoveryRepository(this._db);

  Future<List<DiscoveredDevice>> getKnownDevices() async {
    try {
      final jsonStr = _db.getValue('discovered_devices');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => DiscoveredDevice.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveKnownDevices(List<DiscoveredDevice> devices) async {
    final list = devices.map((e) => e.toJson()).toList();
    _db.setValue('discovered_devices', json.encode(list));
  }

  Future<List<DiscoveryHistoryEntry>> getDiscoveryHistory() async {
    try {
      final jsonStr = _db.getValue('discovery_history');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => DiscoveryHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveDiscoveryHistory(List<DiscoveryHistoryEntry> history) async {
    final list = history.map((e) => e.toJson()).toList();
    _db.setValue('discovery_history', json.encode(list));
  }

  Future<void> addHistoryEntry(DiscoveryHistoryEntry entry) async {
    final current = await getDiscoveryHistory();
    current.insert(0, entry); // Most recent first
    if (current.length > 500) {
      current.removeRange(500, current.length); // Cap at 500 logs
    }
    await saveDiscoveryHistory(current);
  }

  Future<void> clearHistory() async {
    await saveDiscoveryHistory([]);
  }
}
