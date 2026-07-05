import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/backup_engine.dart';
import '../../../../core/copy_engine/copy_job.dart';
import '../../../../core/copy_engine/copy_queue.dart';
import '../../../dashboard/dashboard_provider.dart';
import '../../../folder_manager/folder_manager_provider.dart';
import 'backup_state.dart';

class BackupNotifier extends Notifier<BackupState> {
  @override
  BackupState build() {
    return BackupState();
  }

  Future<void> runBackup(BackupFolder folder) async {
    if (state.isBackingUp) return;

    final db = ref.read(databaseProvider);
    final logger = ref.read(loggingServiceProvider);
    final backupEngine = ref.read(backupEngineProvider);

    state = BackupState(
      isBackingUp: true,
      currentFolderId: folder.id,
      currentFolderName: folder.name,
      progress: 0.0,
      currentStatusText: 'Scanning files...',
    );

    await logger.info('BackupService', 'Starting backup for folder: ${folder.name}');

    try {
      // Start scanning and queue building
      final jobs = await backupEngine.backupFolder(folder);

      if (jobs.isEmpty) {
        await logger.info('BackupService', 'No new or modified files found for folder: ${folder.name}');
        state = BackupState(
          isBackingUp: false,
          currentStatusText: 'Up to date. No files copied.',
        );
        ref.invalidate(dashboardProvider);
        // ignore: unused_result
        ref.refresh(folderManagerProvider);
        return;
      }

      final jobIds = jobs.map((j) => j.id).toSet();
      final totalCount = jobs.length;
      final totalSize = jobs.fold<int>(0, (sum, j) => sum + j.fileSize);

      state = state.copyWith(
        currentStatusText: 'Backing up files... (0/$totalCount completed)',
        progress: 0.0,
      );

      bool allFinished = false;
      List<CopyJob> relevantJobs = [];

      while (!allFinished) {
        await Future.delayed(const Duration(milliseconds: 200));

        final currentQueue = ref.read(copyQueueProvider);
        relevantJobs = currentQueue.where((j) => jobIds.contains(j.id)).toList();

        if (relevantJobs.isEmpty) {
          allFinished = true;
          break;
        }

        int finishedCount = 0;
        double sumProgress = 0.0;

        for (final job in relevantJobs) {
          if (job.status == CopyStatus.completed ||
              job.status == CopyStatus.failed ||
              job.status == CopyStatus.canceled) {
            finishedCount++;
            sumProgress += 1.0;
          } else if (job.status == CopyStatus.copying) {
            sumProgress += job.progress;
          }
        }

        final overallProgress = sumProgress / totalCount;
        state = state.copyWith(
          progress: overallProgress,
          currentStatusText: 'Backing up files... ($finishedCount/$totalCount completed)',
        );

        if (finishedCount == totalCount) {
          allFinished = true;
        }
      }

      // Check results
      final completedCount = relevantJobs.where((j) => j.status == CopyStatus.completed).length;
      final failedCount = relevantJobs.where((j) => j.status == CopyStatus.failed || j.status == CopyStatus.canceled).length;

      if (completedCount > 0) {
        final now = DateTime.now();

        // Update folder info
        await (db.update(db.backupFolders)..where((t) => t.id.equals(folder.id))).write(
          BackupFoldersCompanion(
            lastBackupAt: Value(now),
          ),
        );

        // Insert backup history record
        await db.into(db.backupHistory).insert(
          BackupHistoryCompanion.insert(
            folderId: Value(folder.id),
            timestamp: Value(now),
            status: 'success',
            message: 'Backup completed successfully. Saved $completedCount files. (Failed: $failedCount)',
            filesCount: Value(completedCount),
            totalSize: Value(totalSize),
            backupType: const Value('full'),
          ),
        );

        await logger.info(
          'BackupService',
          'Backup for "${folder.name}" completed. files: $completedCount, size: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      } else {
        // Never report success if zero files were successfully copied
        if (failedCount > 0) {
          await db.into(db.backupHistory).insert(
            BackupHistoryCompanion.insert(
              folderId: Value(folder.id),
              timestamp: Value(DateTime.now()),
              status: 'failed',
              message: 'Backup failed. 0 files copied. Failed: $failedCount',
              filesCount: Value(0),
              totalSize: Value(0),
              backupType: const Value('full'),
            ),
          );
        }
        await logger.warning('BackupService', 'Backup finished but 0 files were successfully copied.');
      }

      // Refresh list and dashboard
      ref.invalidate(dashboardProvider);
      // ignore: unused_result
      ref.refresh(folderManagerProvider);

      state = BackupState(); // Reset state
    } catch (e, stack) {
      await logger.error('BackupService', 'Backup failed for "${folder.name}": $e', stack.toString());
      
      // Save failure record
      try {
        await db.into(db.backupHistory).insert(
          BackupHistoryCompanion.insert(
            folderId: Value(folder.id),
            timestamp: Value(DateTime.now()),
            status: 'failed',
            message: 'Backup failed: $e',
          ),
        );
      } catch (_) {}

      state = BackupState(); // Reset state
      ref.invalidate(dashboardProvider);
    }
  }
}

final backupProvider = NotifierProvider<BackupNotifier, BackupState>(() {
  return BackupNotifier();
});
