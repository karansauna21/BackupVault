// ignore_for_file: prefer_initializing_formals
import '../repositories/backup_file_repository.dart';

class DuplicateDetector {
  final BackupFileRepository _fileRepository;

  DuplicateDetector({
    required BackupFileRepository fileRepository,
  }) : _fileRepository = fileRepository;

  Future<String?> findDuplicateBackupPath(String sha256, int fileSize) async {
    if (sha256.isEmpty) return null;
    final allFiles = await _fileRepository.getAllFiles();
    for (final file in allFiles) {
      if (file.sha256 == sha256 && file.fileSize == fileSize && file.backupStatus == 'success') {
        return file.backupPath;
      }
    }
    return null;
  }
}
