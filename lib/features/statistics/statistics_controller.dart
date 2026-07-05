import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'statistics_provider.dart';
import 'statistics_exporter.dart';

class StatisticsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  /// Manually force a rebuild/refresh of all statistics providers
  void refreshAll() {
    ref.invalidate(storageInfoProvider);
    ref.invalidate(backupStatsProvider);
    ref.invalidate(storageAnalysisProvider);
    ref.invalidate(performanceAnalysisProvider);
    ref.invalidate(backupHealthProvider);
    ref.invalidate(chartsProvider);
  }

  /// Export stats report in JSON, CSV, or HTML format
  Future<String> exportReport({
    required String format,
    String? customFileName,
  }) async {
    state = const AsyncLoading();
    try {
      final stats = await ref.read(backupStatsProvider.future);
      final storage = await ref.read(storageAnalysisProvider.future);
      final performance = await ref.read(performanceAnalysisProvider.future);
      final health = await ref.read(backupHealthProvider.future);

      final tempDir = await getTemporaryDirectory();
      
      final path = await StatisticsExporter.exportReport(
        stats: stats,
        storage: storage,
        performance: performance,
        health: health,
        format: format,
        targetDirectory: tempDir.path,
        customFileName: customFileName,
      );
      
      state = const AsyncData(null);
      return path;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

final statisticsControllerProvider = NotifierProvider<StatisticsController, AsyncValue<void>>(() {
  return StatisticsController();
});
