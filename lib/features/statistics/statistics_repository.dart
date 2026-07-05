import '../../core/database/app_database.dart';
import '../settings/settings_database.dart';

class StatisticsRepository {
  final AppDatabase _db;
  final SettingsDatabase _settingsDb;

  StatisticsRepository(this._db, this._settingsDb);

  /// Fetch all folders in the database
  Future<List<BackupFolder>> getAllFolders() async {
    return await _db.select(_db.backupFolders).get();
  }

  /// Fetch all files in the database
  Future<List<BackupFile>> getAllFiles() async {
    return await _db.select(_db.backupFiles).get();
  }

  /// Fetch all versions in the database
  Future<List<FileVersion>> getAllFileVersions() async {
    return await _db.select(_db.fileVersions).get();
  }

  /// Fetch all log entries
  Future<List<BackupLog>> getAllLogs() async {
    return await _db.select(_db.backupLogs).get();
  }

  /// Fetch all historical backup runs
  Future<List<BackupHistoryData>> getBackupHistory() async {
    return await _db.select(_db.backupHistory).get();
  }

  /// Get settings database path or current active path
  String? getDbPath() {
    return _settingsDb.dbPath;
  }
}
