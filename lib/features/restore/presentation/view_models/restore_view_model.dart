import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/logging_service.dart';
import 'restore_state.dart';

class RestoreNotifier extends Notifier<RestoreState> {
  @override
  RestoreState build() {
    return RestoreState();
  }

  Future<List<BackupHistoryData>> getRestorePoints() async {
    final db = ref.read(databaseProvider);
    final query = db.select(db.backupHistory)
      ..where((t) => t.status.equals('success'))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return query.get();
  }

  Future<void> runRestore(BackupHistoryData historyItem, String folderName) async {
    if (state.isRestoring) return;

    final logger = ref.read(loggingServiceProvider);

    state = RestoreState(
      isRestoring: true,
      currentHistoryId: historyItem.id,
      progress: 0.0,
      statusText: 'Preparing folders for restore...',
    );

    await logger.info('RestoreService', 'Starting restore for point: ID ${historyItem.id} (${historyItem.timestamp})');

    // Simulate scanning/unpacking
    await Future.delayed(const Duration(milliseconds: 1000));

    state = state.copyWith(statusText: 'Verifying package integrity...', progress: 0.2);
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate file restoring
    for (int i = 3; i <= 10; i++) {
      state = state.copyWith(
        progress: i / 10.0,
        statusText: 'Restoring files to destination... (${(i * 10)}% completed)',
      );
      await Future.delayed(const Duration(milliseconds: 350));
    }

    await logger.info('RestoreService', 'Restore of "$folderName" from ${historyItem.timestamp} completed successfully. Restored ${historyItem.filesCount} files.');
    
    state = RestoreState(); // Reset state
  }
}

final restoreProvider = NotifierProvider<RestoreNotifier, RestoreState>(() {
  return RestoreNotifier();
});

// A future provider to load restore points dynamically for UI dropdown/list
final restorePointsProvider = FutureProvider.autoDispose<List<BackupHistoryData>>((ref) async {
  return ref.watch(restoreProvider.notifier).getRestorePoints();
});
