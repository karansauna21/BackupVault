import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import 'backup_queue.dart';

class BackupScheduler {
  final Ref _ref;
  Timer? _timer;

  BackupScheduler(this._ref);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkScheduledFolders());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkScheduledFolders() async {
    final db = _ref.read(databaseProvider);
    final queue = _ref.read(backupQueueProvider.notifier);

    final folders = await db.backupFoldersDao.getAllFolders();
    final now = DateTime.now();

    for (final folder in folders) {
      if (!folder.enabled || folder.backupInterval.toLowerCase() == 'manual') continue;

      if (folder.nextBackupAt != null && now.isAfter(folder.nextBackupAt!)) {
        // Trigger Backup Job
        await queue.createAndAddJob(folder.id);

        // Calculate next backup time
        final next = _calculateNextBackupTime(folder.backupInterval);
        final updated = folder.copyWith(
          lastBackupAt: Value(now),
          nextBackupAt: Value(next),
        );
        await db.backupFoldersDao.updateFolder(updated);
      }
    }
  }

  DateTime _calculateNextBackupTime(String interval) {
    final now = DateTime.now();
    switch (interval.toLowerCase()) {
      case 'hourly':
        return now.add(const Duration(hours: 1));
      case 'daily':
        return now.add(const Duration(days: 1));
      case 'weekly':
        return now.add(const Duration(days: 7));
      default:
        return now.add(const Duration(days: 1));
    }
  }
}

final backupSchedulerProvider = Provider<BackupScheduler>((ref) {
  final scheduler = BackupScheduler(ref);
  ref.onDispose(() {
    scheduler.stop();
  });
  return scheduler;
});
