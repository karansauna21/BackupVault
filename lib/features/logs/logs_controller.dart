import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logs_models.dart';
import 'logs_repository.dart';
import 'log_exporter.dart';
import 'logs_provider.dart';

class LogsController extends Notifier<AsyncValue<List<LogEntry>>> {
  late final LogsRepository _repository;

  @override
  AsyncValue<List<LogEntry>> build() {
    _repository = ref.watch(logsRepositoryProvider);
    Future.microtask(() => loadLogs());
    return const AsyncValue.loading();
  }

  /// Initial load of logs from the database
  Future<void> loadLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _repository.getLogs(limit: 2000);
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh current logs list
  Future<void> refreshLogs() async {
    try {
      final logs = await _repository.getLogs(limit: 2000);
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Clear all logs in the database
  Future<void> clearLogs() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearAllLogs();
      // Log clear event itself
      await _repository.addLogEntry(LogEntry(
        id: 0,
        timestamp: DateTime.now(),
        level: LogLevel.system,
        module: LogModule.system,
        category: LogCategory.databaseEvents,
        message: 'System logs cleared by user.',
        isImportant: true,
      ));
      final logs = await _repository.getLogs(limit: 2000);
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Pin or unpin a specific log entry
  Future<void> togglePinLog(int logId) async {
    try {
      await _repository.togglePinLog(logId);
      await refreshLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Trigger log export to a file
  Future<String> exportLogs({
    required List<LogEntry> logsToExport,
    required String format,
    required String targetDirectory,
    String? customFileName,
  }) async {
    return await LogExporter.exportLogs(
      logs: logsToExport,
      format: format,
      targetDirectory: targetDirectory,
      customFileName: customFileName,
    );
  }

  /// Manually delete logs older than [days]
  Future<int> deleteOldLogs(int days) async {
    try {
      final count = await _repository.deleteLogsOlderThan(days);
      await _repository.addLogEntry(LogEntry(
        id: 0,
        timestamp: DateTime.now(),
        level: LogLevel.system,
        module: LogModule.system,
        category: LogCategory.databaseEvents,
        message: 'Database maintenance: Purged $count log entries older than $days days.',
      ));
      await refreshLogs();
      return count;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Perform database auto-cleanup
  Future<void> runAutoCleanup(MaintenanceConfig config) async {
    try {
      await _repository.autoCleanup(config);
      await refreshLogs();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
