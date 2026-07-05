import 'package:backup_vault/core/database/app_database.dart';

class SearchIndexer {
  final AppDatabase db;

  SearchIndexer(this.db);

  /// Performs an optimization of indices inside SQLite (ANALYZE updates query planner stats)
  Future<void> optimizeIndexes() async {
    await db.customStatement('ANALYZE;');
  }

  /// Force SQLite to rebuild all indices in the database
  Future<void> reindexDatabase() async {
    await db.customStatement('REINDEX;');
    await db.customStatement('ANALYZE;');
  }

  /// Get metadata stats about current indexed files, logs, versions
  Future<Map<String, dynamic>> getIndexerStats() async {
    final fileCount = await db.select(db.backupFiles).get();
    final versionCount = await db.select(db.fileVersions).get();
    final logCount = await db.select(db.backupLogs).get();

    final totalSizeBytes = fileCount.fold<int>(0, (sum, f) => sum + f.fileSize);

    return {
      'totalFiles': fileCount.length,
      'totalVersions': versionCount.length,
      'totalLogs': logCount.length,
      'totalIndexedSizeBytes': totalSizeBytes,
      'lastIndexTime': DateTime.now().toIso8601String(),
    };
  }
}
