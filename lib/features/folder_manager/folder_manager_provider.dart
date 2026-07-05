import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/services/logging_service.dart';
import 'folder_models.dart';
import 'folder_manager_repository.dart';

class FolderManagerNotifier extends Notifier<AsyncValue<List<BackupFolder>>> {
  @override
  AsyncValue<List<BackupFolder>> build() {
    loadFolders();
    return const AsyncValue.loading();
  }

  Future<void> loadFolders() async {
    final repository = ref.read(backupFolderRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);
    try {
      final folders = await repository.getAllFolders();
      state = AsyncValue.data(folders);
      // Also pre-load stats for all folders
      for (final folder in folders) {
        ref.read(folderStatsProvider(folder.id));
      }
    } catch (e, stack) {
      logger.error('FolderManager', 'Failed to load folders: $e', stack.toString());
      state = AsyncValue.error(e, stack);
    }
  }

  Future<int> addFolder({
    required String name,
    required String sourcePath,
    required String destinationPath,
    required String interval,
    FolderRules rules = const FolderRules(),
  }) async {
    final repository = ref.read(backupFolderRepositoryProvider);
    final folderRepo = ref.read(folderManagerRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);
    try {
      final companion = BackupFoldersCompanion.insert(
        name: name,
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        backupInterval: Value(interval),
      );
      final newId = await repository.addFolder(companion);
      
      // Save stats and rules
      final stats = FolderStats(folderId: newId, rules: rules);
      await folderRepo.saveStatsForFolder(newId, stats);

      await logger.info('FolderManager', 'Folder "$name" added successfully: $sourcePath -> $destinationPath');
      await loadFolders();
      return newId;
    } catch (e, stack) {
      await logger.error('FolderManager', 'Failed to add folder "$name": $e', stack.toString());
      rethrow;
    }
  }

  Future<void> updateFolder(BackupFolder folder, {FolderRules? rules}) async {
    final repository = ref.read(backupFolderRepositoryProvider);
    final folderRepo = ref.read(folderManagerRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);
    try {
      await repository.updateFolder(folder);
      
      if (rules != null) {
        final currentStats = await folderRepo.getStatsForFolder(folder.id);
        await folderRepo.saveStatsForFolder(folder.id, currentStats.copyWith(rules: rules));
        ref.invalidate(folderStatsProvider(folder.id));
      }

      await logger.info('FolderManager', 'Folder "${folder.name}" updated successfully');
      await loadFolders();
    } catch (e, stack) {
      await logger.error('FolderManager', 'Failed to update folder "${folder.name}": $e', stack.toString());
      rethrow;
    }
  }

  Future<void> deleteFolder(int id, String name) async {
    final repository = ref.read(backupFolderRepositoryProvider);
    final folderRepo = ref.read(folderManagerRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);
    try {
      await repository.deleteFolder(id);
      await folderRepo.deleteFolderConfig(id);
      await logger.warning('FolderManager', 'Folder "$name" deleted');
      await loadFolders();
    } catch (e, stack) {
      await logger.error('FolderManager', 'Failed to delete folder "$name": $e', stack.toString());
      rethrow;
    }
  }

  Future<void> toggleFolderActive(int id, bool isActive) async {
    final repository = ref.read(backupFolderRepositoryProvider);
    final logger = ref.read(loggingServiceProvider);
    try {
      final folder = await repository.getFolderById(id);
      if (folder != null) {
        final updatedFolder = folder.copyWith(enabled: isActive);
        await repository.updateFolder(updatedFolder);
        await logger.info('FolderManager', 'Folder $id active state toggled to $isActive');
        await loadFolders();
      }
    } catch (e, stack) {
      await logger.error('FolderManager', 'Failed to toggle folder $id: $e', stack.toString());
      rethrow;
    }
  }
}

final folderManagerProvider = NotifierProvider<FolderManagerNotifier, AsyncValue<List<BackupFolder>>>(() {
  return FolderManagerNotifier();
});

final folderStatsProvider = FutureProvider.family.autoDispose<FolderStats, int>((ref, folderId) async {
  final repo = ref.watch(folderManagerRepositoryProvider);
  return repo.getStatsForFolder(folderId);
});

// Search & Filter State Providers
class FolderSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final folderSearchQueryProvider = NotifierProvider<FolderSearchQueryNotifier, String>(() {
  return FolderSearchQueryNotifier();
});

class FolderSearchFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String value) => state = value;
}

final folderSearchFilterProvider = NotifierProvider<FolderSearchFilterNotifier, String>(() {
  return FolderSearchFilterNotifier();
});

// Selection State Provider
class SelectedFolderIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  void setSelected(Set<int> ids) {
    state = ids;
  }

  void clear() {
    state = {};
  }
}

final selectedFolderIdsProvider = NotifierProvider<SelectedFolderIdsNotifier, Set<int>>(() {
  return SelectedFolderIdsNotifier();
});

// Filtered folders list
final filteredFoldersProvider = Provider.autoDispose<AsyncValue<List<BackupFolder>>>((ref) {
  final foldersAsync = ref.watch(folderManagerProvider);
  final query = ref.watch(folderSearchQueryProvider).toLowerCase();
  final filter = ref.watch(folderSearchFilterProvider);

  return foldersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (folders) {
      var filtered = folders.where((f) {
        final matchesQuery = f.name.toLowerCase().contains(query) ||
            f.sourcePath.toLowerCase().contains(query) ||
            f.destinationPath.toLowerCase().contains(query);
        
        if (!matchesQuery) return false;

        switch (filter) {
          case 'enabled':
            return f.enabled;
          case 'disabled':
            return !f.enabled;
          case 'failed':
            final stats = ref.watch(folderStatsProvider(f.id)).value;
            return stats?.health.score != null && stats!.health.score < 80;
          default:
            return true;
        }
      }).toList();
      return AsyncValue.data(filtered);
    },
  );
});

// Aggregate overall folder statistics (Total file count, total size)
final folderStatisticsProvider = Provider.autoDispose<FolderSummaryStats>((ref) {
  final foldersAsync = ref.watch(folderManagerProvider);
  
  return foldersAsync.when(
    loading: () => const FolderSummaryStats(totalFolders: 0, totalFiles: 0, totalSize: 0),
    error: (err, stack) => const FolderSummaryStats(totalFolders: 0, totalFiles: 0, totalSize: 0),
    data: (folders) {
      int totalFiles = 0;
      int totalSize = 0;
      
      for (final folder in folders) {
        final stats = ref.watch(folderStatsProvider(folder.id)).value;
        if (stats != null) {
          totalFiles += stats.fileCount;
          totalSize += stats.totalSize;
        }
      }

      return FolderSummaryStats(
        totalFolders: folders.length,
        totalFiles: totalFiles,
        totalSize: totalSize,
      );
    },
  );
});

class FolderSummaryStats {
  final int totalFolders;
  final int totalFiles;
  final int totalSize;

  const FolderSummaryStats({
    required this.totalFolders,
    required this.totalFiles,
    required this.totalSize,
  });
}
