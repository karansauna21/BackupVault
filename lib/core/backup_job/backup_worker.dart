import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/database/app_database.dart';
import '../../core/services/logging_service.dart';
import 'backup_job_repository.dart';
import '../transfer/transfer_manager.dart';

extension BackupJobExtension on BackupJob {
  BackupJob copyWithCustom({
    String? id,
    String? deviceUuid,
    String? folderUuid,
    int? folderId,
    String? destinationUuid,
    DateTime? createdAt,
    DateTime? startedTime,
    DateTime? completedTime,
    String? status,
    double? progress,
    int? totalFiles,
    int? totalSize,
    int? filesToBackup,
    int? skippedFiles,
    String? error,
  }) {
    return BackupJob(
      id: id ?? this.id,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      folderUuid: folderUuid ?? this.folderUuid,
      folderId: folderId ?? this.folderId,
      destinationUuid: destinationUuid ?? this.destinationUuid,
      createdAt: createdAt ?? this.createdAt,
      startedTime: startedTime ?? this.startedTime,
      completedTime: completedTime ?? this.completedTime,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalFiles: totalFiles ?? this.totalFiles,
      totalSize: totalSize ?? this.totalSize,
      filesToBackup: filesToBackup ?? this.filesToBackup,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      error: error ?? this.error,
    );
  }
}

class BackupJobCalculations {
  final int totalFiles;
  final int totalSize;
  final int filesToBackup;
  final int skippedFiles;

  BackupJobCalculations({
    required this.totalFiles,
    required this.totalSize,
    required this.filesToBackup,
    required this.skippedFiles,
  });
}

class BackupWorker {
  BackupJob job;
  final BackupJobRepository repository;
  final LoggingService logger;
  final AppDatabase db;
  final TransferManager transferManager;
  final Function(BackupJob) onUpdate;

  bool _isPaused = false;
  bool _isCancelled = false;

  BackupWorker({
    required this.job,
    required this.repository,
    required this.logger,
    required this.db,
    required this.transferManager,
    required this.onUpdate,
  });

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  void cancel() {
    _isCancelled = true;
  }

  Future<void> run() async {
    // 1. Transition to Preparing
    job = job.copyWithCustom(
      status: 'Preparing',
      startedTime: DateTime.now(),
    );
    await repository.saveJob(job);
    onUpdate(job);
    await logger.info('BackupJob', 'Backup Started for job ${job.id}');

    // 2. Perform validations
    final validationError = await _performValidations();
    if (validationError != null) {
      job = job.copyWithCustom(
        status: 'Failed',
        completedTime: DateTime.now(),
        error: validationError,
      );
      await repository.saveJob(job);
      onUpdate(job);
      await logger.error('BackupJob', 'Validation Failed for job ${job.id}: $validationError');
      return;
    }

    // 3. Perform calculations
    final calculations = await _performCalculations();
    job = job.copyWithCustom(
      status: 'Queued',
      totalFiles: calculations.totalFiles,
      totalSize: calculations.totalSize,
      filesToBackup: calculations.filesToBackup,
      skippedFiles: calculations.skippedFiles,
    );
    await repository.saveJob(job);
    onUpdate(job);

    // Transition to Ready
    job = job.copyWithCustom(status: 'Ready');
    await repository.saveJob(job);
    onUpdate(job);

    final folder = await db.backupFoldersDao.getFolderById(job.folderId);
    if (folder != null && folder.destinationType == 'remote' && folder.deviceUuid != null) {
      // 4. Run real V2 Transfer Engine
      final List<File> filesToBackupList = [];
      try {
        final dir = Directory(folder.sourcePath);
        if (dir.existsSync()) {
          final list = dir.listSync(recursive: true);
          for (final entity in list) {
            if (entity is File) {
              final name = p.basename(entity.path);
              if (!name.endsWith('.tmp') && !name.startsWith('~')) {
                filesToBackupList.add(entity);
              }
            }
          }
        }
      } catch (_) {}

      try {
        final transferWorker = await transferManager.createSenderWorker(
          deviceId: folder.deviceUuid!,
          sourceFolderPath: folder.sourcePath,
          files: filesToBackupList,
        );

        final progressSub = transferWorker.progressStream.listen((progress) async {
          job = job.copyWithCustom(
            progress: progress,
          );
          await repository.saveJob(job);
          onUpdate(job);
        });

        await transferWorker.start();

        while (transferWorker.session == null || transferWorker.session!.isTransferring) {
          if (_isCancelled) {
            transferWorker.cancel();
            break;
          }
          if (_isPaused) {
            transferWorker.pause();
          } else if (transferWorker.session?.isPaused == true) {
            transferWorker.resume();
          }
          await Future.delayed(const Duration(milliseconds: 200));
        }

        await progressSub.cancel();

        if (_isCancelled) {
          job = job.copyWithCustom(
            status: 'Cancelled',
            completedTime: DateTime.now(),
          );
          await repository.saveJob(job);
          onUpdate(job);
          await logger.warning('BackupJob', 'Job Cancelled: ${job.id}');
          return;
        }

        if (transferWorker.session?.sessionState == 'Failed') {
          throw Exception('File transfer failed');
        }

        // Complete
        job = job.copyWithCustom(
          status: 'Completed',
          completedTime: DateTime.now(),
        );
        await repository.saveJob(job);
        onUpdate(job);
        await logger.info('BackupJob', 'Job Completed: ${job.id}');

      } catch (e, stack) {
        job = job.copyWithCustom(
          status: 'Failed',
          completedTime: DateTime.now(),
          error: e.toString(),
        );
        await repository.saveJob(job);
        onUpdate(job);
        await logger.error('BackupJob', 'Job Failed: $e', stack.toString());
      }
    } else {
      // 4. Simulate transfer progress loop for local backup
      double currentProgress = 0.0;
      while (currentProgress < 1.0) {
        if (_isCancelled) {
          job = job.copyWithCustom(
            status: 'Cancelled',
            completedTime: DateTime.now(),
          );
          await repository.saveJob(job);
          onUpdate(job);
          await logger.warning('BackupJob', 'Job Cancelled: ${job.id}');
          return;
        }

        if (_isPaused) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        await Future.delayed(const Duration(milliseconds: 300));
        currentProgress += 0.1;
        if (currentProgress > 1.0) currentProgress = 1.0;

        job = job.copyWithCustom(progress: currentProgress);
        await repository.saveJob(job);
        onUpdate(job);
      }

      // 5. Complete
      job = job.copyWithCustom(
        status: 'Completed',
        completedTime: DateTime.now(),
      );
      await repository.saveJob(job);
      onUpdate(job);
      await logger.info('BackupJob', 'Job Completed: ${job.id}');
    }
  }

  Future<String?> _performValidations() async {
    final folder = await db.backupFoldersDao.getFolderById(job.folderId);
    if (folder == null) {
      return "Folder metadata not available";
    }

    if (!Directory(folder.sourcePath).existsSync()) {
      return "Source directory does not exist";
    }

    if (folder.destinationPath.trim().isEmpty) {
      return "Destination not configured";
    }

    // Check read permission by trying to list the directory
    try {
      Directory(folder.sourcePath).listSync();
    } catch (_) {
      return "Permissions denied for source directory";
    }

    if (folder.destinationType == 'remote' && folder.deviceUuid != null) {
      final device = await db.pairedDevicesDao.getDeviceByUuid(folder.deviceUuid!);
      if (device == null || device.status != 'Online') {
        return "Destination device is offline";
      }
    }

    // Simulate storage available check
    return null;
  }

  Future<BackupJobCalculations> _performCalculations() async {
    final folder = await db.backupFoldersDao.getFolderById(job.folderId);
    if (folder == null) {
      return BackupJobCalculations(totalFiles: 0, totalSize: 0, filesToBackup: 0, skippedFiles: 0);
    }

    int totalFiles = 0;
    int totalSize = 0;
    int filesToBackup = 0;
    int skippedFiles = 0;

    try {
      final dir = Directory(folder.sourcePath);
      if (await dir.exists()) {
        final list = dir.listSync(recursive: true);
        for (final entity in list) {
          if (entity is File) {
            totalFiles++;
            totalSize += entity.lengthSync();

            final name = p.basename(entity.path);
            if (name.endsWith('.tmp') || name.startsWith('~')) {
              skippedFiles++;
            } else {
              filesToBackup++;
            }
          }
        }
      }
    } catch (_) {}

    return BackupJobCalculations(
      totalFiles: totalFiles,
      totalSize: totalSize,
      filesToBackup: filesToBackup,
      skippedFiles: skippedFiles,
    );
  }
}
