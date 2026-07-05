import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import 'statistics_state.dart';

class StatisticsNotifier extends Notifier<StatisticsState> {
  @override
  StatisticsState build() {
    refreshStats();
    return StatisticsState.initial();
  }

  Future<void> refreshStats() async {
    state = state.copyWith(isLoading: true);
    final db = ref.read(databaseProvider);
    try {
      final foldersList = await db.select(db.backupFolders).get();
      final folderIdMap = {for (var f in foldersList) f.id: f.name};

      final historyList = await db.select(db.backupHistory).get();

      int totalAttempts = historyList.length;
      int successCount = 0;
      int failureCount = 0;
      int totalSizeSum = 0;
      
      Map<String, int> folderSizeMap = {};
      Map<String, int> folderFilesMap = {};

      for (var h in historyList) {
        if (h.status == 'success') {
          successCount++;
          totalSizeSum += h.totalSize;

          final folderName = folderIdMap[h.folderId] ?? 'Deleted Folder (ID ${h.folderId})';
          folderSizeMap[folderName] = (folderSizeMap[folderName] ?? 0) + h.totalSize;
          folderFilesMap[folderName] = (folderFilesMap[folderName] ?? 0) + h.filesCount;
        } else {
          failureCount++;
        }
      }

      double avgSizeMb = 0.0;
      if (successCount > 0) {
        final avgBytes = totalSizeSum / successCount;
        avgSizeMb = avgBytes / (1024 * 1024);
      }

      state = StatisticsState(
        totalAttempts: totalAttempts,
        successCount: successCount,
        failureCount: failureCount,
        averageSizeMb: avgSizeMb,
        folderSizeDistribution: folderSizeMap,
        folderFileCountDistribution: folderFilesMap,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final statisticsProvider = NotifierProvider<StatisticsNotifier, StatisticsState>(() {
  return StatisticsNotifier();
});
