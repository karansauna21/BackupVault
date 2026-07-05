import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_database.dart';
import 'settings_models.dart';
import 'settings_repository.dart';
import 'settings_controller.dart';

/// Provider for SettingsDatabase instance
final settingsDatabaseProvider = Provider<SettingsDatabase>((ref) {
  final db = SettingsDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for SettingsRepository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(settingsDatabaseProvider);
  return SettingsRepository(db);
});

/// Provider for the SettingsController which manages the SettingsState
final settingsProvider = NotifierProvider<SettingsController, SettingsState>(() {
  return SettingsController();
});

/// Derived provider exposing the Theme string ('light', 'dark', 'system')
final themeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((s) => s.general.theme));
});

/// Derived provider exposing the Language code ('en', etc.)
final languageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((s) => s.general.language));
});

/// Derived provider exposing the PerformanceState / PerformanceSettings
final performanceStateProvider = Provider<PerformanceSettings>((ref) {
  return ref.watch(settingsProvider.select((s) => s.performance));
});

/// Derived provider exposing the NotificationState / NotificationSettings
final notificationStateProvider = Provider<NotificationSettings>((ref) {
  return ref.watch(settingsProvider.select((s) => s.notifications));
});

/// Derived provider exposing the StorageState / StorageSettings
final storageStateProvider = Provider<StorageSettings>((ref) {
  return ref.watch(settingsProvider.select((s) => s.storage));
});
