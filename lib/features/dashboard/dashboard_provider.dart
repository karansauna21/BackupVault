import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/copy_engine/copy_job.dart';
import '../../core/copy_engine/copy_queue.dart';
import '../../core/copy_engine/copy_engine_providers.dart';
import '../../core/restore/restore_job.dart';
import '../../core/restore/restore_queue.dart';
import '../../core/file_watcher/watcher_manager.dart';
import '../../core/file_watcher/watcher_state.dart';
import 'dashboard_models.dart';
import 'dashboard_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final baseStats = await repo.fetchStats();

  final copyQueue = ref.watch(copyQueueProvider);
  final restoreQueue = ref.watch(restoreQueueProvider);
  final watcherState = ref.watch(watcherStateProvider);

  final totalSpeed = ref.watch(totalSpeedProvider);

  final pendingQueueSize = copyQueue
      .where((j) => j.status == CopyStatus.pending || j.status == CopyStatus.copying)
      .length;
  final activeRestoreCount = restoreQueue
      .where((j) => j.status == RestoreStatus.pending || j.status == RestoreStatus.restoring)
      .length;

  String backupStatus = 'Idle';
  if (copyQueue.any((j) => j.status == CopyStatus.copying)) {
    backupStatus = 'Backing Up';
  } else if (watcherState.status == WatcherStatus.paused) {
    backupStatus = 'Paused';
  } else if (watcherState.status == WatcherStatus.error) {
    backupStatus = 'Error';
  }

  String engineStatus = 'Active';
  if (watcherState.status == WatcherStatus.idle) {
    engineStatus = 'Idle';
  } else if (watcherState.status == WatcherStatus.paused) {
    engineStatus = 'Paused';
  } else if (watcherState.status == WatcherStatus.error) {
    engineStatus = 'Error';
  }

  return baseStats.copyWith(
    backupStatus: backupStatus,
    engineStatus: engineStatus,
    pendingQueueSize: pendingQueueSize,
    restoreJobsCount: baseStats.restoreJobsCount + activeRestoreCount,
    averageBackupSpeed: totalSpeed,
  );
});

final recentActivityProvider = FutureProvider.autoDispose<List<ActivityEvent>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  // Force rebuild on copy completion or log updates
  ref.watch(copyQueueProvider);
  return repo.fetchRecentActivity();
});
