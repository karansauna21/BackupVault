// ignore_for_file: prefer_initializing_formals
import 'package:path/path.dart' as p;
import '../repositories/backup_file_repository.dart';
import '../repositories/file_version_repository.dart';
import 'duplicate_detector.dart';
import 'path_generator.dart';

// Helper extension to mimic firstWhereOrNull
extension _ListExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ArchiveManager {
  final BackupFileRepository _fileRepository;
  final FileVersionRepository _versionRepository;
  final PathGenerator _pathGenerator;
  final DuplicateDetector _duplicateDetector;

  ArchiveManager({
    required BackupFileRepository fileRepository,
    required FileVersionRepository versionRepository,
    required PathGenerator pathGenerator,
    required DuplicateDetector duplicateDetector,
  })  : _fileRepository = fileRepository,
        _versionRepository = versionRepository,
        _pathGenerator = pathGenerator,
        _duplicateDetector = duplicateDetector;

  Future<String> resolveArchivePath({
    required int folderId,
    required String folderName,
    required String backupRoot,
    required String sourcePath,
    required String relativePath,
    required String currentHash,
    required int fileSize,
  }) async {
    final dbFiles = await _fileRepository.getFilesByFolderId(folderId);
    final existingFile = dbFiles.firstWhereOrNull((f) => f.originalPath == sourcePath);

    final basePath = _pathGenerator.generateTimestampPath(backupRoot, folderName, relativePath);

    if (existingFile == null) {
      // Brand new original file. Handle destination filename clashes.
      return _pathGenerator.getUniqueDuplicatePath(basePath);
    }

    // Existing original file. Check if content hasn't changed.
    if (existingFile.sha256 == currentHash && existingFile.backupStatus == 'success') {
      return existingFile.backupPath;
    }

    // Content modified, trigger versioning.
    final versions = await _versionRepository.getVersionsByFileId(existingFile.id);
    final versionNumber = versions.length + 1;

    final baseDestName = p.basename(existingFile.backupPath);
    final cleanBaseDestName = _removeVersionTags(baseDestName);
    
    final versionedDestName = _pathGenerator.getVersionedPath(cleanBaseDestName, versionNumber);
    final destDirectory = p.dirname(existingFile.backupPath);

    return p.join(destDirectory, versionedDestName);
  }

  String _removeVersionTags(String filename) {
    final ext = p.extension(filename);
    final base = p.basenameWithoutExtension(filename);
    final cleanBase = base.replaceAll(RegExp(r'_v\d+$'), '');
    return '$cleanBase$ext';
  }

  DuplicateDetector get duplicateDetector => _duplicateDetector;
}
