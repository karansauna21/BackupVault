import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_settings.dart';
import '../../data/repositories/settings_repository.dart';

import '../../../../core/database/database_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db.settingsDao);
});

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettings();
    return AppSettings.defaultSettings();
  }

  Future<void> _loadSettings() async {
    final repository = ref.read(settingsRepositoryProvider);
    final settings = await repository.loadSettings();
    state = settings;
  }

  Future<void> updateThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    state = updated;
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateDefaultDestinationPath(String path) async {
    final updated = state.copyWith(defaultDestinationPath: path);
    state = updated;
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateAutoBackupEnabled(bool enabled) async {
    final updated = state.copyWith(autoBackupEnabled: enabled);
    state = updated;
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateBackupInterval(String interval) async {
    final updated = state.copyWith(backupInterval: interval);
    state = updated;
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateNotifyOnSuccess(bool notify) async {
    final updated = state.copyWith(notifyOnSuccess: notify);
    state = updated;
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateNotifyOnFailure(bool notify) async {
    final updated = state.copyWith(notifyOnFailure: notify);
    state = updated;
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
