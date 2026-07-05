import 'dart:io';
import 'package:path/path.dart' as p;

class ConflictResolver {
  String resolveConflict(String targetPath) {
    if (!File(targetPath).existsSync()) {
      return targetPath;
    }

    final dir = p.dirname(targetPath);
    final ext = p.extension(targetPath);
    final baseName = p.basenameWithoutExtension(targetPath);

    int counter = 1;
    String uniquePath = targetPath;
    while (File(uniquePath).existsSync()) {
      uniquePath = p.join(dir, '${baseName}_(restored_$counter)$ext');
      counter++;
    }
    return uniquePath;
  }
}
