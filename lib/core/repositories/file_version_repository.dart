import '../database/app_database.dart';

abstract class FileVersionRepository {
  Future<List<FileVersion>> getAllVersions();
  Future<List<FileVersion>> getVersionsByFileId(int fileId);
  Future<int> addVersion(FileVersionsCompanion version);
  Future<int> deleteVersion(int id);
}
