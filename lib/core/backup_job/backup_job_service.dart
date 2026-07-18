import '../../core/database/app_database.dart';
import '../../core/services/logging_service.dart';
import 'backup_job_repository.dart';

class BackupJobService {
  final BackupJobRepository _repository;
  final LoggingService _logger;
  final AppDatabase _db;

  BackupJobService(this._repository, this._logger, this._db);

  Future<BackupJob> createJob(int folderId) async {
    final folder = await _db.backupFoldersDao.getFolderById(folderId);
    if (folder == null) {
      throw Exception('Folder metadata not available');
    }

    final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';
    final job = BackupJob(
      id: jobId,
      deviceUuid: folder.deviceUuid,
      folderUuid: folder.id.toString(),
      folderId: folder.id,
      destinationUuid: folder.deviceUuid, // destinationUuid maps to deviceUuid
      createdAt: DateTime.now(),
      status: 'Waiting',
      progress: 0.0,
      totalFiles: 0,
      totalSize: 0,
      filesToBackup: 0,
      skippedFiles: 0,
    );

    await _repository.saveJob(job);
    await _logger.info('BackupJob', 'Job Queued: ${job.id}');
    return job;
  }
}
