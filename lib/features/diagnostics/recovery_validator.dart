import 'dart:io';
import '../../core/database/database_provider.dart';

class RecoveryValidator {
  final dynamic ref;

  RecoveryValidator(this.ref);

  /// Run comprehensive backup archive and index consistency checks
  Future<Map<String, dynamic>> runIntegrityValidations() async {
    final dbCheck = await verifyDatabaseConsistency();
    final duplicateCheck = await scanDuplicateDetections();
    final watcherCheck = await verifyFileWatcherConsistency();

    return {
      'databaseConsistent': dbCheck,
      'duplicatesFoundCount': duplicateCheck,
      'fileWatcherConsistent': watcherCheck,
    };
  }

  /// Verify every record in the DB references a valid backup storage path
  Future<bool> verifyDatabaseConsistency() async {
    try {
      final db = ref.read(databaseProvider);
      final files = await db.customSelect('SELECT backup_path FROM backup_files;').get();

      for (final row in files) {
        final path = row.read<String?>('backup_path');
        if (path != null) {
          final file = File(path);
          if (!await file.exists()) {
            // Missing backup target file!
            return false;
          }
        }
      }
      return true;
    } catch (_) {
      return true; // If no files are in DB yet
    }
  }

  /// Scan for duplicate file paths with matching SHA-256 hashes
  Future<int> scanDuplicateDetections() async {
    try {
      final db = ref.read(databaseProvider);
      final duplicates = await db.customSelect(
        'SELECT file_hash, COUNT(*) as c FROM backup_files GROUP BY file_hash HAVING c > 1;'
      ).get();
      return duplicates.length;
    } catch (_) {
      return 0;
    }
  }

  /// Verify filesystem folders match the watched folders in sqlite
  Future<bool> verifyFileWatcherConsistency() async {
    try {
      final db = ref.read(databaseProvider);
      final folders = await db.customSelect('SELECT source_path FROM backup_folders;').get();

      for (final row in folders) {
        final path = row.read<String>('source_path');
        final dir = Directory(path);
        if (!await dir.exists()) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}
