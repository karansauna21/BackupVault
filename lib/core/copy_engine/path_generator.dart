import 'dart:io';
import 'package:path/path.dart' as p;

class PathGenerator {
  String generateTimestampPath(String backupRoot, String folderName, String relativePath) {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return p.join(backupRoot, year, month, day, folderName, relativePath);
  }

  String getUniqueDuplicatePath(String targetPath) {
    final dir = p.dirname(targetPath);
    final ext = p.extension(targetPath);
    final nameWithoutExt = p.basenameWithoutExtension(targetPath);

    int counter = 1;
    String newPath = targetPath;
    while (File(newPath).existsSync()) {
      newPath = p.join(dir, '${nameWithoutExt}_($counter)$ext');
      counter++;
    }
    return newPath;
  }

  String getVersionedPath(String targetPath, int version) {
    if (version <= 1) return targetPath;
    
    final dir = p.dirname(targetPath);
    final ext = p.extension(targetPath);
    final nameWithoutExt = p.basenameWithoutExtension(targetPath);

    final versionStr = '_v${version - 1}';
    return p.join(dir, '$nameWithoutExt$versionStr$ext');
  }
}
