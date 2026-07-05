import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class SettingsDatabase {
  Database? _db;
  String? _dbPath;
  final bool isInMemory;

  SettingsDatabase({this.isInMemory = false});

  String? get dbPath => _dbPath;

  Future<void> init() async {
    if (_db != null) return;
    
    if (isInMemory) {
      _dbPath = ':memory:';
      _db = sqlite3.openInMemory();
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(dbFolder.path, 'backup_vault'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final file = File(p.join(dir.path, 'settings.db'));
      _dbPath = file.path;
      _db = sqlite3.open(_dbPath!);
    }
    
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS settings_kv (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  void close() {
    _db?.close();
    _db = null;
  }

  String? getValue(String key) {
    if (_db == null) return null;
    final stmt = _db!.prepare('SELECT value FROM settings_kv WHERE key = ?');
    final results = stmt.select([key]);
    stmt.close();
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  void setValue(String key, String value) {
    if (_db == null) return;
    final stmt = _db!.prepare('''
      INSERT OR REPLACE INTO settings_kv (key, value)
      VALUES (?, ?)
    ''');
    stmt.execute([key, value]);
    stmt.close();
  }

  void clear() {
    if (_db == null) return;
    _db!.execute('DELETE FROM settings_kv');
  }
}
