import 'dart:io';
import 'settings_models.dart';

class SettingsValidator {
  /// Validates the full SettingsState. Returns a list of error messages.
  /// If the list is empty, the settings are valid.
  static List<String> validate(SettingsState settings) {
    final List<String> errors = [];

    // General
    if (settings.general.theme != 'light' &&
        settings.general.theme != 'dark' &&
        settings.general.theme != 'system') {
      errors.add('General: Theme must be "light", "dark", or "system".');
    }
    if (settings.general.language.trim().isEmpty) {
      errors.add('General: Language code cannot be empty.');
    }

    // Backup
    if (settings.backup.defaultBackupDestination.isNotEmpty) {
      final path = settings.backup.defaultBackupDestination.trim();
      if (Platform.isWindows) {
        final hasDrivePattern = RegExp(r'^[a-zA-Z]:\\');
        if (!hasDrivePattern.hasMatch(path)) {
          errors.add('Backup: Default backup destination must be a valid Windows path (e.g., C:\\Backup).');
        }
      }
    }
    if (settings.backup.maxVersions <= 0) {
      errors.add('Backup: Maximum versions must be greater than 0.');
    }
    if (settings.backup.maxRetryCount < 0 || settings.backup.maxRetryCount > 50) {
      errors.add('Backup: Maximum retry count must be between 0 and 50.');
    }
    if (settings.backup.overwritePolicy != 'overwrite' &&
        settings.backup.overwritePolicy != 'skip' &&
        settings.backup.overwritePolicy != 'rename') {
      errors.add('Backup: Overwrite policy must be "overwrite", "skip", or "rename".');
    }
    if (settings.backup.duplicatePolicy != 'keep_both' &&
        settings.backup.duplicatePolicy != 'replace' &&
        settings.backup.duplicatePolicy != 'ask') {
      errors.add('Backup: Duplicate policy must be "keep_both", "replace", or "ask".');
    }
    if (settings.backup.backupOrganizationMode != 'mirror' &&
        settings.backup.backupOrganizationMode != 'smart' &&
        settings.backup.backupOrganizationMode != 'hybrid') {
      errors.add('Backup: Backup organization mode must be "mirror", "smart", or "hybrid".');
    }

    // Monitoring
    if (settings.monitoring.maxWorkerThreads <= 0 || settings.monitoring.maxWorkerThreads > 64) {
      errors.add('Monitoring: Maximum worker threads must be between 1 and 64.');
    }
    if (settings.monitoring.scanDelayMs < 0 || settings.monitoring.scanDelayMs > 10000) {
      errors.add('Monitoring: Scan delay must be between 0 and 10,000 ms.');
    }
    if (settings.monitoring.eventQueueSize <= 0 || settings.monitoring.eventQueueSize > 50000) {
      errors.add('Monitoring: Event queue size must be between 1 and 50,000.');
    }
    if (settings.monitoring.folderScanIntervalSecs < 5) {
      errors.add('Monitoring: Folder scan interval must be at least 5 seconds.');
    }

    // Restore
    if (settings.restore.defaultRestoreFolder.isNotEmpty) {
      final path = settings.restore.defaultRestoreFolder.trim();
      if (Platform.isWindows) {
        final hasDrivePattern = RegExp(r'^[a-zA-Z]:\\');
        if (!hasDrivePattern.hasMatch(path)) {
          errors.add('Restore: Default restore folder must be a valid Windows path.');
        }
      }
    }
    if (settings.restore.conflictPolicy != 'overwrite' &&
        settings.restore.conflictPolicy != 'skip' &&
        settings.restore.conflictPolicy != 'rename') {
      errors.add('Restore: Conflict policy must be "overwrite", "skip", or "rename".');
    }

    // Performance
    if (settings.performance.cpuLimitPercent < 10 || settings.performance.cpuLimitPercent > 100) {
      errors.add('Performance: CPU Limit must be between 10% and 100%.');
    }
    if (settings.performance.ramLimitMb < 64 || settings.performance.ramLimitMb > 65536) {
      errors.add('Performance: RAM Limit must be between 64 MB and 65,536 MB.');
    }
    if (settings.performance.threadLimit < 1 || settings.performance.threadLimit > 64) {
      errors.add('Performance: Thread Limit must be between 1 and 64.');
    }
    if (settings.performance.maxParallelJobs < 1 || settings.performance.maxParallelJobs > 32) {
      errors.add('Performance: Maximum parallel jobs must be between 1 and 32.');
    }
    if (settings.performance.fileBufferSizeKb < 4 || settings.performance.fileBufferSizeKb > 16384) {
      errors.add('Performance: File buffer size must be between 4 KB and 16,384 KB.');
    }

    // Storage
    if (settings.storage.minimumFreeSpaceGb < 1 || settings.storage.minimumFreeSpaceGb > 10000) {
      errors.add('Storage: Minimum free space must be between 1 GB and 10,000 GB.');
    }

    return errors;
  }
}
