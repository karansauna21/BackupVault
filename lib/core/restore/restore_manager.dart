// ignore_for_file: prefer_initializing_formals
import '../database/app_database.dart';
import '../repositories/backup_file_repository.dart';
import '../repositories/file_version_repository.dart';

// Helper extension
extension _ListExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class RestoreManager {
  final BackupFileRepository _fileRepository;
  final FileVersionRepository _versionRepository;

  RestoreManager({
    required BackupFileRepository fileRepository,
    required FileVersionRepository versionRepository,
  })  : _fileRepository = fileRepository,
        _versionRepository = versionRepository;

  Future<List<BackupFile>> searchBackupFiles({
    String? filename,
    String? extension,
    int? folderId,
    DateTime? backupDate,
    String? originalPath,
    int? minSize,
    int? maxSize,
    String? sha256,
  }) async {
    final allFiles = await _fileRepository.getAllFiles();
    return allFiles.where((file) {
      if (filename != null && !file.fileName.toLowerCase().contains(filename.toLowerCase())) return false;
      if (extension != null && !file.extension.toLowerCase().contains(extension.toLowerCase())) return false;
      if (folderId != null && file.folderId != folderId) return false;
      if (backupDate != null) {
        final start = DateTime(backupDate.year, backupDate.month, backupDate.day);
        final end = start.add(const Duration(days: 1));
        if (file.createdAt.isBefore(start) || file.createdAt.isAfter(end)) return false;
      }
      if (originalPath != null && !file.originalPath.toLowerCase().contains(originalPath.toLowerCase())) return false;
      if (minSize != null && file.fileSize < minSize) return false;
      if (maxSize != null && file.fileSize > maxSize) return false;
      if (sha256 != null && file.sha256.toLowerCase() != sha256.toLowerCase()) return false;
      return true;
    }).toList();
  }

  Future<List<FileVersion>> getFileVersions(int fileId) async {
    return _versionRepository.getVersionsByFileId(fileId);
  }

  Future<FileVersion?> getVersionByNumber(int fileId, int versionNumber) async {
    final versions = await getFileVersions(fileId);
    return versions.firstWhereOrNull((v) => v.versionNumber == versionNumber);
  }
}
