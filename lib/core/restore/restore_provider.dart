import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'restore_job.dart';
import 'restore_queue.dart';
import 'restore_history.dart';
import 'restore_manager.dart';
import '../repositories/repository_providers.dart';
import '../database/app_database.dart';

final activeRestoreJobsProvider = Provider<List<RestoreJob>>((ref) {
  final queue = ref.watch(restoreQueueProvider);
  return queue.where((j) => j.status == RestoreStatus.restoring).toList();
});

final restoreProgressProvider = Provider<double>((ref) {
  final queue = ref.watch(restoreQueueProvider);
  final activeOrCompleted = queue
      .where((j) =>
          j.status == RestoreStatus.restoring ||
          j.status == RestoreStatus.pending ||
          j.status == RestoreStatus.completed)
      .toList();

  if (activeOrCompleted.isEmpty) return 0.0;

  final totalBytes = activeOrCompleted.fold<int>(0, (sum, j) => sum + j.fileSize);
  if (totalBytes == 0) return 0.0;

  final bytesRestored = activeOrCompleted.fold<double>(0.0, (sum, j) {
    if (j.status == RestoreStatus.completed) return sum + j.fileSize;
    return sum + (j.fileSize * j.progress);
  });

  return bytesRestored / totalBytes;
});

final restoreErrorsProvider = Provider<List<String>>((ref) {
  final queue = ref.watch(restoreQueueProvider);
  return queue.where((j) => j.error != null).map((j) => j.error!).toList();
});

final restoreHistoryRecordsProvider = FutureProvider<List<RestoreRecord>>((ref) async {
  final history = ref.watch(restoreHistoryProvider);
  return history.getRecords();
});

class SearchCriteria {
  final String? filename;
  final String? extension;
  final int? folderId;
  final DateTime? backupDate;
  final String? originalPath;
  final int? minSize;
  final int? maxSize;
  final String? sha256;

  SearchCriteria({
    this.filename,
    this.extension,
    this.folderId,
    this.backupDate,
    this.originalPath,
    this.minSize,
    this.maxSize,
    this.sha256,
  });
}

class SearchCriteriaNotifier extends Notifier<SearchCriteria?> {
  @override
  SearchCriteria? build() => null;

  void setCriteria(SearchCriteria? criteria) {
    state = criteria;
  }
}

final searchCriteriaProvider = NotifierProvider<SearchCriteriaNotifier, SearchCriteria?>(() {
  return SearchCriteriaNotifier();
});

final restoreManagerProvider = Provider<RestoreManager>((ref) {
  final fileRepo = ref.watch(backupFileRepositoryProvider);
  final versionRepo = ref.watch(fileVersionRepositoryProvider);
  return RestoreManager(fileRepository: fileRepo, versionRepository: versionRepo);
});

final searchResultsProvider = FutureProvider<List<BackupFile>>((ref) async {
  final criteria = ref.watch(searchCriteriaProvider);
  if (criteria == null) return const [];
  
  final manager = ref.watch(restoreManagerProvider);
  return manager.searchBackupFiles(
    filename: criteria.filename,
    extension: criteria.extension,
    folderId: criteria.folderId,
    backupDate: criteria.backupDate,
    originalPath: criteria.originalPath,
    minSize: criteria.minSize,
    maxSize: criteria.maxSize,
    sha256: criteria.sha256,
  );
});
