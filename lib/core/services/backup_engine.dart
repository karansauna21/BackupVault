// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../file_watcher/file_event.dart';
import '../database/app_database.dart';
import '../repositories/backup_file_repository.dart';
import '../repositories/backup_folder_repository.dart';
import '../repositories/repository_providers.dart';
import '../copy_engine/copy_engine.dart';
import '../copy_engine/copy_job.dart';
import 'folder_watcher.dart';
import 'logging_service.dart';
import 'version_manager.dart';

// Helper extension to mimic firstWhereOrNull since we do not import collection package
extension _ListExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class BackupEngine {
  final BackupFolderRepository _folderRepository;
  final BackupFileRepository _fileRepository;
  final FolderWatcher _folderWatcher;
  final CopyEngine _copyEngine;
  final VersionManager _versionManager;
  final LoggingService _logger;
  final Uuid _uuid = const Uuid();

  BackupEngine({
    required BackupFolderRepository folderRepository,
    required BackupFileRepository fileRepository,
    required FolderWatcher folderWatcher,
    required CopyEngine copyEngine,
    required VersionManager versionManager,
    required LoggingService logger,
  }) : _folderRepository = folderRepository,
       _fileRepository = fileRepository,
       _folderWatcher = folderWatcher,
       _copyEngine = copyEngine,
       _versionManager = versionManager,
       _logger = logger;

  Future<void> start() async {
    await _logger.info('BackupEngine', 'Initializing backup engine...');

    try {
      final folders = await _folderRepository.getAllFolders();
      for (final folder in folders) {
        if (folder.enabled) {
          _folderWatcher.startWatching(
            folder,
            (event, f) => _handleFileEvent(event, f),
          );
          // Perform automatic scanning on start to align disk and database
          backupFolder(folder);
        }
      }
    } catch (e, stack) {
      await _logger.error(
        'BackupEngine',
        'Failed during initialization: $e',
        stack.toString(),
      );
    }
  }

  void enableFolderWatching(BackupFolder folder) {
    _folderWatcher.startWatching(
      folder,
      (event, f) => _handleFileEvent(event, f),
    );
  }

  void disableFolderWatching(int folderId) {
    _folderWatcher.stopWatching(folderId);
  }

  Future<void> stop() async {
    await _logger.info('BackupEngine', 'Stopping backup engine...');
    try {
      final folders = await _folderRepository.getAllFolders();
      for (final folder in folders) {
        _folderWatcher.stopWatching(folder.id);
      }
    } catch (e, stack) {
      await _logger.error(
        'BackupEngine',
        'Failed during shutdown: $e',
        stack.toString(),
      );
    }
  }

  Future<List<CopyJob>> backupFolder(BackupFolder folder) async {
    final sourceDir = Directory(folder.sourcePath);
    if (!await sourceDir.exists()) {
      await _logger.error(
        'BackupEngine',
        'Source directory does not exist: ${folder.sourcePath}',
      );
      return [];
    }

    await _logger.info(
      'BackupEngine',
      'Scanning backup folder: ${folder.name}',
    );

    final List<File> files = [];
    try {
      await for (final entity in sourceDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (e, stack) {
      await _logger.error(
        'BackupEngine',
        'Error scanning directory ${folder.sourcePath}: $e',
        stack.toString(),
      );
      return [];
    }

    final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
    final dbFilesMap = {for (final f in dbFiles) f.originalPath: f};
    final List<CopyJob> jobsToQueue = [];

    for (final file in files) {
      final relativePath = p.relative(file.path, from: folder.sourcePath);
      final destPath = p.join(folder.destinationPath, relativePath);

      final dbFile = dbFilesMap[file.path];
      final stat = await file.stat();
      if (dbFile == null) {
        jobsToQueue.add(
          CopyJob(
            id: _generateJobId(),
            folderId: folder.id,
            folderName: folder.name,
            sourcePath: file.path,
            destinationPath: destPath,
            fileSize: stat.size,
          ),
        );
      } else {
        if (stat.size != dbFile.fileSize ||
            stat.modified.millisecondsSinceEpoch !=
                dbFile.modifiedAt.millisecondsSinceEpoch) {
          final changed = await _versionManager.hasFileChanged(
            file,
            dbFile.sha256,
          );
          if (changed) {
            final nextVersion = await _versionManager.getNextVersionNumber(
              dbFile.id,
            );
            final versionedDestPath = _versionManager.calculateVersionedPath(
              destPath,
              nextVersion,
            );

            jobsToQueue.add(
              CopyJob(
                id: _generateJobId(),
                folderId: folder.id,
                folderName: folder.name,
                sourcePath: file.path,
                destinationPath: versionedDestPath,
                fileSize: stat.size,
              ),
            );
          }
        }
      }
    }

    // Detect files deleted on source and mark in database (preserving the backup itself)
    final currentFilePaths = files.map((f) => f.path).toSet();
    for (final dbFile in dbFiles) {
      if (!currentFilePaths.contains(dbFile.originalPath) &&
          dbFile.backupStatus != 'deleted_on_source') {
        await _fileRepository.updateFile(
          dbFile.copyWith(backupStatus: 'deleted_on_source'),
        );
        await _logger.warning(
          'BackupEngine',
          'File deleted on source, keeping backup: ${dbFile.originalPath}',
        );
      }
    }

    if (jobsToQueue.isNotEmpty) {
      await _logger.info(
        'BackupEngine',
        'Queuing ${jobsToQueue.length} backup tasks for folder: ${folder.name}',
      );
      _copyEngine.addJobs(jobsToQueue);
    } else {
      await _logger.info(
        'BackupEngine',
        'No changes found for folder: ${folder.name}',
      );
    }

    return jobsToQueue;
  }

  Future<void> _handleFileEvent(
    FileSystemEvent event,
    BackupFolder folder,
  ) async {
    final path = event.path;
    final relativePath = p.relative(path, from: folder.sourcePath);
    final destPath = p.join(folder.destinationPath, relativePath);

    if (event is FileSystemCreateEvent) {
      if (FileSystemEntity.isFileSync(path)) {
        await _logger.info(
          'BackupEngine',
          'Real-time: file created: $relativePath',
        );
        final file = File(path);
        final size = await file.exists() ? await file.length() : 0;
        _copyEngine.addJob(
          CopyJob(
            id: _generateJobId(),
            folderId: folder.id,
            folderName: folder.name,
            sourcePath: path,
            destinationPath: destPath,
            fileSize: size,
          ),
        );
      }
    } else if (event is FileSystemModifyEvent) {
      if (FileSystemEntity.isFileSync(path)) {
        final file = File(path);
        final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
        final dbFile = dbFiles.firstWhereOrNull((f) => f.originalPath == path);

        if (dbFile != null) {
          final stat = await file.stat();
          if (stat.size != dbFile.fileSize) {
            final changed = await _versionManager.hasFileChanged(
              file,
              dbFile.sha256,
            );
            if (changed) {
              final nextVersion = await _versionManager.getNextVersionNumber(
                dbFile.id,
              );
              final versionedDestPath = _versionManager.calculateVersionedPath(
                destPath,
                nextVersion,
              );

              await _logger.info(
                'BackupEngine',
                'Real-time: file modified: $relativePath (New Version: $nextVersion)',
              );
              _copyEngine.addJob(
                CopyJob(
                  id: _generateJobId(),
                  folderId: folder.id,
                  folderName: folder.name,
                  sourcePath: path,
                  destinationPath: versionedDestPath,
                  fileSize: stat.size,
                ),
              );
            }
          }
        }
      }
    } else if (event is FileSystemDeleteEvent) {
      final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
      final dbFile = dbFiles.firstWhereOrNull((f) => f.originalPath == path);
      if (dbFile != null && dbFile.backupStatus != 'deleted_on_source') {
        await _fileRepository.updateFile(
          dbFile.copyWith(backupStatus: 'deleted_on_source'),
        );
        await _logger.warning(
          'BackupEngine',
          'Real-time: file deleted on source, preserving backup: $path',
        );
      }
    } else if (event is FileSystemMoveEvent) {
      final destination = event.destination;
      if (destination != null) {
        final newRelativePath = p.relative(
          destination,
          from: folder.sourcePath,
        );
        final newDestPath = p.join(folder.destinationPath, newRelativePath);

        final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
        final dbFile = dbFiles.firstWhereOrNull((f) => f.originalPath == path);

        if (dbFile != null) {
          await _fileRepository.updateFile(
            dbFile.copyWith(
              originalPath: destination,
              fileName: p.basename(destination),
              extension: p.extension(destination),
            ),
          );
          await _logger.info(
            'BackupEngine',
            'Real-time: file renamed from $relativePath to $newRelativePath',
          );
        } else {
          final file = File(destination);
          final size = await file.exists() ? await file.length() : 0;
          _copyEngine.addJob(
            CopyJob(
              id: _generateJobId(),
              folderId: folder.id,
              folderName: folder.name,
              sourcePath: destination,
              destinationPath: newDestPath,
              fileSize: size,
            ),
          );
        }
      }
    }
  }

  Future<void> handleWatcherFileEvent(FileEvent event) async {
    final folder = await _folderRepository.getFolderById(event.folderId);
    if (folder == null || !folder.enabled) return;

    final path = event.path;
    final relativePath = p.relative(path, from: folder.sourcePath);
    final destPath = p.join(folder.destinationPath, relativePath);

    switch (event.type) {
      case FileEventType.newFile:
      case FileEventType.copiedFile:
        if (FileSystemEntity.isFileSync(path)) {
          await _logger.info(
            'BackupEngine',
            'Automatic: New file detected: $relativePath',
          );
          final file = File(path);
          final size = await file.exists() ? await file.length() : 0;
          _copyEngine.addJob(
            CopyJob(
              id: _generateJobId(),
              folderId: folder.id,
              folderName: folder.name,
              sourcePath: path,
              destinationPath: destPath,
              fileSize: size,
            ),
          );
        }
        break;

      case FileEventType.modifiedFile:
        if (FileSystemEntity.isFileSync(path)) {
          final file = File(path);
          final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
          final dbFile = dbFiles.firstWhereOrNull(
            (f) => f.originalPath == path,
          );

          if (dbFile != null) {
            final stat = await file.stat();
            if (stat.size != dbFile.fileSize) {
              final changed = await _versionManager.hasFileChanged(
                file,
                dbFile.sha256,
              );
              if (changed) {
                final nextVersion = await _versionManager.getNextVersionNumber(
                  dbFile.id,
                );
                final versionedDestPath = _versionManager
                    .calculateVersionedPath(destPath, nextVersion);

                await _logger.info(
                  'BackupEngine',
                  'Automatic: File modified: $relativePath (New Version: $nextVersion)',
                );
                _copyEngine.addJob(
                  CopyJob(
                    id: _generateJobId(),
                    folderId: folder.id,
                    folderName: folder.name,
                    sourcePath: path,
                    destinationPath: versionedDestPath,
                    fileSize: stat.size,
                  ),
                );
              }
            }
          } else {
            final size = await file.exists() ? await file.length() : 0;
            _copyEngine.addJob(
              CopyJob(
                id: _generateJobId(),
                folderId: folder.id,
                folderName: folder.name,
                sourcePath: path,
                destinationPath: destPath,
                fileSize: size,
              ),
            );
          }
        }
        break;

      case FileEventType.deletedFile:
        final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
        final dbFile = dbFiles.firstWhereOrNull((f) => f.originalPath == path);
        if (dbFile != null && dbFile.backupStatus != 'deleted_on_source') {
          await _fileRepository.updateFile(
            dbFile.copyWith(backupStatus: 'deleted_on_source'),
          );
          await _logger.warning(
            'BackupEngine',
            'Automatic: File deleted on source, preserving backup: $path',
          );
        }
        break;

      case FileEventType.movedFile:
      case FileEventType.renamedFile:
        final destination = event.destinationPath;
        if (destination != null) {
          final newRelativePath = p.relative(
            destination,
            from: folder.sourcePath,
          );
          final newDestPath = p.join(folder.destinationPath, newRelativePath);

          final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
          final dbFile = dbFiles.firstWhereOrNull(
            (f) => f.originalPath == path,
          );

          if (dbFile != null) {
            await _fileRepository.updateFile(
              dbFile.copyWith(
                originalPath: destination,
                fileName: p.basename(destination),
                extension: p.extension(destination),
              ),
            );
            await _logger.info(
              'BackupEngine',
              'Automatic: File renamed/moved from $relativePath to $newRelativePath',
            );
          } else {
            final file = File(destination);
            final size = await file.exists() ? await file.length() : 0;
            _copyEngine.addJob(
              CopyJob(
                id: _generateJobId(),
                folderId: folder.id,
                folderName: folder.name,
                sourcePath: destination,
                destinationPath: newDestPath,
                fileSize: size,
              ),
            );
          }
        }
        break;

      case FileEventType.folderCreated:
        await _logger.info(
          'BackupEngine',
          'Automatic: Folder created: $relativePath',
        );
        final newDir = Directory(destPath);
        if (!await newDir.exists()) {
          await newDir.create(recursive: true);
        }
        break;

      case FileEventType.folderDeleted:
        await _logger.warning(
          'BackupEngine',
          'Automatic: Folder deleted on source (preserving backup): $relativePath',
        );
        break;

      case FileEventType.folderMoved:
      case FileEventType.folderRenamed:
        final destination = event.destinationPath;
        if (destination != null) {
          final newRelativePath = p.relative(
            destination,
            from: folder.sourcePath,
          );
          await _logger.info(
            'BackupEngine',
            'Automatic: Folder renamed/moved from $relativePath to $newRelativePath',
          );
        }
        break;
    }
  }

  String _generateJobId() => _uuid.v4();
}

final backupEngineProvider = Provider<BackupEngine>((ref) {
  final folderRepo = ref.watch(backupFolderRepositoryProvider);
  final fileRepo = ref.watch(backupFileRepositoryProvider);
  final folderWatcher = ref.watch(folderWatcherProvider);
  final copyEngine = ref.watch(copyEngineProvider);
  final versionManager = ref.watch(versionManagerProvider);
  final logger = ref.watch(loggingServiceProvider);

  return BackupEngine(
    folderRepository: folderRepo,
    fileRepository: fileRepo,
    folderWatcher: folderWatcher,
    copyEngine: copyEngine,
    versionManager: versionManager,
    logger: logger,
  );
});
