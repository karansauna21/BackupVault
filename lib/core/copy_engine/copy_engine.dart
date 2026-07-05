// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../repositories/backup_file_repository.dart';
import '../repositories/file_version_repository.dart';
import '../repositories/repository_providers.dart';
import '../services/logging_service.dart';
import 'copy_job.dart';
import 'copy_queue.dart';
import 'copy_worker.dart';
import 'storage_manager.dart';
import 'retention_manager.dart';
import 'integrity_verifier.dart';
import 'archive_manager.dart';
import 'path_generator.dart';
import 'duplicate_detector.dart';

// Helper extension to mimic firstWhereOrNull
extension _ListExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class CopyEngine {
  final Ref ref;
  final BackupFileRepository _fileRepository;
  final FileVersionRepository _versionRepository;
  final LoggingService _logger;
  final StorageManager _storageManager;
  final RetentionManager _retentionManager;
  final IntegrityVerifier _integrityVerifier;
  final ArchiveManager _archiveManager;

  final List<CopyWorker> _workers;
  bool _isProcessing = false;

  CopyEngine({
    required this.ref,
    required BackupFileRepository fileRepository,
    required FileVersionRepository versionRepository,
    required LoggingService logger,
    required StorageManager storageManager,
    required RetentionManager retentionManager,
    required IntegrityVerifier integrityVerifier,
    required ArchiveManager archiveManager,
    int workerCount = 3,
  })  : _fileRepository = fileRepository,
        _versionRepository = versionRepository,
        _logger = logger,
        _storageManager = storageManager,
        _retentionManager = retentionManager,
        _integrityVerifier = integrityVerifier,
        _archiveManager = archiveManager,
        _workers = List.generate(workerCount, (i) => CopyWorker(workerId: 'Worker_$i'));

  void addJob(CopyJob job) {
    ref.read(copyQueueProvider.notifier).addJob(job);
    _triggerProcessing();
  }

  void addJobs(List<CopyJob> jobs) {
    ref.read(copyQueueProvider.notifier).addJobs(jobs);
    _triggerProcessing();
  }

  void _triggerProcessing() {
    if (_isProcessing) return;
    _isProcessing = true;
    _startWorkerPool();
  }

  Future<void> _startWorkerPool() async {
    final List<Future<void>> pool = [];
    for (final worker in _workers) {
      pool.add(_runWorkerLoop(worker));
    }
    await Future.wait(pool);
    _isProcessing = false;
  }

  Future<void> _runWorkerLoop(CopyWorker worker) async {
    final queueNotifier = ref.read(copyQueueProvider.notifier);

    while (true) {
      if (queueNotifier.isQueuePaused) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      CopyJob? job;
      final jobs = ref.read(copyQueueProvider);
      job = jobs.firstWhereOrNull((j) => j.status == CopyStatus.pending);
      if (job != null) {
        queueNotifier.updateJobResult(job.id, CopyStatus.copying, workerId: worker.workerId);
      }

      if (job == null) {
        break; // No more pending jobs
      }

      await _executeJob(worker, job);
    }
  }

  Future<void> _executeJob(CopyWorker worker, CopyJob job) async {
    final queueNotifier = ref.read(copyQueueProvider.notifier);
    final stopwatch = Stopwatch()..start();
    final file = File(job.sourcePath);

    try {
      await _logger.info('CopyEngine', 'Calculating pre-copy hash for: ${job.sourcePath}');
      final sourceHash = await _integrityVerifier.calculateSha256(file);

      // Check duplicates
      final duplicatePath = await _archiveManager.duplicateDetector.findDuplicateBackupPath(sourceHash, job.fileSize);
      String finalDestPath = job.destinationPath;

      if (duplicatePath != null) {
        finalDestPath = duplicatePath;
        await _logger.info('CopyEngine', 'Duplicate found for ${job.sourcePath}. Referencing existing backup: $duplicatePath');
        queueNotifier.updateJobProgress(job.id, 1.0, 0.0);
      } else {
        // Enforce storage space checks
        final storage = await _storageManager.getStorageInfo(finalDestPath);
        if (storage.isLowSpace) {
          await _logger.warning('CopyEngine', 'Storage space low on ${storage.driveLetter} (${storage.freeSpacePercentage.toStringAsFixed(1)}% free)');
        }
        if (storage.availableBytes < job.fileSize) {
          throw Exception('Insufficient space on ${storage.driveLetter}. Needed: ${job.fileSize}, Free: ${storage.availableBytes}');
        }

        await _logger.info('CopyEngine', 'Copying starting: ${job.sourcePath} -> $finalDestPath');
        await worker.copy(
          sourcePath: job.sourcePath,
          destinationPath: finalDestPath,
          onUpdate: (progress, speed) {
            queueNotifier.updateJobProgress(job.id, progress, speed);
          },
          isCancelled: () => queueNotifier.isCancelled(job.id),
          isPaused: () => queueNotifier.isPaused(job.id),
        );

        await _logger.info('CopyEngine', 'Copy finished. Verifying post-copy hash for: $finalDestPath');
        final destFile = File(finalDestPath);
        final verified = await _integrityVerifier.verifyIntegrity(file, destFile);
        if (!verified) {
          throw Exception('Integrity check failed: source and destination SHA-256 mismatch');
        }
      }

      final duration = stopwatch.elapsed;
      final now = DateTime.now();
      final stat = await file.stat();

      // Write/update SQLite
      final dbFiles = await _fileRepository.getFilesByFolderId(job.folderId);
      final dbFile = dbFiles.firstWhereOrNull((f) => f.originalPath == job.sourcePath);

      if (dbFile == null) {
        final fileId = await _fileRepository.addFile(
          BackupFilesCompanion.insert(
            folderId: job.folderId,
            fileName: p.basename(job.sourcePath),
            extension: p.extension(job.sourcePath),
            originalPath: job.sourcePath,
            backupPath: finalDestPath,
            fileSize: job.fileSize,
            sha256: sourceHash,
            modifiedAt: stat.modified,
            backupStatus: 'success',
          ),
        );

        await _versionRepository.addVersion(
          FileVersionsCompanion.insert(
            fileId: fileId,
            versionNumber: 1,
            backupPath: finalDestPath,
          ),
        );
      } else {
        final versions = await _versionRepository.getVersionsByFileId(dbFile.id);
        final nextVersion = versions.length + 1;

        await _fileRepository.updateFile(
          dbFile.copyWith(
            backupPath: finalDestPath,
            fileSize: job.fileSize,
            sha256: sourceHash,
            modifiedAt: stat.modified,
            backupStatus: 'success',
          ),
        );

        await _versionRepository.addVersion(
          FileVersionsCompanion.insert(
            fileId: dbFile.id,
            versionNumber: nextVersion,
            backupPath: finalDestPath,
          ),
        );
      }

      await _logger.info('CopyEngine', 'Job completed: ${job.sourcePath} in ${duration.inMilliseconds}ms');

      queueNotifier.updateJobResult(
        job.id,
        CopyStatus.completed,
        sha256: sourceHash,
        duration: duration,
        backupTime: now,
        workerId: worker.workerId,
        destinationPath: finalDestPath,
      );

    } catch (e) {
      final errorMsg = e.toString();
      await _logger.error('CopyEngine', 'Copy failed for ${job.sourcePath}: $errorMsg');

      if (job.retryCount < 3) {
        final nextRetry = job.retryCount + 1;
        queueNotifier.updateJobResult(
          job.id,
          CopyStatus.pending,
          error: 'Error: $errorMsg (Attempt $nextRetry failed)',
          retryCount: nextRetry,
        );
        // Trigger queue processing again for retrying
        _triggerProcessing();
      } else {
        queueNotifier.updateJobResult(
          job.id,
          CopyStatus.failed,
          error: errorMsg,
          workerId: worker.workerId,
        );
      }
    }
  }

  StorageManager get storageManager => _storageManager;
  RetentionManager get retentionManager => _retentionManager;
}

final copyEngineProvider = Provider<CopyEngine>((ref) {
  final fileRepo = ref.watch(backupFileRepositoryProvider);
  final versionRepo = ref.watch(fileVersionRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  
  final storageManager = StorageManager();
  final retentionManager = RetentionManager(logger: logger);
  final integrityVerifier = IntegrityVerifier();
  final pathGenerator = PathGenerator();
  
  final duplicateDetector = DuplicateDetector(fileRepository: fileRepo);
  final archiveManager = ArchiveManager(
    fileRepository: fileRepo,
    versionRepository: versionRepo,
    pathGenerator: pathGenerator,
    duplicateDetector: duplicateDetector,
  );

  return CopyEngine(
    ref: ref,
    fileRepository: fileRepo,
    versionRepository: versionRepo,
    logger: logger,
    storageManager: storageManager,
    retentionManager: retentionManager,
    integrityVerifier: integrityVerifier,
    archiveManager: archiveManager,
  );
});
