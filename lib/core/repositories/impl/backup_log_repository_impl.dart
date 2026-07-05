import '../../database/app_database.dart';
import '../backup_log_repository.dart';

class BackupLogRepositoryImpl implements BackupLogRepository {
  final BackupLogsDao _dao;

  BackupLogRepositoryImpl(this._dao);

  @override
  Future<List<BackupLog>> getAllLogs({String? logType, int limit = 200}) => _dao.getAllLogs(logType: logType, limit: limit);

  @override
  Future<int> addLog(BackupLogsCompanion log) => _dao.insertLog(log);

  @override
  Future<int> clearLogs() => _dao.clearAllLogs();
}
