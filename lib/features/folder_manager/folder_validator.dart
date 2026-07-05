import 'dart:io';
import 'package:path/path.dart' as p;
import 'folder_models.dart';

class FolderValidator {
  static Future<FolderHealthScore> checkHealth(String sourcePath, String destinationPath) async {
    final List<String> warnings = [];
    bool isReadable = true;
    bool isWritable = true;
    bool pathExists = true;
    bool diskSpaceAvailable = true;
    int score = 100;

    // 1. Check Source path existence
    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) {
      pathExists = false;
      score -= 50;
      warnings.add('Source path does not exist: $sourcePath');
      return FolderHealthScore(
        score: 0,
        isReadable: false,
        isWritable: false,
        pathExists: false,
        diskSpaceAvailable: false,
        warnings: warnings,
      );
    }

    // 2. Check Read test on Source
    try {
      final list = sourceDir.listSync();
      // Try to read first element info if available
      if (list.isNotEmpty) {
        list.first.statSync();
      }
    } catch (e) {
      isReadable = false;
      score -= 30;
      warnings.add('Source path read permission denied: $e');
    }

    // 3. Check Destination path
    if (destinationPath.isNotEmpty) {
      final destDir = Directory(destinationPath);
      if (!await destDir.exists()) {
        score -= 20;
        warnings.add('Destination path does not exist/offline: $destinationPath');
        diskSpaceAvailable = false;
      } else {
        // Try to perform a write check in destination
        try {
          final testFile = File(p.join(destinationPath, '.backup_vault_test_write'));
          await testFile.writeAsString('write_test');
          await testFile.delete();
        } catch (e) {
          isWritable = false;
          score -= 30;
          warnings.add('Destination write check failed: $e');
        }

        // Available disk space warning (check dummy space limits if actual API not available)
        try {
          // Verify if we can read stats or if it's on local disk
          final stat = await destDir.stat();
          if (stat.type == FileSystemEntityType.notFound) {
            diskSpaceAvailable = false;
            score -= 10;
            warnings.add('Destination disk stats unavailable');
          }
        } catch (_) {}
      }
    } else {
      score -= 10;
      warnings.add('No destination path configured');
    }

    return FolderHealthScore(
      score: score.clamp(0, 100),
      isReadable: isReadable,
      isWritable: isWritable,
      pathExists: pathExists,
      diskSpaceAvailable: diskSpaceAvailable,
      warnings: warnings,
    );
  }

  static Future<bool> validatePath(String path) async {
    if (path.trim().isEmpty) return false;
    final dir = Directory(path);
    return dir.exists();
  }

  static Future<int> getFreeSpace(String path) async {
    try {
      if (path.isEmpty) return 0;
      final dir = Directory(path);
      if (!await dir.exists()) return 0;
      
      // On Windows/Linux/macOS, we can estimate free space.
      // For cross-platform stability without external plugins, we return a default high value (e.g. 50GB)
      // or check the directory system stats.
      return 50 * 1024 * 1024 * 1024; // Mock 50 GB free space
    } catch (_) {
      return 0;
    }
  }
}
