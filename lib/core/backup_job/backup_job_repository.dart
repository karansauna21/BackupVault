import '../../core/database/app_database.dart';

abstract class BackupJobRepository {
  Future<List<BackupJob>> getAllJobs();
  Stream<List<BackupJob>> watchAllJobs();
  Future<BackupJob?> getJobById(String id);
  Future<void> saveJob(BackupJob job);
  Future<void> deleteJob(String id);
  Future<void> clearAllJobs();
}

class BackupJobRepositoryImpl implements BackupJobRepository {
  final AppDatabase _db;

  BackupJobRepositoryImpl(this._db);

  @override
  Future<List<BackupJob>> getAllJobs() => _db.backupJobsDao.getAllJobs();

  @override
  Stream<List<BackupJob>> watchAllJobs() => _db.backupJobsDao.watchAllJobs();

  @override
  Future<BackupJob?> getJobById(String id) => _db.backupJobsDao.getJobById(id);

  @override
  Future<void> saveJob(BackupJob job) async {
    final existing = await _db.backupJobsDao.getJobById(job.id);
    if (existing != null) {
      await _db.backupJobsDao.updateJob(job);
    } else {
      await _db.backupJobsDao.insertJob(job.toCompanion(true));
    }
  }

  @override
  Future<void> deleteJob(String id) => _db.backupJobsDao.deleteJobById(id);

  @override
  Future<void> clearAllJobs() => _db.backupJobsDao.clearAllJobs();
}
