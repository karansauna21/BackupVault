import '../../database/app_database.dart';
import '../backup_folder_repository.dart';

class BackupFolderRepositoryImpl implements BackupFolderRepository {
  final BackupFoldersDao _dao;

  BackupFolderRepositoryImpl(this._dao);

  @override
  Future<List<BackupFolder>> getAllFolders() => _dao.getAllFolders();

  @override
  Stream<List<BackupFolder>> watchAllFolders() => _dao.watchAllFolders();

  @override
  Future<BackupFolder?> getFolderById(int id) => _dao.getFolderById(id);

  @override
  Future<int> addFolder(BackupFoldersCompanion folder) => _dao.insertFolder(folder);

  @override
  Future<bool> updateFolder(BackupFolder folder) => _dao.updateFolder(folder);

  @override
  Future<int> deleteFolder(int id) => _dao.deleteFolderById(id);
}
