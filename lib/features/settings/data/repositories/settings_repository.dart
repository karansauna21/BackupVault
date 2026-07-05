import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/app_settings.dart';

class SettingsRepository {
  final SettingsDao _dao;

  SettingsRepository(this._dao);

  Future<AppSettings> loadSettings() async {
    try {
      final dbSetting = await _dao.getSettings();
      if (dbSetting != null) {
        return AppSettings(
          themeMode: dbSetting.themeMode,
          defaultDestinationPath: dbSetting.defaultDestinationPath,
          autoBackupEnabled: dbSetting.autoBackupEnabled,
          backupInterval: dbSetting.backupInterval,
          notifyOnSuccess: dbSetting.notifyOnSuccess,
          notifyOnFailure: dbSetting.notifyOnFailure,
        );
      }
    } catch (_) {
      // In case of database error, return default settings
    }
    return AppSettings.defaultSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final dbSetting = await _dao.getSettings();
      if (dbSetting != null) {
        // Update existing row
        final updatedSetting = Setting(
          id: dbSetting.id,
          autoStart: settings.autoBackupEnabled,
          darkMode: settings.themeMode == 'dark',
          notifications: settings.notifyOnSuccess || settings.notifyOnFailure,
          verifyHash: dbSetting.verifyHash,
          versioningEnabled: dbSetting.versioningEnabled,
          backupMode: dbSetting.backupMode,
          language: dbSetting.language,
          defaultDestinationPath: settings.defaultDestinationPath,
          themeMode: settings.themeMode,
          autoBackupEnabled: settings.autoBackupEnabled,
          backupInterval: settings.backupInterval,
          notifyOnSuccess: settings.notifyOnSuccess,
          notifyOnFailure: settings.notifyOnFailure,
        );
        await _dao.updateSettings(updatedSetting);
      } else {
        // Insert new row
        final companion = SettingsCompanion.insert(
          autoStart: Value(settings.autoBackupEnabled),
          darkMode: Value(settings.themeMode == 'dark'),
          notifications: Value(settings.notifyOnSuccess || settings.notifyOnFailure),
          verifyHash: const Value(true),
          versioningEnabled: const Value(true),
          backupMode: const Value('incremental'),
          language: const Value('en'),
          defaultDestinationPath: Value(settings.defaultDestinationPath),
          themeMode: Value(settings.themeMode),
          autoBackupEnabled: Value(settings.autoBackupEnabled),
          backupInterval: Value(settings.backupInterval),
          notifyOnSuccess: Value(settings.notifyOnSuccess),
          notifyOnFailure: Value(settings.notifyOnFailure),
        );
        await _dao.insertSettings(companion);
      }
    } catch (_) {
      // Handle error in production logging if needed
    }
  }
}
