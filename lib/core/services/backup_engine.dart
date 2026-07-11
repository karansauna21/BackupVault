// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../file_watcher/file_event.dart';
import '../database/app_database.dart';
import '../repositories/backup_file_repository.dart';
import '../repositories/backup_folder_repository.dart';
import '../repositories/file_version_repository.dart';
import '../repositories/repository_providers.dart';
import '../copy_engine/copy_engine.dart';
import '../copy_engine/copy_job.dart';
import '../copy_engine/integrity_verifier.dart';
import 'folder_watcher.dart';
import 'logging_service.dart';
import 'version_manager.dart';

import '../utils/android_storage.dart';

// Helper extension to mimic firstWhereOrNull since we do not import collection package
extension _ListExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ScanResultStats {
  final int scannedCount;
  final int skippedCount;
  final int totalBytesToCopy;
  final int imagesCount;
  final int videosCount;
  final int documentsCount;
  final int archivesCount;
  final int audioCount;
  final int apkCount;
  final int unknownCount;

  ScanResultStats({
    required this.scannedCount,
    required this.skippedCount,
    required this.totalBytesToCopy,
    this.imagesCount = 0,
    this.videosCount = 0,
    this.documentsCount = 0,
    this.archivesCount = 0,
    this.audioCount = 0,
    this.apkCount = 0,
    this.unknownCount = 0,
  });
}

class BackupEngine {
  final BackupFolderRepository _folderRepository;
  final BackupFileRepository _fileRepository;
  final FileVersionRepository _versionRepository;
  final FolderWatcher _folderWatcher;
  final CopyEngine _copyEngine;
  final VersionManager _versionManager;
  final LoggingService _logger;
  final IntegrityVerifier _integrityVerifier = IntegrityVerifier();
  final Uuid _uuid = const Uuid();
  final Map<int, ScanResultStats> _scanStats = {};
  final StreamController<FileEvent> _watcherEventController = StreamController<FileEvent>.broadcast();

  Stream<FileEvent> get onWatcherEvent => _watcherEventController.stream;

  BackupEngine({
    required BackupFolderRepository folderRepository,
    required BackupFileRepository fileRepository,
    required FileVersionRepository versionRepository,
    required FolderWatcher folderWatcher,
    required CopyEngine copyEngine,
    required VersionManager versionManager,
    required LoggingService logger,
  }) : _folderRepository = folderRepository,
       _fileRepository = fileRepository,
       _versionRepository = versionRepository,
       _folderWatcher = folderWatcher,
       _copyEngine = copyEngine,
       _versionManager = versionManager,
       _logger = logger;

  ScanResultStats? getScanStats(int folderId) => _scanStats[folderId];

  Future<void> start() async {
    await _logger.info('BackupEngine', 'Initializing backup engine...');

    try {
      final folders = await _folderRepository.getAllFolders();
      for (final folder in folders) {
        if (folder.enabled) {
          var folderToUse = folder;
          if (Platform.isAndroid) {
            String resolvedSource = folder.sourcePath;
            String resolvedDest = folder.destinationPath;

            if (folder.sourcePath.startsWith('content://')) {
              final resolved = await AndroidStorage.resolvePath(folder.sourcePath);
              if (resolved != null && resolved.isNotEmpty) {
                resolvedSource = resolved;
              }
            }
            if (folder.destinationPath.startsWith('content://')) {
              final resolved = await AndroidStorage.resolvePath(folder.destinationPath);
              if (resolved != null && resolved.isNotEmpty) {
                resolvedDest = resolved;
              }
            }
            folderToUse = folder.copyWith(
              sourcePath: resolvedSource,
              destinationPath: resolvedDest,
            );
          }

          _folderWatcher.startWatching(
            folderToUse,
            (event, f) => _handleFileEvent(event, f),
          );
          // Perform automatic scanning on start to align disk and database
          backupFolder(folderToUse);
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

  bool _shouldIgnore(String filePath, String rootPath) {
    final fileName = p.basename(filePath);
    final nameLower = fileName.toLowerCase();
    final relativePath = p.relative(filePath, from: rootPath);
    final relativeLower = relativePath.toLowerCase();

    // 1. Hidden files/directories (starts with . or contains a hidden folder segment)
    final segments = p.split(relativePath);
    for (final segment in segments) {
      if (segment.startsWith('.') || segment.startsWith(r'~$')) {
        return true;
      }
    }

    // 2. Temporary files: ends with .tmp, .temp, .crdownload, starts with ~$ or contains tmp/temp
    if (nameLower.endsWith('.tmp') ||
        nameLower.endsWith('.temp') ||
        nameLower.endsWith('.crdownload') ||
        nameLower.startsWith(r'~$') ||
        nameLower.contains('tmp') ||
        nameLower.contains('temp')) {
      return true;
    }

    // 3. System files: thumbs.db, desktop.ini, .ds_store, or System Volume Information, $RECYCLE.BIN
    if (nameLower == 'thumbs.db' ||
        nameLower == 'desktop.ini' ||
        nameLower == '.ds_store' ||
        relativeLower.contains('system volume information') ||
        relativeLower.contains(r'$recycle.bin')) {
      return true;
    }

    return false;
  }

  String _detectCategory(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '').trim();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
      case 'bmp':
      case 'tiff':
        return 'Images';
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case '3gp':
      case 'wmv':
      case 'flv':
      case 'webm':
        return 'Videos';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
      case 'rtf':
      case 'odt':
      case 'ods':
      case 'odp':
        return 'Documents';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
      case 'bz2':
      case 'xz':
        return 'Archives';
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
      case 'm4a':
      case 'wma':
        return 'Audio';
      case 'apk':
        return 'APK';
      default:
        return 'Unknown';
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
      'Backup started for folder: ${folder.name}',
    );

    int scannedCount = 0;
    int skippedCount = 0;
    int totalBytesToCopy = 0;

    int imagesCount = 0;
    int videosCount = 0;
    int documentsCount = 0;
    int archivesCount = 0;
    int audioCount = 0;
    int apkCount = 0;
    int unknownCount = 0;

    final List<File> filesToCopy = [];
    final List<String> destPaths = [];
    final List<int> initialCopiedBytes = [];
    final Set<String> scannedPaths = {};

    final dbFiles = await _fileRepository.getFilesByFolderId(folder.id);
    final dbFilesMap = {for (final f in dbFiles) f.originalPath: f};

    try {
      await for (final entity in sourceDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          scannedCount++;

          if (_shouldIgnore(entity.path, folder.sourcePath)) {
            skippedCount++;
            continue;
          }

          scannedPaths.add(entity.path);

          final category = _detectCategory(entity.path);
          switch (category) {
            case 'Images':
              imagesCount++;
              break;
            case 'Videos':
              videosCount++;
              break;
            case 'Documents':
              documentsCount++;
              break;
            case 'Archives':
              archivesCount++;
              break;
            case 'Audio':
              audioCount++;
              break;
            case 'APK':
              apkCount++;
              break;
            default:
              unknownCount++;
              break;
          }

          final relativePath = p.relative(entity.path, from: folder.sourcePath);
          final destPath = p.join(folder.destinationPath, relativePath);

          final dbFile = dbFilesMap[entity.path];
          final stat = await entity.stat();

          bool needsCopy = true;
          int offset = 0;

          if (dbFile != null && dbFile.backupStatus == 'success') {
            final destFile = File(dbFile.backupPath);
            if (await destFile.exists() && (await destFile.length()) == stat.size) {
              if (stat.size == dbFile.fileSize &&
                  stat.modified.millisecondsSinceEpoch == dbFile.modifiedAt.millisecondsSinceEpoch) {
                needsCopy = false;
              } else {
                final sourceHash = await _integrityVerifier.calculateSha256(entity);
                if (sourceHash == dbFile.sha256) {
                  await _fileRepository.updateFile(dbFile.copyWith(modifiedAt: stat.modified));
                  needsCopy = false;
                }
              }
            }
          }

          if (needsCopy) {
            final destFile = File(destPath);
            if (await destFile.exists()) {
              final destSize = await destFile.length();
              if (destSize == stat.size) {
                final sourceHash = await _integrityVerifier.calculateSha256(entity);
                final destHash = await _integrityVerifier.calculateSha256(destFile);
                if (sourceHash == destHash) {
                  if (dbFile == null) {
                    final fileId = await _fileRepository.addFile(
                      BackupFilesCompanion.insert(
                        folderId: folder.id,
                        fileName: p.basename(entity.path),
                        extension: p.extension(entity.path),
                        originalPath: entity.path,
                        backupPath: destPath,
                        fileSize: stat.size,
                        sha256: sourceHash,
                        modifiedAt: stat.modified,
                        backupStatus: 'success',
                      ),
                    );
                    await _versionRepository.addVersion(
                      FileVersionsCompanion.insert(
                        fileId: fileId,
                        versionNumber: 1,
                        backupPath: destPath,
                      ),
                    );
                  } else {
                    await _fileRepository.updateFile(
                      dbFile.copyWith(
                        backupPath: destPath,
                        fileSize: stat.size,
                        sha256: sourceHash,
                        modifiedAt: stat.modified,
                        backupStatus: 'success',
                      ),
                    );
                  }
                  needsCopy = false;
                }
              } else if (destSize > 0 && destSize < stat.size) {
                offset = destSize;
                await _logger.info('BackupEngine', 'Partially copied file detected: $relativePath. Resuming from byte $offset.');
              }
            }
          }

          if (needsCopy) {
            filesToCopy.add(entity);
            destPaths.add(destPath);
            initialCopiedBytes.add(offset);
            totalBytesToCopy += stat.size;
          } else {
            skippedCount++;
          }
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

    _scanStats[folder.id] = ScanResultStats(
      scannedCount: scannedCount,
      skippedCount: skippedCount,
      totalBytesToCopy: totalBytesToCopy,
      imagesCount: imagesCount,
      videosCount: videosCount,
      documentsCount: documentsCount,
      archivesCount: archivesCount,
      audioCount: audioCount,
      apkCount: apkCount,
      unknownCount: unknownCount,
    );

    await _logger.info(
      'BackupEngine',
      'Scan completed. Total files scanned: $scannedCount. Skipped: $skippedCount unchanged/ignored files.',
    );

    final List<CopyJob> jobsToQueue = [];
    for (int i = 0; i < filesToCopy.length; i++) {
      final file = filesToCopy[i];
      final destPath = destPaths[i];
      final offset = initialCopiedBytes[i];
      final stat = await file.stat();

      jobsToQueue.add(
        CopyJob(
          id: _generateJobId(),
          folderId: folder.id,
          folderName: folder.name,
          sourcePath: file.path,
          destinationPath: destPath,
          fileSize: stat.size,
          progress: offset > 0 ? (offset / stat.size) : 0.0,
        ),
      );
    }

    for (final dbFile in dbFiles) {
      if (!scannedPaths.contains(dbFile.originalPath) &&
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
        'Backup finished. No new or modified files to copy for folder: ${folder.name}',
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
    _watcherEventController.add(event);
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
  final versionRepo = ref.watch(fileVersionRepositoryProvider);
  final folderWatcher = ref.watch(folderWatcherProvider);
  final copyEngine = ref.watch(copyEngineProvider);
  final versionManager = ref.watch(versionManagerProvider);
  final logger = ref.watch(loggingServiceProvider);

  return BackupEngine(
    folderRepository: folderRepo,
    fileRepository: fileRepo,
    versionRepository: versionRepo,
    folderWatcher: folderWatcher,
    copyEngine: copyEngine,
    versionManager: versionManager,
    logger: logger,
  );
});
