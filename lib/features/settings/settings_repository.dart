import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'settings_database.dart';
import 'settings_models.dart';

class SettingsRepository {
  final SettingsDatabase _database;

  SettingsRepository(this._database);

  String? get dbPath => _database.dbPath;

  Future<void> init() async {
    await _database.init();
  }

  Future<SettingsState> loadSettings() async {
    try {
      final jsonStr = _database.getValue('settings_state');
      if (jsonStr != null) {
        final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
        return SettingsState.fromJson(jsonMap);
      }
    } catch (_) {
      // Return default on failure/corrupt data
    }
    return const SettingsState();
  }

  Future<void> saveSettings(SettingsState settings) async {
    final jsonStr = json.encode(settings.toJson());
    _database.setValue('settings_state', jsonStr);
  }

  Future<void> resetToDefault() async {
    _database.clear();
    await saveSettings(const SettingsState());
  }

  Future<void> exportSettings(String destinationPath) async {
    final settings = await loadSettings();
    final jsonString = const JsonEncoder.withIndent('  ').convert(settings.toJson());
    
    String targetPath = destinationPath;
    if (FileSystemEntity.isDirectorySync(destinationPath)) {
      targetPath = p.join(destinationPath, 'backup_vault_settings.json');
    }
    
    // Ensure parent dir exists
    final file = File(targetPath);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    
    await file.writeAsString(jsonString);
  }

  Future<SettingsState> importSettings(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Source settings file does not exist');
    }
    
    final content = await file.readAsString();
    final jsonMap = json.decode(content) as Map<String, dynamic>;
    final settings = SettingsState.fromJson(jsonMap);
    await saveSettings(settings);
    return settings;
  }

  Future<void> backupConfig(String destinationPath) async {
    final dbPath = _database.dbPath;
    if (dbPath == null) throw Exception('Database not initialized');
    
    final file = File(dbPath);
    if (!await file.exists()) {
      throw Exception('Database file does not exist');
    }
    
    String targetPath = destinationPath;
    if (FileSystemEntity.isDirectorySync(destinationPath)) {
      targetPath = p.join(destinationPath, 'settings_backup.db');
    }
    
    final targetFile = File(targetPath);
    final parentDir = targetFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    
    await file.copy(targetPath);
  }

  Future<void> restoreConfig(String sourcePath) async {
    final dbPath = _database.dbPath;
    if (dbPath == null) throw Exception('Database not initialized');
    
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Source database file does not exist');
    }
    
    // Close the database to release the file handle
    _database.close();
    
    try {
      await file.copy(dbPath);
    } finally {
      // Re-initialize database connection
      await _database.init();
    }
  }
}
