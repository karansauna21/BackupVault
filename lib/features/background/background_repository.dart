import 'dart:convert';
import '../settings/settings_database.dart';
import 'background_models.dart';

class BackgroundRepository {
  final SettingsDatabase _settingsDb;

  BackgroundRepository(this._settingsDb);

  Future<void> init() async {
    await _settingsDb.init();
  }

  Future<WindowState> loadWindowState() async {
    try {
      final jsonStr = _settingsDb.getValue('window_state');
      if (jsonStr != null) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return WindowState(
          width: (map['width'] as num?)?.toDouble() ?? 1000,
          height: (map['height'] as num?)?.toDouble() ?? 700,
          x: (map['x'] as num?)?.toDouble(),
          y: (map['y'] as num?)?.toDouble(),
          isVisible: map['isVisible'] as bool? ?? true,
          isMinimized: map['isMinimized'] as bool? ?? false,
          isMaximized: map['isMaximized'] as bool? ?? false,
        );
      }
    } catch (_) {}
    return const WindowState();
  }

  Future<void> saveWindowState(WindowState state) async {
    final map = {
      'width': state.width,
      'height': state.height,
      'x': state.x,
      'y': state.y,
      'isVisible': state.isVisible,
      'isMinimized': state.isMinimized,
      'isMaximized': state.isMaximized,
    };
    _settingsDb.setValue('window_state', json.encode(map));
  }

  Future<StartupState> loadStartupState() async {
    try {
      final jsonStr = _settingsDb.getValue('startup_state');
      if (jsonStr != null) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return StartupState(
          isEnabled: map['isEnabled'] as bool? ?? false,
          startMinimized: map['startMinimized'] as bool? ?? false,
          startInSystemTray: map['startInSystemTray'] as bool? ?? false,
          restorePreviousSession: map['restorePreviousSession'] as bool? ?? false,
          startupDelaySeconds: map['startupDelaySeconds'] as int? ?? 0,
          isDelayActive: false,
        );
      }
    } catch (_) {}
    return const StartupState();
  }

  Future<void> saveStartupState(StartupState state) async {
    final map = {
      'isEnabled': state.isEnabled,
      'startMinimized': state.startMinimized,
      'startInSystemTray': state.startInSystemTray,
      'restorePreviousSession': state.restorePreviousSession,
      'startupDelaySeconds': state.startupDelaySeconds,
    };
    _settingsDb.setValue('startup_state', json.encode(map));
  }

  Future<List<Map<String, dynamic>>> loadPendingQueue() async {
    try {
      final jsonStr = _settingsDb.getValue('pending_backup_queue');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> savePendingQueue(List<Map<String, dynamic>> queue) async {
    _settingsDb.setValue('pending_backup_queue', json.encode(queue));
  }

  Future<List<Map<String, dynamic>>> loadPendingRestoreQueue() async {
    try {
      final jsonStr = _settingsDb.getValue('pending_restore_queue');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> savePendingRestoreQueue(List<Map<String, dynamic>> queue) async {
    _settingsDb.setValue('pending_restore_queue', json.encode(queue));
  }
}
