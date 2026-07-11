import 'dart:convert';
import '../../features/settings/settings_database.dart';
import 'transport_models.dart';

class TransportRepository {
  final SettingsDatabase _db;

  TransportRepository(this._db);

  // --- Sessions ---
  Future<List<TransferSessionModel>> getSessions() async {
    try {
      final jsonStr = _db.getValue('transport_sessions');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => TransferSessionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveSessions(List<TransferSessionModel> sessions) async {
    final list = sessions.map((e) => e.toJson()).toList();
    _db.setValue('transport_sessions', json.encode(list));
  }

  Future<void> addOrUpdateSession(TransferSessionModel session) async {
    final current = await getSessions();
    final index = current.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      current[index] = session;
    } else {
      current.add(session);
    }
    await saveSessions(current);
  }

  // --- Transfer History ---
  Future<List<TransferHistoryModel>> getTransferHistory() async {
    try {
      final jsonStr = _db.getValue('transfer_history');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => TransferHistoryModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveTransferHistory(List<TransferHistoryModel> history) async {
    final list = history.map((e) => e.toJson()).toList();
    _db.setValue('transfer_history', json.encode(list));
  }

  Future<void> addTransferHistoryEntry(TransferHistoryModel entry) async {
    final current = await getTransferHistory();
    current.add(entry);
    // Keep last 1000 entries
    if (current.length > 1000) {
      current.removeAt(0);
    }
    await saveTransferHistory(current);
  }

  // --- Connection History ---
  Future<List<ConnectionHistoryModel>> getConnectionHistory() async {
    try {
      final jsonStr = _db.getValue('connection_history');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => ConnectionHistoryModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveConnectionHistory(List<ConnectionHistoryModel> history) async {
    final list = history.map((e) => e.toJson()).toList();
    _db.setValue('connection_history', json.encode(list));
  }

  Future<void> addConnectionHistoryEntry(ConnectionHistoryModel entry) async {
    final current = await getConnectionHistory();
    current.add(entry);
    // Keep last 500 entries
    if (current.length > 500) {
      current.removeAt(0);
    }
    await saveConnectionHistory(current);
  }

  // --- Transfer Statistics ---
  Future<TransferStatisticsModel> getStatistics() async {
    try {
      final jsonStr = _db.getValue('transfer_statistics');
      if (jsonStr != null) {
        return TransferStatisticsModel.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    return TransferStatisticsModel(
      totalBytesSent: 0,
      totalBytesReceived: 0,
      totalFilesSent: 0,
      totalFilesReceived: 0,
      averageSpeedBytesPerSec: 0.0,
      activeTransfersCount: 0,
    );
  }

  Future<void> saveStatistics(TransferStatisticsModel stats) async {
    _db.setValue('transfer_statistics', json.encode(stats.toJson()));
  }

  Future<void> updateStatistics(int bytesSent, int bytesReceived, int filesSent, int filesReceived, double speed) async {
    final current = await getStatistics();
    // Running average for speed
    double newSpeed = current.averageSpeedBytesPerSec;
    if (speed > 0) {
      if (current.averageSpeedBytesPerSec == 0.0) {
        newSpeed = speed;
      } else {
        newSpeed = (current.averageSpeedBytesPerSec * 0.9) + (speed * 0.1);
      }
    }

    final updated = current.copyWith(
      totalBytesSent: current.totalBytesSent + bytesSent,
      totalBytesReceived: current.totalBytesReceived + bytesReceived,
      totalFilesSent: current.totalFilesSent + filesSent,
      totalFilesReceived: current.totalFilesReceived + filesReceived,
      averageSpeedBytesPerSec: newSpeed,
    );
    await saveStatistics(updated);
  }

  // --- Errors ---
  Future<List<TransportErrorModel>> getErrors() async {
    try {
      final jsonStr = _db.getValue('transport_errors');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => TransportErrorModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveErrors(List<TransportErrorModel> errors) async {
    final list = errors.map((e) => e.toJson()).toList();
    _db.setValue('transport_errors', json.encode(list));
  }

  Future<void> addErrorEntry(TransportErrorModel entry) async {
    final current = await getErrors();
    current.add(entry);
    // Keep last 200 entries
    if (current.length > 200) {
      current.removeAt(0);
    }
    await saveErrors(current);
  }
}
