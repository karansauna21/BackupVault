// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../repositories/backup_file_repository.dart';
import '../repositories/file_version_repository.dart';
import '../repositories/repository_providers.dart';
import '../services/logging_service.dart';
import 'restore_job.dart';
import 'restore_queue.dart';
import 'restore_validator.dart';
import 'restore_history.dart';
import 'conflict_resolver.dart';
import 'path_resolver.dart';
import 'integrity_verifier.dart';
import '../../features/security/security_provider.dart';

// Helper extension to mimic firstWhereOrNull
extension _ListExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class RestoreEngine {
  final Ref ref;
  final BackupFileRepository _fileRepository;
  final FileVersionRepository _versionRepository;
  final LoggingService _logger;
  final RestoreValidator _restoreValidator;
  final RestoreHistory _restoreHistory;
  final ConflictResolver _conflictResolver;
  final PathResolver _pathResolver;
  final IntegrityVerifier _integrityVerifier;
  final Uuid _uuid = const Uuid();

  bool _isProcessing = false;

  RestoreEngine({
    required this.ref,
    required BackupFileRepository fileRepository,
    required FileVersionRepository versionRepository,
    required LoggingService logger,
    required RestoreValidator restoreValidator,
    required RestoreHistory restoreHistory,
    required ConflictResolver conflictResolver,
    required PathResolver pathResolver,
    required IntegrityVerifier integrityVerifier,
  })  : _fileRepository = fileRepository,
        _versionRepository = versionRepository,
        _logger = logger,
        _restoreValidator = restoreValidator,
        _restoreHistory = restoreHistory,
        _conflictResolver = conflictResolver,
        _pathResolver = pathResolver,
        _integrityVerifier = integrityVerifier;

  Future<void> restoreFile(
    BackupFile file, {
    required String destinationOption, // 'original', 'custom', 'desktop', 'downloads'
    String? customFolderPath,
    int? versionNumber,
  }) async {
    String sourcePath = file.backupPath;
    int versionNum = 1;

    if (versionNumber != null && versionNumber > 1) {
      final versions = await _versionRepository.getVersionsByFileId(file.id);
      final targetVersion = versions.firstWhereOrNull((v) => v.versionNumber == versionNumber);
      if (targetVersion != null) {
        sourcePath = targetVersion.backupPath;
        versionNum = versionNumber;
      }
    } else {
      // Find latest version number
      final versions = await _versionRepository.getVersionsByFileId(file.id);
      if (versions.isNotEmpty) {
        final maxVersion = versions.fold<int>(1, (max, v) => v.versionNumber > max ? v.versionNumber : max);
        versionNum = maxVersion;
      }
    }

    final targetPath = _pathResolver.resolveTargetRestorePath(
      originalPath: file.originalPath,
      destinationOption: destinationOption,
      customFolderPath: customFolderPath,
    );

    final job = RestoreJob(
      id: _uuid.v4(),
      fileId: file.id,
      sourceBackupPath: sourcePath,
      targetRestorePath: targetPath,
      fileSize: file.fileSize,
      versionNumber: versionNum,
      sha256: file.sha256,
    );

    ref.read(restoreQueueProvider.notifier).addJob(job);
    _triggerProcessing();
  }

  Future<void> restoreMultipleFiles(
    List<BackupFile> files, {
    required String destinationOption,
    String? customFolderPath,
  }) async {
    for (final file in files) {
      await restoreFile(
        file,
        destinationOption: destinationOption,
        customFolderPath: customFolderPath,
      );
    }
  }

  Future<void> restoreFolder(
    int folderId, {
    required String destinationOption,
    String? customFolderPath,
  }) async {
    final dbFiles = await _fileRepository.getFilesByFolderId(folderId);
    // Ignore files marked deleted on source
    final activeFiles = dbFiles.where((f) => f.backupStatus == 'success').toList();

    await restoreMultipleFiles(
      activeFiles,
      destinationOption: destinationOption,
      customFolderPath: customFolderPath,
    );
  }

  Future<void> restoreBackup(
    int folderId, {
    required String destinationOption,
    String? customFolderPath,
  }) async {
    await restoreFolder(
      folderId,
      destinationOption: destinationOption,
      customFolderPath: customFolderPath,
    );
  }

  void _triggerProcessing() {
    if (_isProcessing) return;
    _isProcessing = true;
    _startProcessorLoop();
  }

  Future<void> _startProcessorLoop() async {
    final queueNotifier = ref.read(restoreQueueProvider.notifier);

    while (true) {
      if (queueNotifier.isQueuePaused) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      RestoreJob? job;
      final jobs = ref.read(restoreQueueProvider);
      job = jobs.firstWhereOrNull((j) => j.status == RestoreStatus.pending);
      if (job != null) {
        queueNotifier.updateJobResult(job.id, RestoreStatus.restoring);
      }

      if (job == null) {
        break; // No pending restore jobs
      }

      await _executeJob(job);
    }
    _isProcessing = false;
  }

  Future<void> _executeJob(RestoreJob job) async {
    final queueNotifier = ref.read(restoreQueueProvider.notifier);
    final stopwatch = Stopwatch()..start();

    try {
      await _logger.info('RestoreEngine', 'Calculating hash for source backup file: ${job.sourceBackupPath}');
      final isSourceValid = await _integrityVerifier.verifyFileIntegrity(File(job.sourceBackupPath), job.sha256);
      if (!isSourceValid) {
        throw Exception('Backup archive file is corrupted (SHA-256 mismatch).');
      }

      final resolvedPath = _conflictResolver.resolveConflict(job.targetRestorePath);

      final isDestValid = await _restoreValidator.validateDestination(resolvedPath);
      if (!isDestValid) {
        throw Exception('Destination directory is not writable: $resolvedPath');
      }

      // Stream copying with support for large files and pause/resume
      final sourceFile = File(job.sourceBackupPath);
      final destFile = File(resolvedPath);
      final totalSize = job.fileSize;

      final encManager = ref.read(encryptionManagerProvider);
      if (encManager.isEncryptionActive) {
        final encryptedBytes = await sourceFile.readAsBytes();
        final decryptedBytes = encManager.decryptBytes(encryptedBytes);
        if (!await destFile.parent.exists()) {
          await destFile.parent.create(recursive: true);
        }
        await destFile.writeAsBytes(decryptedBytes);
        queueNotifier.updateJobProgress(job.id, 1.0);
      } else {
        int bytesRestored = 0;
        IOSink? destSink;
        Stream<List<int>>? sourceStream;

        if (await destFile.exists()) {
          final destSize = await destFile.length();
          if (destSize > 0 && destSize < totalSize) {
            bytesRestored = destSize;
            destSink = destFile.openWrite(mode: FileMode.append);
            sourceStream = sourceFile.openRead(destSize);
          }
        }

        if (destSink == null || sourceStream == null) {
          destSink = destFile.openWrite(mode: FileMode.write);
          sourceStream = sourceFile.openRead();
        }

        try {
          await for (final chunk in sourceStream) {
            if (queueNotifier.isCancelled(job.id)) {
              throw Exception('Restore job cancelled');
            }
            while (queueNotifier.isPaused(job.id)) {
              await Future.delayed(const Duration(milliseconds: 100));
            }

            destSink.add(chunk);
            bytesRestored += chunk.length;

            queueNotifier.updateJobProgress(job.id, bytesRestored / totalSize);
          }
          await destSink.flush();
        } finally {
          await destSink.close();
        }
      }

      await _logger.info('RestoreEngine', 'Verifying integrity of restored file: $resolvedPath');
      final isRestoredValid = await _integrityVerifier.verifyFileIntegrity(destFile, job.sha256);
      if (!isRestoredValid) {
        throw Exception('Restored file integrity check failed: SHA-256 mismatch');
      }

      final duration = stopwatch.elapsed;
      final now = DateTime.now();

      await _restoreHistory.addRecord(
        RestoreRecord(
          date: now,
          location: resolvedPath,
          duration: duration,
          status: 'success',
          version: job.versionNumber,
          userAction: 'Restore File',
        ),
      );

      queueNotifier.updateJobResult(
        job.id,
        RestoreStatus.completed,
        duration: duration,
        restoreTime: now,
        targetRestorePath: resolvedPath,
      );

      await _logger.info('RestoreEngine', 'Restore completed successfully: ${job.sourceBackupPath} -> $resolvedPath');

    } catch (e) {
      final errorMsg = e.toString();
      await _logger.error('RestoreEngine', 'Restore failed for ${job.sourceBackupPath}: $errorMsg');

      if (job.retryCount < 3) {
        final nextRetry = job.retryCount + 1;
        queueNotifier.updateJobResult(
          job.id,
          RestoreStatus.pending,
          error: 'Error: $errorMsg (Attempt $nextRetry failed)',
          retryCount: nextRetry,
        );
        _triggerProcessing();
      } else {
        final now = DateTime.now();
        await _restoreHistory.addRecord(
          RestoreRecord(
            date: now,
            location: job.targetRestorePath,
            duration: stopwatch.elapsed,
            status: 'failed',
            version: job.versionNumber,
            userAction: 'Restore File',
            errors: errorMsg,
          ),
        );

        queueNotifier.updateJobResult(
          job.id,
          RestoreStatus.failed,
          error: errorMsg,
        );
      }
    }
  }
}

final restoreEngineProvider = Provider<RestoreEngine>((ref) {
  final fileRepo = ref.watch(backupFileRepositoryProvider);
  final versionRepo = ref.watch(fileVersionRepositoryProvider);
  final logger = ref.watch(loggingServiceProvider);
  final restoreHistory = ref.watch(restoreHistoryProvider);

  final restoreValidator = RestoreValidator();
  final conflictResolver = ConflictResolver();
  final pathResolver = PathResolver();
  final integrityVerifier = IntegrityVerifier(ref);

  return RestoreEngine(
    ref: ref,
    fileRepository: fileRepo,
    versionRepository: versionRepo,
    logger: logger,
    restoreValidator: restoreValidator,
    restoreHistory: restoreHistory,
    conflictResolver: conflictResolver,
    pathResolver: pathResolver,
    integrityVerifier: integrityVerifier,
  );
});
