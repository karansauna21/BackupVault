import '../database/app_database.dart';

abstract class BackupLogRepository {
  Future<List<BackupLog>> getAllLogs({String? logType, int limit = 200});
  Future<int> addLog(BackupLogsCompanion log);
  Future<int> clearLogs();
}
