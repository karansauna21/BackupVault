import '../../database/app_database.dart';
import '../file_version_repository.dart';

class FileVersionRepositoryImpl implements FileVersionRepository {
  final FileVersionsDao _dao;

  FileVersionRepositoryImpl(this._dao);

  @override
  Future<List<FileVersion>> getAllVersions() => _dao.getAllVersions();

  @override
  Future<List<FileVersion>> getVersionsByFileId(int fileId) => _dao.getVersionsByFileId(fileId);

  @override
  Future<int> addVersion(FileVersionsCompanion version) => _dao.insertVersion(version);

  @override
  Future<bool> updateVersion(FileVersion version) => _dao.updateVersion(version);

  @override
  Future<int> deleteVersion(int id) => _dao.deleteVersionById(id);
}
