import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/logging_service.dart';
import 'settings_models.dart';
import 'settings_provider.dart';
import 'settings_validator.dart';
import '../../core/services/backup_migration_service.dart';

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _initSettings();
    return const SettingsState();
  }

  Future<void> _initSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.init();
    final loaded = await repo.loadSettings();
    state = loaded;
  }

  Future<void> updateGeneralSettings(GeneralSettings general) async {
    final updated = state.copyWith(general: general);
    _validateAndSave(updated, 'General');
  }

  Future<void> updateStartupSettings(StartupSettings startup) async {
    final updated = state.copyWith(startup: startup);
    _validateAndSave(updated, 'Startup');
  }

  Future<void> updateBackupSettings(BackupSettings backup) async {
    final oldMode = state.backup.backupOrganizationMode;
    final newMode = backup.backupOrganizationMode;

    final updated = state.copyWith(backup: backup);
    await _validateAndSave(updated, 'Backup');

    if (oldMode != newMode) {
      final migration = ref.read(backupMigrationServiceProvider);
      // Run migration asynchronously
      migration.migrateAllFolders(oldMode, newMode);
    }
  }

  Future<void> updateMonitoringSettings(MonitoringSettings monitoring) async {
    final updated = state.copyWith(monitoring: monitoring);
    _validateAndSave(updated, 'Monitoring');
  }

  Future<void> updateRestoreSettings(RestoreSettings restore) async {
    final updated = state.copyWith(restore: restore);
    _validateAndSave(updated, 'Restore');
  }

  Future<void> updateNotificationSettings(NotificationSettings notifications) async {
    final updated = state.copyWith(notifications: notifications);
    _validateAndSave(updated, 'Notifications');
  }

  Future<void> updateLoggingSettings(LoggingSettings logging) async {
    final updated = state.copyWith(logging: logging);
    _validateAndSave(updated, 'Logging');
  }

  Future<void> updatePerformanceSettings(PerformanceSettings performance) async {
    final updated = state.copyWith(performance: performance);
    _validateAndSave(updated, 'Performance');
  }

  Future<void> updateSecuritySettings(SecuritySettings security) async {
    final updated = state.copyWith(security: security);
    _validateAndSave(updated, 'Security');
  }

  Future<void> updateStorageSettings(StorageSettings storage) async {
    final updated = state.copyWith(storage: storage);
    _validateAndSave(updated, 'Storage');
  }

  Future<void> resetToDefault() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.resetToDefault();
    state = const SettingsState();
    await ref.read(loggingServiceProvider).warning('Settings', 'Settings reset to default values');
  }

  Future<void> exportSettings(String destinationPath) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.exportSettings(destinationPath);
    await ref.read(loggingServiceProvider).info('Settings', 'Settings configuration exported to: $destinationPath');
  }

  Future<void> importSettings(String sourcePath) async {
    final repo = ref.read(settingsRepositoryProvider);
    final imported = await repo.importSettings(sourcePath);
    
    // Validate the imported settings state
    final errors = SettingsValidator.validate(imported);
    if (errors.isNotEmpty) {
      // Revert to database state if validation fails
      final loaded = await repo.loadSettings();
      state = loaded;
      throw Exception('Import validation failed:\n${errors.join("\n")}');
    }
    
    state = imported;
    await ref.read(loggingServiceProvider).info('Settings', 'Settings configuration imported from: $sourcePath');
  }

  Future<void> backupConfig(String destinationPath) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.backupConfig(destinationPath);
    await ref.read(loggingServiceProvider).info('Settings', 'Settings database backed up to: $destinationPath');
  }

  Future<void> restoreConfig(String sourcePath) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.restoreConfig(sourcePath);
    // Reload state after restore
    final loaded = await repo.loadSettings();
    state = loaded;
    await ref.read(loggingServiceProvider).warning('Settings', 'Settings database restored from: $sourcePath');
  }

  Future<void> _validateAndSave(SettingsState updatedState, String sectionName) async {
    final errors = SettingsValidator.validate(updatedState);
    if (errors.isNotEmpty) {
      throw Exception('Validation errors in $sectionName:\n${errors.join("\n")}');
    }
    state = updatedState;
    await ref.read(settingsRepositoryProvider).saveSettings(updatedState);
    await ref.read(loggingServiceProvider).info('Settings', 'Updated $sectionName settings');
  }
}
