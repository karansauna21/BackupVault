import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/file_watcher/watcher_manager.dart';
import 'folder_models.dart';
import 'folder_manager_provider.dart';
import 'folder_manager_repository.dart';

class FolderManagerController {
  final WidgetRef ref;

  FolderManagerController(this.ref);

  Future<void> addFolder({
    required String name,
    required String sourcePath,
    required String destinationPath,
    required String interval,
    FolderRules rules = const FolderRules(),
    String? destinationType,
    String? deviceUuid,
    String? deviceName,
    String? remoteFolderId,
    String? remoteFolderPath,
  }) async {
    final notifier = ref.read(folderManagerProvider.notifier);
    final id = await notifier.addFolder(
      name: name,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      interval: interval,
      rules: rules,
      destinationType: destinationType,
      deviceUuid: deviceUuid,
      deviceName: deviceName,
      remoteFolderId: remoteFolderId,
      remoteFolderPath: remoteFolderPath,
    );

    // Scan immediately after adding to get stats
    await scanFolder(id);

    // If enabled, start monitoring
    final folders = ref.read(folderManagerProvider).value ?? [];
    final folder = folders.firstWhere((f) => f.id == id);
    if (folder.enabled) {
      ref.read(watcherStateProvider.notifier).startMonitoringFolder(
        folder,
        excludedExtensions: rules.excludeExtensions,
      );
    }
  }

  Future<void> editFolder(
    BackupFolder folder, {
    required String name,
    required String sourcePath,
    required String destinationPath,
    required String interval,
    FolderRules? rules,
    String? destinationType,
    String? deviceUuid,
    String? deviceName,
    String? remoteFolderId,
    String? remoteFolderPath,
  }) async {
    final notifier = ref.read(folderManagerProvider.notifier);
    final updated = folder.copyWith(
      name: name,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      backupInterval: interval,
      destinationType: Value(destinationType),
      deviceUuid: Value(deviceUuid),
      deviceName: Value(deviceName),
      remoteFolderId: Value(remoteFolderId),
      remoteFolderPath: Value(remoteFolderPath),
    );
    await notifier.updateFolder(updated, rules: rules);

    // Rescan folder
    await scanFolder(folder.id);

    // Restart watcher
    if (updated.enabled) {
      ref.read(watcherStateProvider.notifier).startMonitoringFolder(
        updated,
        excludedExtensions: rules?.excludeExtensions ?? const [],
      );
    } else {
      ref.read(watcherStateProvider.notifier).stopMonitoringFolder(folder.id);
    }
  }

  Future<void> deleteFolder(int id, String name) async {
    // 1. Stop monitoring
    ref.read(watcherStateProvider.notifier).stopMonitoringFolder(id);
    
    // 2. Delete from database & repository
    await ref.read(folderManagerProvider.notifier).deleteFolder(id, name);
  }

  Future<void> toggleFolder(int id, bool enabled) async {
    await ref.read(folderManagerProvider.notifier).toggleFolderActive(id, enabled);
    
    // Manage watcher
    final folders = ref.read(folderManagerProvider).value ?? [];
    final folder = folders.firstWhere((f) => f.id == id);
    
    if (enabled) {
      final stats = ref.read(folderStatsProvider(id)).value;
      ref.read(watcherStateProvider.notifier).startMonitoringFolder(
        folder,
        excludedExtensions: stats?.rules.excludeExtensions ?? const [],
      );
    } else {
      ref.read(watcherStateProvider.notifier).stopMonitoringFolder(id);
    }
  }

  Future<void> scanFolder(int id) async {
    final folders = ref.read(folderManagerProvider).value ?? [];
    final folder = folders.firstWhere((f) => f.id == id);
    
    final repo = ref.read(folderManagerRepositoryProvider);
    await repo.scanAndValidate(id, folder.sourcePath, folder.destinationPath);
    ref.invalidate(folderStatsProvider(id));
  }

  Future<void> scanAllFolders() async {
    final folders = ref.read(folderManagerProvider).value ?? [];
    for (final folder in folders) {
      await scanFolder(folder.id);
    }
  }

  // Bulk Operations
  Future<void> bulkEnable(List<int> ids) async {
    for (final id in ids) {
      await toggleFolder(id, true);
    }
  }

  Future<void> bulkDisable(List<int> ids) async {
    for (final id in ids) {
      await toggleFolder(id, false);
    }
  }

  Future<void> bulkDelete(List<int> ids) async {
    final folders = ref.read(folderManagerProvider).value ?? [];
    for (final id in ids) {
      final folder = folders.firstWhere((f) => f.id == id);
      await deleteFolder(id, folder.name);
    }
    ref.read(selectedFolderIdsProvider.notifier).clear();
  }

  Future<String> exportConfigs(List<int> ids) async {
    final repo = ref.read(folderManagerRepositoryProvider);
    return repo.exportConfigs(ids);
  }

  Future<void> importConfigs(String jsonContent) async {
    final repo = ref.read(folderManagerRepositoryProvider);
    await repo.importConfigs(jsonContent);
    await ref.read(folderManagerProvider.notifier).loadFolders();
  }
}

final folderManagerControllerProvider = Provider.family<FolderManagerController, WidgetRef>((ref, widgetRef) {
  return FolderManagerController(widgetRef);
});
