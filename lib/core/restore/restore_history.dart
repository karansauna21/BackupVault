import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

class RestoreRecord {
  final DateTime date;
  final String location;
  final Duration duration;
  final String status;
  final int version;
  final String userAction;
  final String? errors;

  RestoreRecord({
    required this.date,
    required this.location,
    required this.duration,
    required this.status,
    required this.version,
    required this.userAction,
    this.errors,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'location': location,
      'durationMs': duration.inMilliseconds,
      'status': status,
      'version': version,
      'userAction': userAction,
      'errors': errors,
    });
  }

  factory RestoreRecord.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return RestoreRecord(
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String,
      duration: Duration(milliseconds: map['durationMs'] as int),
      status: map['status'] as String,
      version: map['version'] as int,
      userAction: map['userAction'] as String,
      errors: map['errors'] as String?,
    );
  }
}

class RestoreHistory {
  final Ref _ref;

  RestoreHistory(this._ref);

  Future<void> addRecord(RestoreRecord record) async {
    final db = _ref.read(databaseProvider);
    await db.into(db.backupLogs).insert(
      BackupLogsCompanion.insert(
        logType: 'restore',
        message: record.toJson(),
      ),
    );
  }

  Future<List<RestoreRecord>> getRecords() async {
    final db = _ref.read(databaseProvider);
    final query = db.select(db.backupLogs)..where((t) => t.logType.equals('restore'));
    final logs = await query.get();
    
    final List<RestoreRecord> list = [];
    for (final log in logs) {
      try {
        list.add(RestoreRecord.fromJson(log.message));
      } catch (_) {
        // Skip corrupted logs
      }
    }
    return list;
  }
}

final restoreHistoryProvider = Provider<RestoreHistory>((ref) {
  return RestoreHistory(ref);
});
