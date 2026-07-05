import '../database/app_database.dart';

abstract class BackupFileRepository {
  Future<List<BackupFile>> getAllFiles();
  Future<List<BackupFile>> getFilesByFolderId(int folderId);
  Future<BackupFile?> getFileById(int id);
  Future<int> addFile(BackupFilesCompanion file);
  Future<bool> updateFile(BackupFile file);
  Future<int> deleteFile(int id);
}
