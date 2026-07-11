import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../repositories/repository_providers.dart';
import 'logging_service.dart';

class BackupMigrationService {
  final Ref ref;
  final LoggingService _logger;

  BackupMigrationService(this.ref) : _logger = ref.read(loggingServiceProvider);

  String getCategoryForExtension(String ext) {
    final cleanExt = ext.toLowerCase().replaceAll('.', '').trim();
    switch (cleanExt) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
        return 'Images';
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case '3gp':
        return 'Videos';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'txt':
        return 'Documents';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return 'Archives';
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return 'Audio';
      case 'apk':
      case 'exe':
      case 'msi':
        return 'Applications';
      default:
        return 'Others';
    }
  }

  String getMirrorRelativePath(String currentBackupPath, String destRoot) {
    final relativeToRoot = p.relative(currentBackupPath, from: destRoot);
    final parts = p.split(relativeToRoot);
    if (parts.isNotEmpty) {
      final firstPart = parts.first;
      const categories = {'Images', 'Videos', 'Documents', 'Archives', 'Audio', 'Applications', 'Others'};
      if (categories.contains(firstPart)) {
        return p.joinAll(parts.sublist(1));
      }
    }
    return relativeToRoot;
  }

  Future<void> migrateAllFolders(String oldMode, String newMode) async {
    if (oldMode == newMode) return;
    await _logger.warning('MigrationService', 'Starting backup organization migration: $oldMode -> $newMode');

    try {
      final folderRepo = ref.read(backupFolderRepositoryProvider);
      final fileRepo = ref.read(backupFileRepositoryProvider);
      final versionRepo = ref.read(fileVersionRepositoryProvider);
      
      final folders = await folderRepo.getAllFolders();
      for (final folder in folders) {
        await _logger.info('MigrationService', 'Migrating folder: ${folder.name}');
        final dbFiles = await fileRepo.getFilesByFolderId(folder.id);
        
        for (final dbFile in dbFiles) {
          final versions = await versionRepo.getVersionsByFileId(dbFile.id);
          
          // Migrate each version
          for (final ver in versions) {
            final currentPath = ver.backupPath;
            final destRoot = folder.destinationPath;
            
            final mirrorRelPath = getMirrorRelativePath(currentPath, destRoot);
            final category = getCategoryForExtension(dbFile.extension);
            
            final mirrorTarget = p.join(destRoot, mirrorRelPath);
            final smartTarget = p.join(destRoot, category, mirrorRelPath);
            
            if (newMode == 'mirror') {
              // 1. Move to mirror target if at smart path
              if (currentPath == smartTarget) {
                final srcFile = File(currentPath);
                if (await srcFile.exists()) {
                  final destFile = File(mirrorTarget);
                  await destFile.parent.create(recursive: true);
                  await srcFile.rename(mirrorTarget);
                  await _cleanEmptyDirs(srcFile.parent, destRoot);
                }
              }
              // 2. Delete index file if migrating away from hybrid mode
              if (oldMode == 'hybrid') {
                final indexFile = File(smartTarget);
                if (await indexFile.exists()) {
                  await indexFile.delete();
                  await _cleanEmptyDirs(indexFile.parent, destRoot);
                }
              }
              // Update database version
              await versionRepo.updateVersion(ver.copyWith(backupPath: mirrorTarget));
            } 
            else if (newMode == 'smart') {
              // 1. Move to smart target if at mirror path
              if (currentPath == mirrorTarget) {
                final srcFile = File(currentPath);
                if (await srcFile.exists()) {
                  final destFile = File(smartTarget);
                  await destFile.parent.create(recursive: true);
                  await srcFile.rename(smartTarget);
                  await _cleanEmptyDirs(srcFile.parent, destRoot);
                }
              }
              // 2. Delete mirror file if migrating from hybrid mode
              if (oldMode == 'hybrid') {
                final mirrorFile = File(mirrorTarget);
                if (await mirrorFile.exists()) {
                  await mirrorFile.delete();
                  await _cleanEmptyDirs(mirrorFile.parent, destRoot);
                }
              }
              // Update database version
              await versionRepo.updateVersion(ver.copyWith(backupPath: smartTarget));
            } 
            else if (newMode == 'hybrid') {
              // 1. Ensure exists at both paths, database version references mirrorTarget
              final mirrorFile = File(mirrorTarget);
              final smartFile = File(smartTarget);
              
              if (currentPath == mirrorTarget) {
                if (await mirrorFile.exists() && !await smartFile.exists()) {
                  await smartFile.parent.create(recursive: true);
                  await mirrorFile.copy(smartTarget);
                }
              } else if (currentPath == smartTarget) {
                if (await smartFile.exists() && !await mirrorFile.exists()) {
                  await mirrorFile.parent.create(recursive: true);
                  await smartFile.rename(mirrorTarget);
                  // Since we renamed, copy it back to smartTarget to maintain hybrid index
                  await mirrorFile.copy(smartTarget);
                }
              } else {
                // If it's located somewhere else
                final srcFile = File(currentPath);
                if (await srcFile.exists()) {
                  await mirrorFile.parent.create(recursive: true);
                  await smartFile.parent.create(recursive: true);
                  await srcFile.copy(mirrorTarget);
                  await srcFile.rename(smartTarget);
                }
              }
              // Update database version
              await versionRepo.updateVersion(ver.copyWith(backupPath: mirrorTarget));
            }
          }
          
          // Update the main file record backupPath to match version 1 or the latest version path
          final updatedVersions = await versionRepo.getVersionsByFileId(dbFile.id);
          if (updatedVersions.isNotEmpty) {
            final latestBackupPath = updatedVersions.last.backupPath;
            await fileRepo.updateFile(dbFile.copyWith(backupPath: latestBackupPath));
          }
        }
      }
      
      await _logger.info('MigrationService', 'Backup organization migration completed successfully');
    } catch (e, stack) {
      await _logger.error('MigrationService', 'Error during migration: $e', stack.toString());
    }
  }

  Future<void> _cleanEmptyDirs(Directory dir, String rootPath) async {
    try {
      var current = dir;
      // Do not delete root directory or go outside it
      while (current.path != rootPath && p.isWithin(rootPath, current.path)) {
        if (await current.exists()) {
          final list = await current.list().toList();
          if (list.isEmpty) {
            await current.delete();
            current = current.parent;
          } else {
            break;
          }
        } else {
          current = current.parent;
        }
      }
    } catch (_) {
      // Best effort cleanup
    }
  }
}

final backupMigrationServiceProvider = Provider<BackupMigrationService>((ref) {
  return BackupMigrationService(ref);
});
