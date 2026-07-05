import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../repositories/backup_log_repository.dart';
import '../repositories/repository_providers.dart';

class LoggingService {
  final BackupLogRepository _repository;

  LoggingService(this._repository);

  Future<void> info(String tag, String message) async {
    await _log('info', tag, message);
  }

  Future<void> warning(String tag, String message) async {
    await _log('warning', tag, message);
  }

  Future<void> error(String tag, String message, [String? stackTrace]) async {
    await _log('error', tag, message, stackTrace);
  }

  Future<void> _log(String logType, String tag, String message, [String? stackTrace]) async {
    try {
      await _repository.addLog(
        BackupLogsCompanion.insert(
          logType: logType,
          message: message,
          tag: Value(tag),
          stackTrace: Value(stackTrace),
        ),
      );
    } catch (e) {
      // Fallback printing to stdout
      // ignore: avoid_print
      print('[$logType][$tag] $message. Error saving: $e');
    }
  }

  Future<List<BackupLog>> getLogs({String? level, int limit = 200}) async {
    return _repository.getAllLogs(logType: level, limit: limit);
  }

  Future<void> clearLogs() async {
    await _repository.clearLogs();
  }
}

final loggingServiceProvider = Provider<LoggingService>((ref) {
  final repo = ref.watch(backupLogRepositoryProvider);
  return LoggingService(repo);
});
