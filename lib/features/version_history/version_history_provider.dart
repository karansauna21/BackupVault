import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import 'version_models.dart';
import 'version_history_repository.dart';
import 'version_service.dart';
import 'version_statistics.dart';
import 'version_search.dart';

final versionHistoryRepositoryProvider = Provider<VersionHistoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VersionHistoryRepository(db);
});

final versionServiceProvider = Provider<VersionService>((ref) {
  final repo = ref.watch(versionHistoryRepositoryProvider);
  return VersionService(repo);
});

class SelectedFileIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? fileId) {
    state = fileId;
  }
}

final selectedFileIdProvider = NotifierProvider<SelectedFileIdNotifier, int?>(() {
  return SelectedFileIdNotifier();
});

class SelectedVersionNotifier extends Notifier<VersionDetail?> {
  @override
  VersionDetail? build() => null;

  void select(VersionDetail? version) {
    state = version;
  }
}

final selectedVersionProvider = NotifierProvider<SelectedVersionNotifier, VersionDetail?>(() {
  return SelectedVersionNotifier();
});

class VersionFiltersNotifier extends Notifier<VersionHistoryFilter> {
  @override
  VersionHistoryFilter build() => const VersionHistoryFilter();

  void updateFilter(VersionHistoryFilter filter) {
    state = filter;
  }

  void reset() {
    state = const VersionHistoryFilter();
  }
}

final versionFiltersProvider = NotifierProvider<VersionFiltersNotifier, VersionHistoryFilter>(() {
  return VersionFiltersNotifier();
});

final backupFilesListProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(versionHistoryRepositoryProvider);
  return repo.getAllFiles();
});

final versionListProvider = FutureProvider<List<VersionDetail>>((ref) async {
  final fileId = ref.watch(selectedFileIdProvider);
  if (fileId == null) return const [];

  final service = ref.watch(versionServiceProvider);
  return service.getVersionDetails(fileId);
});

final versionSearchResultsProvider = Provider<AsyncValue<List<VersionDetail>>>((ref) {
  final listAsync = ref.watch(versionListProvider);
  final filter = ref.watch(versionFiltersProvider);

  return listAsync.when(
    data: (list) => AsyncValue.data(VersionSearchEvaluator.filter(list, filter)),
    error: (err, stack) => AsyncValue.error(err, stack),
    loading: () => const AsyncValue.loading(),
  );
});

class TimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final String eventType; // 'created', 'modified', 'restored', 'verified', 'compared'

  const TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.eventType,
  });
}

final versionTimelineProvider = Provider<AsyncValue<List<TimelineEvent>>>((ref) {
  final listAsync = ref.watch(versionListProvider);

  return listAsync.when(
    data: (list) {
      final List<TimelineEvent> events = [];
      if (list.isEmpty) return AsyncValue.data(events);

      final parent = list.first.parentFile;
      events.add(TimelineEvent(
        title: 'Original File Logged',
        description: 'Original file created at: ${parent.originalPath}',
        timestamp: parent.createdAt,
        eventType: 'created',
      ));

      for (final v in list.reversed) {
        events.add(TimelineEvent(
          title: 'Version #${v.version.versionNumber} Created',
          description: 'Completed backup to store. Worker: ${v.backupWorker}. Size: ${v.sizeBytes} bytes',
          timestamp: v.version.createdAt,
          eventType: 'modified',
        ));

        if (v.verificationStatus == 'verified') {
          events.add(TimelineEvent(
            title: 'Integrity Check Passed',
            description: 'Version #${v.version.versionNumber} checked and verified matching SHA-256: ${v.sha256.substring(0, 8)}...',
            timestamp: v.version.createdAt.add(const Duration(minutes: 2)),
            eventType: 'verified',
          ));
        }
      }

      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return AsyncValue.data(events);
    },
    error: (err, stack) => AsyncValue.error(err, stack),
    loading: () => const AsyncValue.loading(),
  );
});

final versionStatisticsProvider = FutureProvider<VersionHistoryStats>((ref) async {
  final repo = ref.watch(versionHistoryRepositoryProvider);
  return VersionStatisticsCalculator.calculateStats(repo);
});
