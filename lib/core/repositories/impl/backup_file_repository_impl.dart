import '../../database/app_database.dart';
import '../backup_file_repository.dart';

class BackupFileRepositoryImpl implements BackupFileRepository {
  final BackupFilesDao _dao;

  BackupFileRepositoryImpl(this._dao);

  @override
  Future<List<BackupFile>> getAllFiles() => _dao.getAllFiles();

  @override
  Future<List<BackupFile>> getFilesByFolderId(int folderId) => _dao.getFilesByFolderId(folderId);

  @override
  Future<BackupFile?> getFileById(int id) => _dao.getFileById(id);

  @override
  Future<int> addFile(BackupFilesCompanion file) => _dao.insertFile(file);

  @override
  Future<bool> updateFile(BackupFile file) => _dao.updateFile(file);

  @override
  Future<int> deleteFile(int id) => _dao.deleteFileById(id);
}
