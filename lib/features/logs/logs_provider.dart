import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/repositories/repository_providers.dart';
import '../settings/settings_provider.dart';
import 'logs_models.dart';
import 'logs_repository.dart';
import 'log_service.dart';
import 'logs_controller.dart';

/// Database repository provider
final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final logRepo = ref.watch(backupLogRepositoryProvider);
  final settingsDb = ref.watch(settingsDatabaseProvider);
  return LogsRepository(db, logRepo, settingsDb);
});

/// High-level logger service provider
final logServiceProvider = Provider<LogService>((ref) {
  final repo = ref.watch(logsRepositoryProvider);
  return LogService(repo);
});

/// Primary state controller provider for Logs screen
final logsControllerProvider =
    NotifierProvider<LogsController, AsyncValue<List<LogEntry>>>(() {
      return LogsController();
    });

/// Exposes all log statistics computed from the database
final logsStatisticsProvider = FutureProvider<LogStatisticsState>((ref) async {
  // Watch logs controller so it auto-recomputes whenever logs update
  ref.watch(logsControllerProvider);
  final repo = ref.read(logsRepositoryProvider);
  return await repo.calculateStatistics();
});

/// Exposes the list of currently pinned log entries
final pinnedLogsProvider = Provider<List<LogEntry>>((ref) {
  final logsState = ref.watch(logsControllerProvider);
  return logsState.maybeWhen(
    data: (logs) => logs.where((l) => l.isPinned).toList(),
    orElse: () => [],
  );
});

/// Exposes the list of error-level log entries
final logsErrorsProvider = Provider<List<LogEntry>>((ref) {
  final logsState = ref.watch(logsControllerProvider);
  return logsState.maybeWhen(
    data: (logs) => logs.where((l) => l.level == LogLevel.error).toList(),
    orElse: () => [],
  );
});

class LogsSearchQueryNotifier extends Notifier<LogSearchQuery> {
  @override
  LogSearchQuery build() => const LogSearchQuery();

  void update(LogSearchQuery query) => state = query;

  void reset() => state = const LogSearchQuery();
}

/// Exposes the active search query state
final logsSearchQueryProvider =
    NotifierProvider<LogsSearchQueryNotifier, LogSearchQuery>(() {
      return LogsSearchQueryNotifier();
    });

class LogsFilterOptionsNotifier extends Notifier<LogFilterOptions> {
  @override
  LogFilterOptions build() => const LogFilterOptions();

  void update(LogFilterOptions options) => state = options;

  void reset() => state = const LogFilterOptions();
}

/// Exposes the active filter options state
final logsFilterOptionsProvider =
    NotifierProvider<LogsFilterOptionsNotifier, LogFilterOptions>(() {
      return LogsFilterOptionsNotifier();
    });

/// Exposes logs that match the current search filters and criteria
final filteredLogsProvider = Provider<List<LogEntry>>((ref) {
  final logsState = ref.watch(logsControllerProvider);
  final search = ref.watch(logsSearchQueryProvider);
  final filters = ref.watch(logsFilterOptionsProvider);

  return logsState.maybeWhen(
    data: (logs) {
      return logs.where((entry) {
        // 1. Search Query Filters
        if (!search.isEmpty) {
          if (search.keyword.isNotEmpty) {
            final kw = search.keyword.toLowerCase();
            final matchesMsg = entry.message.toLowerCase().contains(kw);
            final matchesException =
                entry.exceptionDetails?.toLowerCase().contains(kw) ?? false;
            final matchesSrc =
                entry.sourceFile?.toLowerCase().contains(kw) ?? false;
            final matchesDst =
                entry.destinationFile?.toLowerCase().contains(kw) ?? false;
            if (!matchesMsg &&
                !matchesException &&
                !matchesSrc &&
                !matchesDst) {
              return false;
            }
          }

          if (search.folder != null && search.folder!.isNotEmpty) {
            final f = search.folder!.toLowerCase();
            final srcMatch =
                entry.sourceFile?.toLowerCase().contains(f) ?? false;
            final dstMatch =
                entry.destinationFile?.toLowerCase().contains(f) ?? false;
            if (!srcMatch && !dstMatch) return false;
          }

          if (search.file != null && search.file!.isNotEmpty) {
            final fl = search.file!.toLowerCase();
            final srcMatch =
                entry.sourceFile?.toLowerCase().contains(fl) ?? false;
            final dstMatch =
                entry.destinationFile?.toLowerCase().contains(fl) ?? false;
            if (!srcMatch && !dstMatch) return false;
          }

          if (search.dateRange != null) {
            final start = search.dateRange!.start;
            final end = search.dateRange!.end.add(
              const Duration(days: 1),
            ); // inclusive of end day
            if (entry.timestamp.isBefore(start) ||
                entry.timestamp.isAfter(end)) {
              return false;
            }
          }

          if (search.level != null && entry.level != search.level) {
            return false;
          }

          if (search.category != null && entry.category != search.category) {
            return false;
          }

          if (search.status != null && search.status!.isNotEmpty) {
            if (entry.status?.toLowerCase() != search.status!.toLowerCase()) {
              return false;
            }
          }

          if (search.errorCode != null && search.errorCode!.isNotEmpty) {
            if (entry.errorCode?.toLowerCase() !=
                search.errorCode!.toLowerCase()) {
              return false;
            }
          }

          if (search.worker != null && search.worker!.isNotEmpty) {
            if (entry.workerId?.toLowerCase() != search.worker!.toLowerCase()) {
              return false;
            }
          }
        }

        // 2. Filter Options
        if (!filters.isEmpty) {
          if (filters.levels.isNotEmpty &&
              !filters.levels.contains(entry.level)) {
            return false;
          }

          if (filters.modules.isNotEmpty &&
              !filters.modules.contains(entry.module)) {
            return false;
          }

          if (filters.showOnlyErrors && entry.level != LogLevel.error) {
            return false;
          }

          if (filters.showOnlyWarnings && entry.level != LogLevel.warning) {
            return false;
          }

          if (filters.showOnlySuccess && entry.level != LogLevel.success) {
            return false;
          }

          if (filters.showOnlyImportant && !entry.isImportant) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

/// Exposes recent activity logs (e.g., today's activity)
final recentActivityProvider = Provider<List<LogEntry>>((ref) {
  final logs = ref.watch(filteredLogsProvider);
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  return logs.where((l) => l.timestamp.isAfter(startOfToday)).toList();
});
