import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/copy_engine/copy_job.dart';
import '../../../../core/copy_engine/copy_queue.dart';
import '../../../../core/services/backup_engine.dart';
import '../../../dashboard/dashboard_provider.dart';
import '../../../folder_manager/folder_manager_provider.dart';
import '../../workflows/backup_workflow_provider.dart';
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
    final backupWorkflow = ref.read(backupWorkflowProvider);

    state = BackupState(
      isBackingUp: true,
      currentFolderId: folder.id,
      currentFolderName: folder.name,
      progress: 0.0,
      currentStatusText: 'Scanning files...',
    );

    await logger.info('BackupService', 'Starting backup for folder: ${folder.name}');

    try {
      // Start scanning and queue building via platform-specific workflow
      final jobs = await backupWorkflow.run(folder);

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

      final scanStats = ref.read(backupEngineProvider).getScanStats(folder.id);
      final scannedCount = scanStats?.scannedCount ?? totalCount;
      final skippedCount = scanStats?.skippedCount ?? 0;

      state = state.copyWith(
        currentStatusText: 'Backing up files... (0/$totalCount completed)',
        progress: 0.0,
      );

      final stopwatch = Stopwatch()..start();
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
        int failedCount = 0;
        double copiedBytes = 0.0;

        for (final job in relevantJobs) {
          if (job.status == CopyStatus.completed) {
            finishedCount++;
            copiedBytes += job.fileSize;
          } else if (job.status == CopyStatus.failed ||
              job.status == CopyStatus.canceled) {
            finishedCount++;
            failedCount++;
          } else if (job.status == CopyStatus.copying) {
            copiedBytes += job.fileSize * job.progress;
          }
        }

        final remainingBytes = (totalSize - copiedBytes).clamp(0.0, totalSize.toDouble());
        final remainingFilesCount = relevantJobs.where((j) => j.status == CopyStatus.pending || j.status == CopyStatus.copying).length;

        final totalSpeed = relevantJobs
            .where((j) => j.status == CopyStatus.copying)
            .fold<double>(0.0, (sum, j) => sum + j.speed);

        final etaSeconds = totalSpeed > 0 ? remainingBytes / totalSpeed : 0.0;

        final overallProgress = totalSize > 0 ? (copiedBytes / totalSize) : 0.0;

        final speedStr = _formatSpeed(totalSpeed);
        final etaStr = _formatEta(etaSeconds);
        final copiedSizeStr = _formatSize(copiedBytes.toInt());
        final totalSizeStr = _formatSize(totalSize);
        final remainingSizeStr = _formatSize(remainingBytes.toInt());

        final statusText = 'Scanned: $scannedCount files | Skipped: $skippedCount\n'
            'Copied: ${finishedCount - failedCount} | Failed: $failedCount | Remaining: $remainingFilesCount files\n'
            'Size: $copiedSizeStr / $totalSizeStr (Remaining: $remainingSizeStr)\n'
            'Speed: $speedStr | ETA: $etaStr';

        state = state.copyWith(
          progress: overallProgress,
          currentStatusText: statusText,
        );

        if (finishedCount == totalCount) {
          allFinished = true;
        }
      }

      stopwatch.stop();
      final duration = stopwatch.elapsed;

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
            message: 'Backup completed successfully in ${duration.inSeconds}s. Saved $completedCount files. (Failed: $failedCount)',
            filesCount: Value(completedCount),
            totalSize: Value(totalSize),
            backupType: const Value('full'),
          ),
        );

        await logger.info(
          'BackupService',
          'Backup for "${folder.name}" completed in ${duration.inMilliseconds}ms. files: $completedCount, size: ${_formatSize(totalSize)}',
        );
      } else {
        if (failedCount > 0) {
          await db.into(db.backupHistory).insert(
            BackupHistoryCompanion.insert(
              folderId: Value(folder.id),
              timestamp: Value(DateTime.now()),
              status: 'failed',
              message: 'Backup failed in ${duration.inSeconds}s. 0 files copied. Failed: $failedCount',
              filesCount: Value(0),
              totalSize: Value(0),
              backupType: const Value('full'),
            ),
          );
        }
        await logger.warning('BackupService', 'Backup finished in ${duration.inMilliseconds}ms but 0 files were successfully copied.');
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

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(1)} B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatEta(double seconds) {
    if (seconds.isInfinite || seconds.isNaN || seconds <= 0) return '--';
    if (seconds < 60) return '${seconds.toInt()}s';
    final minutes = seconds ~/ 60;
    final remainingSecs = (seconds % 60).toInt();
    return '${minutes}m ${remainingSecs}s';
  }
}

final backupProvider = NotifierProvider<BackupNotifier, BackupState>(() {
  return BackupNotifier();
});
