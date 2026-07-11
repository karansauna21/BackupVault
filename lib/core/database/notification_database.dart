import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class NotificationDatabase {
  Database? _db;
  String? _dbPath;
  final bool isInMemory;

  NotificationDatabase({this.isInMemory = false});

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

      final file = File(p.join(dir.path, 'notifications.db'));
      _dbPath = file.path;
      _db = sqlite3.open(_dbPath!);
    }

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS notification_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        message TEXT NOT NULL,
        action TEXT,
        source TEXT,
        destination TEXT,
        status TEXT,
        worker TEXT,
        related_backup_id INTEGER,
        is_read INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0
      )
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS notification_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  void close() {
    _db?.close();
    _db = null;
  }

  String? getSetting(String key) {
    if (_db == null) return null;
    final stmt = _db!.prepare('SELECT value FROM notification_settings WHERE key = ?');
    final results = stmt.select([key]);
    stmt.close();
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  void setSetting(String key, String value) {
    if (_db == null) return;
    final stmt = _db!.prepare('''
      INSERT OR REPLACE INTO notification_settings (key, value)
      VALUES (?, ?)
    ''');
    stmt.execute([key, value]);
    stmt.close();
  }

  int insertNotification(Map<String, dynamic> data) {
    if (_db == null) return -1;
    final stmt = _db!.prepare('''
      INSERT INTO notification_logs (
        timestamp, priority, category, message, action, source, destination, status, worker, related_backup_id, is_read, is_pinned
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      data['timestamp'],
      data['priority'],
      data['category'],
      data['message'],
      data['action'],
      data['source'],
      data['destination'],
      data['status'],
      data['worker'],
      data['relatedBackupId'],
      data['isRead'] ?? 0,
      data['isPinned'] ?? 0,
    ]);
    stmt.close();
    return _db!.lastInsertRowId;
  }

  List<Map<String, dynamic>> getAllNotifications() {
    if (_db == null) return [];
    final ResultSet results = _db!.select('SELECT * FROM notification_logs ORDER BY id DESC');
    return results.map((row) => {
      'id': row['id'] as int,
      'timestamp': row['timestamp'] as String,
      'priority': row['priority'] as String,
      'category': row['category'] as String,
      'message': row['message'] as String,
      'action': row['action'] as String?,
      'source': row['source'] as String?,
      'destination': row['destination'] as String?,
      'status': row['status'] as String?,
      'worker': row['worker'] as String?,
      'relatedBackupId': row['related_backup_id'] as int?,
      'isRead': row['is_read'] as int? ?? 0,
      'isPinned': row['is_pinned'] as int? ?? 0,
    }).toList();
  }

  void markAsRead(int id, bool isRead) {
    if (_db == null) return;
    final stmt = _db!.prepare('UPDATE notification_logs SET is_read = ? WHERE id = ?');
    stmt.execute([isRead ? 1 : 0, id]);
    stmt.close();
  }

  void markAllAsRead() {
    if (_db == null) return;
    _db!.execute('UPDATE notification_logs SET is_read = 1');
  }

  void setPinned(int id, bool isPinned) {
    if (_db == null) return;
    final stmt = _db!.prepare('UPDATE notification_logs SET is_pinned = ? WHERE id = ?');
    stmt.execute([isPinned ? 1 : 0, id]);
    stmt.close();
  }

  void deleteNotification(int id) {
    if (_db == null) return;
    final stmt = _db!.prepare('DELETE FROM notification_logs WHERE id = ?');
    stmt.execute([id]);
    stmt.close();
  }

  void deleteAllNotifications() {
    if (_db == null) return;
    _db!.execute('DELETE FROM notification_logs');
  }
}
