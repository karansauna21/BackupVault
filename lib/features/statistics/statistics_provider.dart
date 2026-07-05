import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/database_provider.dart';
import '../settings/settings_database.dart';
import '../../core/copy_engine/copy_queue.dart';
import '../../core/copy_engine/storage_manager.dart';
import '../../core/restore/restore_queue.dart';
import 'statistics_models.dart';
import 'statistics_repository.dart';
import 'statistics_service.dart';

// Filter state notifier
class StatisticsFilterNotifier extends Notifier<StatisticsFilter> {
  @override
  StatisticsFilter build() => const StatisticsFilter();

  void update(StatisticsFilter filter) {
    state = filter;
  }

  void reset() {
    state = const StatisticsFilter();
  }
}

final statisticsFilterProvider = NotifierProvider<StatisticsFilterNotifier, StatisticsFilter>(() {
  return StatisticsFilterNotifier();
});

// Repository provider
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final settingsDb = SettingsDatabase(); // In-app instance
  return StatisticsRepository(db, settingsDb);
});

// Service provider
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return StatisticsService(repository);
});

// Get target path for storage analysis
final destinationPathProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  final folders = await repo.getAllFolders();
  final enabledFolders = folders.where((f) => f.enabled).toList();
  if (enabledFolders.isNotEmpty) {
    return enabledFolders.first.destinationPath;
  }
  final docDir = await getApplicationDocumentsDirectory();
  return docDir.path;
});

// Get storage metrics asynchronously
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final path = await ref.watch(destinationPathProvider.future);
  return StorageManager().getStorageInfo(path);
});

// Live Stats provider
final backupStatsProvider = FutureProvider<BackupStats>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  final filter = ref.watch(statisticsFilterProvider);
  final activeQueue = ref.watch(copyQueueProvider);
  final activeRestoreQueue = ref.watch(restoreQueueProvider);
  final storageInfo = await ref.watch(storageInfoProvider.future);

  return await service.compileStats(
    filter: filter,
    activeQueue: activeQueue,
    activeRestoreQueue: activeRestoreQueue,
    storageInfo: storageInfo,
  );
});

// Storage analysis provider
final storageAnalysisProvider = FutureProvider<StorageAnalysis>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  final filter = ref.watch(statisticsFilterProvider);
  final storageInfo = await ref.watch(storageInfoProvider.future);

  return await service.compileStorageAnalysis(
    filter: filter,
    storageInfo: storageInfo,
  );
});

// Performance analysis provider
final performanceAnalysisProvider = FutureProvider<PerformanceAnalysis>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  final filter = ref.watch(statisticsFilterProvider);

  return await service.compilePerformanceAnalysis(
    filter: filter,
  );
});

// Health analysis provider
final backupHealthProvider = FutureProvider<BackupHealth>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  final filter = ref.watch(statisticsFilterProvider);
  final storageInfo = await ref.watch(storageInfoProvider.future);

  // Default to true, or query settings
  bool versioningEnabled = true;

  return await service.compileBackupHealth(
    filter: filter,
    storageInfo: storageInfo,
    isVersioningEnabled: versioningEnabled,
  );
});

// Chart data provider
final chartsProvider = FutureProvider<AnalyticsCharts>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  final filter = ref.watch(statisticsFilterProvider);

  return await service.compileCharts(
    filter: filter,
  );
});
