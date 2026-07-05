import 'dart:io';

class RestoreValidator {
  Future<bool> validateSource(String sourceBackupPath) async {
    return File(sourceBackupPath).exists();
  }

  Future<bool> validateDestination(String targetRestorePath) async {
    final parentPath = Directory(targetRestorePath).parent.path;
    final parentDir = Directory(parentPath);
    if (await parentDir.exists()) {
      try {
        final tempFile = File('${parentDir.path}/.restore_write_test');
        await tempFile.writeAsString('');
        await tempFile.delete();
        return true;
      } catch (_) {
        return false;
      }
    } else {
      try {
        await parentDir.create(recursive: true);
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
