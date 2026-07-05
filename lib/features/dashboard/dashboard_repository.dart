// ignore_for_file: prefer_initializing_formals
import '../../core/database/app_database.dart';
import '../../core/repositories/backup_file_repository.dart';
import '../../core/repositories/backup_folder_repository.dart';
import '../../core/repositories/backup_log_repository.dart';
import '../../core/repositories/repository_providers.dart';
import 'dashboard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardRepository {
  final BackupFolderRepository _folderRepo;
  final BackupFileRepository _fileRepo;
  final BackupLogRepository _logRepo;

  DashboardRepository({
    required BackupFolderRepository folderRepo,
    required BackupFileRepository fileRepo,
    required BackupLogRepository logRepo,
  })  : _folderRepo = folderRepo,
        _fileRepo = fileRepo,
        _logRepo = logRepo;

  Future<DashboardStats> fetchStats() async {
    final folders = await _folderRepo.getAllFolders();
    final files = await _fileRepo.getAllFiles();
    final logs = await _logRepo.getAllLogs();

    final activeFoldersCount = folders.where((f) => f.enabled).length;

    int totalBackupSize = 0;
    int todaysBackupSize = 0;
    int totalFiles = files.length;
    int filesBackedUpToday = 0;
    int failedFiles = 0;
    DateTime? lastBackupTime;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final file in files) {
      if (file.backupStatus == 'success') {
        totalBackupSize += file.fileSize;
        if (file.createdAt.isAfter(todayStart)) {
          todaysBackupSize += file.fileSize;
          filesBackedUpToday++;
        }
      } else if (file.backupStatus == 'failed') {
        failedFiles++;
      }

      if (lastBackupTime == null || file.createdAt.isAfter(lastBackupTime)) {
        lastBackupTime = file.createdAt;
      }
    }

    final restoreLogsCount = logs.where((l) => l.logType == 'restore').length;

    // Default mock disk storage values
    int totalStorageBytes = 512 * 1024 * 1024 * 1024;
    int availableStorageBytes = 128 * 1024 * 1024 * 1024;

    return DashboardStats(
      backupStatus: 'Idle',
      engineStatus: 'Running',
      totalBackupSize: totalBackupSize,
      todaysBackupSize: todaysBackupSize,
      totalFiles: totalFiles,
      filesBackedUpToday: filesBackedUpToday,
      failedFiles: failedFiles,
      pendingQueueSize: 0,
      restoreJobsCount: restoreLogsCount,
      watchedFoldersCount: activeFoldersCount,
      totalStorageBytes: totalStorageBytes,
      availableStorageBytes: availableStorageBytes,
      lastBackupTime: lastBackupTime,
      averageBackupSpeed: 0.0,
    );
  }

  Future<List<ActivityEvent>> fetchRecentActivity() async {
    final logs = await _logRepo.getAllLogs();
    // Get latest 10 logs
    final sortedLogs = List<BackupLog>.from(logs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final recent = sortedLogs.take(10);
    return recent.map((backupLog) {
      String type = 'info';
      if (backupLog.logType == 'error') {
        type = 'error';
      } else if (backupLog.logType == 'warning') {
        type = 'warning';
      } else if (backupLog.logType == 'restore') {
        type = 'success';
      }

      return ActivityEvent(
        id: backupLog.id.toString(),
        title: _logTypeTitle(backupLog.logType),
        description: backupLog.message,
        type: type,
        timestamp: backupLog.createdAt,
      );
    }).toList();
  }

  String _logTypeTitle(String logType) {
    switch (logType) {
      case 'info':
        return 'System Info';
      case 'warning':
        return 'Warning Alert';
      case 'error':
        return 'Error Occurred';
      case 'restore':
        return 'Restore Action';
      default:
        return 'Activity Event';
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final folderRepo = ref.watch(backupFolderRepositoryProvider);
  final fileRepo = ref.watch(backupFileRepositoryProvider);
  final logRepo = ref.watch(backupLogRepositoryProvider);

  return DashboardRepository(
    folderRepo: folderRepo,
    fileRepo: fileRepo,
    logRepo: logRepo,
  );
});
