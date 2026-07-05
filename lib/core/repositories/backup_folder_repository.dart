import '../database/app_database.dart';

abstract class BackupFolderRepository {
  Future<List<BackupFolder>> getAllFolders();
  Stream<List<BackupFolder>> watchAllFolders();
  Future<BackupFolder?> getFolderById(int id);
  Future<int> addFolder(BackupFoldersCompanion folder);
  Future<bool> updateFolder(BackupFolder folder);
  Future<int> deleteFolder(int id);
}
