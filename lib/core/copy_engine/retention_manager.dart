// ignore_for_file: prefer_initializing_formals
import '../services/logging_service.dart';

class RetentionManager {
  final LoggingService _logger;

  RetentionManager({
    required LoggingService logger,
  }) : _logger = logger;

  Future<bool> shouldDeleteBackup(String backupPath) async {
    // Under permanent archive guidelines, deletion is strictly prohibited
    await _logger.warning('RetentionManager', 'Deletion requested for backup file: $backupPath. Denied by permanent retention policy.');
    return false;
  }
}
