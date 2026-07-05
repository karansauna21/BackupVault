import 'dart:io';
import 'folder_models.dart';
import 'folder_rule_engine.dart';

class FolderScanner {
  final String path;
  final FolderRules rules;

  FolderScanner({required this.path, required this.rules});

  Future<FolderScanResult> scan() async {
    final rootDir = Directory(path);
    if (!await rootDir.exists()) {
      return FolderScanResult(
        fileCount: 0,
        totalSize: 0,
        lastScanTime: DateTime.now(),
        paths: [],
      );
    }

    final ruleEngine = FolderRuleEngine(rules);
    int fileCount = 0;
    int totalSize = 0;
    final List<String> paths = [];

    try {
      await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
        // Enforce safety limit if specified
        if (rules.maxFileCount != null && fileCount >= rules.maxFileCount!) {
          break;
        }

        if (entity is File) {
          final parentDir = Directory(entity.parent.path);
          if (ruleEngine.evaluateDirectory(path, parentDir) && ruleEngine.evaluateFile(path, entity)) {
            fileCount++;
            try {
              totalSize += await entity.length();
            } catch (_) {}
            paths.add(entity.path);
          }
        }
      }
    } catch (_) {
      // Catch access errors on system folders
    }

    return FolderScanResult(
      fileCount: fileCount,
      totalSize: totalSize,
      lastScanTime: DateTime.now(),
      paths: paths,
    );
  }
}

class FolderScanResult {
  final int fileCount;
  final int totalSize;
  final DateTime lastScanTime;
  final List<String> paths;

  FolderScanResult({
    required this.fileCount,
    required this.totalSize,
    required this.lastScanTime,
    required this.paths,
  });
}
