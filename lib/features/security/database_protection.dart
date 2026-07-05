import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/database/app_database.dart';
import 'integrity_manager.dart';

class DatabaseProtection {
  final IntegrityManager integrityManager;

  DatabaseProtection(this.integrityManager);

  /// Get the SQLite database file path
  Future<File> getDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, 'backup_vault', 'backup_vault.db'));
  }

  /// Get the SQLite backup file path
  Future<File> getDatabaseBackupFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, 'backup_vault', 'backup_vault_backup.db'));
  }

  /// Automatically backup database file
  Future<void> backupDatabase() async {
    try {
      final dbFile = await getDatabaseFile();
      if (await dbFile.exists()) {
        final backupFile = await getDatabaseBackupFile();
        await backupFile.parent.create(recursive: true);
        await dbFile.copy(backupFile.path);
      }
    } catch (e) {
      throw Exception('Database backup failed: $e');
    }
  }

  /// Verify SQLite database integrity
  Future<bool> verifyIntegrity(AppDatabase database) async {
    return await integrityManager.verifyDatabaseIntegrity(database);
  }

  /// Restore database from backup file
  Future<void> restoreDatabaseBackup() async {
    try {
      final backupFile = await getDatabaseBackupFile();
      if (!await backupFile.exists()) {
        throw Exception('No database backup file found to restore.');
      }
      final dbFile = await getDatabaseFile();
      await dbFile.parent.create(recursive: true);
      
      // Copy backup file back to primary path
      await backupFile.copy(dbFile.path);
    } catch (e) {
      throw Exception('Database recovery failed: $e');
    }
  }
}
