import 'package:drift/drift.dart';
import 'package:backup_vault/core/database/app_database.dart';

class VersionHistoryRepository {
  final AppDatabase db;

  VersionHistoryRepository(this.db);

  /// Fetch all versions for a specific backup file ID, ordered by version number descending
  Future<List<FileVersion>> getVersionsByFileId(int fileId) {
    return (db.select(db.fileVersions)
          ..where((t) => t.fileId.equals(fileId))
          ..orderBy([(t) => OrderingTerm.desc(t.versionNumber)]))
        .get();
  }

  /// Get backup file metadata by ID
  Future<BackupFile?> getFileById(int fileId) {
    return (db.select(db.backupFiles)..where((t) => t.id.equals(fileId))).getSingleOrNull();
  }

  /// Get backup folder metadata by ID
  Future<BackupFolder?> getFolderById(int folderId) {
    return (db.select(db.backupFolders)..where((t) => t.id.equals(folderId))).getSingleOrNull();
  }

  /// Fetch all versions stored in the database
  Future<List<FileVersion>> getAllVersions() {
    return db.select(db.fileVersions).get();
  }

  /// Fetch all files stored in the database
  Future<List<BackupFile>> getAllFiles() {
    return db.select(db.backupFiles).get();
  }

  /// Fetch all configured backup folders
  Future<List<BackupFolder>> getAllFolders() {
    return db.select(db.backupFolders).get();
  }

  /// Insert a new file version
  Future<int> insertVersion(FileVersionsCompanion version) {
    return db.into(db.fileVersions).insert(version);
  }

  /// Delete a file version record
  Future<int> deleteVersion(int versionId) {
    return (db.delete(db.fileVersions)..where((t) => t.id.equals(versionId))).go();
  }
}
