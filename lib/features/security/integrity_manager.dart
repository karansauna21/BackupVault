import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../core/database/app_database.dart';

class IntegrityManager {
  /// Calculate SHA-256 hash of a file
  Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found for hash calculation: $filePath');
    }
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify calculated file hash matches expected hash signature
  Future<bool> verifyFileIntegrity(String filePath, String expectedHash) async {
    try {
      final calculated = await calculateFileHash(filePath);
      return calculated == expectedHash;
    } catch (_) {
      return false;
    }
  }

  /// Execute PRAGMA integrity_check on AppDatabase
  Future<bool> verifyDatabaseIntegrity(AppDatabase database) async {
    try {
      final result = await database.customSelect('PRAGMA integrity_check;').get();
      if (result.isNotEmpty) {
        final val = result.first.data['integrity_check'] as String? ?? '';
        return val.toLowerCase() == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
