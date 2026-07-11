import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/utils/android_storage.dart';
import '../../core/database/app_database.dart';
import '../../core/repositories/backup_folder_repository.dart';
import '../../core/repositories/repository_providers.dart';
import 'folder_models.dart';
import 'folder_scanner.dart';
import 'folder_validator.dart';

class FolderManagerRepository {
  final BackupFolderRepository dbFolderRepo;

  FolderManagerRepository({
    required this.dbFolderRepo,
  });

  Future<File> _getConfigFile() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backup_vault'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'folder_configs.json'));
  }

  Future<Map<int, FolderStats>> _loadAllStats() async {
    try {
      final file = await _getConfigFile();
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      
      final Map<String, dynamic> decoded = json.decode(content);
      return decoded.map((key, value) {
        final id = int.parse(key);
        return MapEntry(id, FolderStats.fromJson(value));
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAllStats(Map<int, FolderStats> allStats) async {
    try {
      final file = await _getConfigFile();
      final mapToSave = allStats.map((key, value) => MapEntry(key.toString(), value.toJson()));
      await file.writeAsString(json.encode(mapToSave));
    } catch (_) {}
  }

  Future<FolderStats> getStatsForFolder(int folderId) async {
    final all = await _loadAllStats();
    return all[folderId] ?? FolderStats(folderId: folderId);
  }

  Future<void> saveStatsForFolder(int folderId, FolderStats stats) async {
    final all = await _loadAllStats();
    all[folderId] = stats;
    await _saveAllStats(all);
  }

  Future<FolderStats> scanAndValidate(int folderId, String sourcePath, String destinationPath) async {
    final currentStats = await getStatsForFolder(folderId);
    
    var resolvedSource = sourcePath;
    var resolvedDest = destinationPath;

    if (Platform.isAndroid) {
      if (sourcePath.startsWith('content://')) {
        final resolved = await AndroidStorage.resolvePath(sourcePath);
        if (resolved != null && resolved.isNotEmpty) {
          resolvedSource = resolved;
        }
      }
      if (destinationPath.startsWith('content://')) {
        final resolved = await AndroidStorage.resolvePath(destinationPath);
        if (resolved != null && resolved.isNotEmpty) {
          resolvedDest = resolved;
        }
      }
    }
    
    // 1. Scan folder files
    final scanner = FolderScanner(path: resolvedSource, rules: currentStats.rules);
    final scanResult = await scanner.scan();

    // 2. Validate folder health
    final health = await FolderValidator.checkHealth(resolvedSource, resolvedDest);

    final updated = currentStats.copyWith(
      fileCount: scanResult.fileCount,
      totalSize: scanResult.totalSize,
      lastScanTime: scanResult.lastScanTime,
      health: health,
    );

    await saveStatsForFolder(folderId, updated);
    return updated;
  }

  Future<void> deleteFolderConfig(int folderId) async {
    final all = await _loadAllStats();
    all.remove(folderId);
    await _saveAllStats(all);
  }

  Future<String> exportConfigs(List<int> folderIds) async {
    final all = await _loadAllStats();
    final dbFolders = await dbFolderRepo.getAllFolders();
    
    final List<Map<String, dynamic>> exportList = [];
    for (final folder in dbFolders) {
      if (folderIds.contains(folder.id)) {
        final stats = all[folder.id] ?? FolderStats(folderId: folder.id);
        exportList.add({
          'name': folder.name,
          'sourcePath': folder.sourcePath,
          'destinationPath': folder.destinationPath,
          'enabled': folder.enabled,
          'backupInterval': folder.backupInterval,
          'rules': stats.rules.toJson(),
        });
      }
    }
    return json.encode(exportList);
  }

  Future<void> importConfigs(String jsonContent) async {
    final List<dynamic> list = json.decode(jsonContent);
    for (final item in list) {
      final String name = item['name'] ?? 'Imported Folder';
      final String sourcePath = item['sourcePath'] ?? '';
      final String destinationPath = item['destinationPath'] ?? '';
      final bool enabled = item['enabled'] ?? true;
      final String backupInterval = item['backupInterval'] ?? 'manual';
      final rules = FolderRules.fromJson(item['rules'] ?? {});

      // Add to Drift database
      final companion = BackupFoldersCompanion.insert(
        name: name,
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        enabled: Value(enabled),
        backupInterval: Value(backupInterval),
      );

      final newId = await dbFolderRepo.addFolder(companion);
      
      // Save rules & stats
      final stats = FolderStats(folderId: newId, rules: rules);
      await saveStatsForFolder(newId, stats);
      
      // Try to scan after import
      await scanAndValidate(newId, sourcePath, destinationPath);
    }
  }
}

final folderManagerRepositoryProvider = Provider<FolderManagerRepository>((ref) {
  final dbFolderRepo = ref.watch(backupFolderRepositoryProvider);
  return FolderManagerRepository(dbFolderRepo: dbFolderRepo);
});
