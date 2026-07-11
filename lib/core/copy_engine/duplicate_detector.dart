// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'package:path/path.dart' as p;
import '../repositories/backup_file_repository.dart';

class DuplicateDetector {
  final BackupFileRepository _fileRepository;

  DuplicateDetector({
    required BackupFileRepository fileRepository,
  }) : _fileRepository = fileRepository;

  Future<String?> findDuplicateBackupPath({
    required String sha256,
    required int fileSize,
    required int folderId,
    required String currentDestinationPath,
  }) async {
    if (sha256.isEmpty) return null;
    final allFiles = await _fileRepository.getAllFiles();
    for (final file in allFiles) {
      if (file.folderId == folderId &&
          file.sha256 == sha256 &&
          file.fileSize == fileSize &&
          file.backupStatus == 'success') {
        if (p.isWithin(currentDestinationPath, file.backupPath) &&
            await File(file.backupPath).exists()) {
          return file.backupPath;
        }
      }
    }
    return null;
  }
}
