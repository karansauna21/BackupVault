import 'dart:io';
import 'package:path/path.dart' as p;
import 'folder_models.dart';

class FolderRuleEngine {
  final FolderRules rules;

  const FolderRuleEngine(this.rules);

  bool evaluateFile(String rootPath, File file) {
    try {
      final filePath = file.path;
      final fileName = p.basename(filePath);
      
      // 1. Check empty file rule
      if (rules.ignoreEmpty) {
        final length = file.lengthSync();
        if (length == 0) return false;
      }

      // 2. Check min/max file size rules
      if (rules.minSize != null || rules.maxSize != null) {
        final length = file.lengthSync();
        if (rules.minSize != null && length < rules.minSize!) return false;
        if (rules.maxSize != null && length > rules.maxSize!) return false;
      }

      // 3. Check hidden files rule
      if (!rules.includeHidden) {
        if (fileName.startsWith('.') || _isHiddenWindows(filePath)) {
          return false;
        }
      }

      // 4. Check temporary files rule
      if (rules.ignoreTemp) {
        final nameLower = fileName.toLowerCase();
        if (nameLower.endsWith('.tmp') ||
            nameLower.endsWith('.temp') ||
            nameLower.endsWith('.crdownload') ||
            nameLower.startsWith('~') ||
            nameLower.contains('tmp') ||
            nameLower.contains('temp')) {
          return false;
        }
      }

      // 5. Check system files rule
      if (rules.ignoreSystem) {
        final nameLower = fileName.toLowerCase();
        if (nameLower == 'desktop.ini' ||
            nameLower == 'thumbs.db' ||
            nameLower == '.ds_store' ||
            filePath.contains('System Volume Information') ||
            filePath.contains('\$RECYCLE.BIN')) {
          return false;
        }
      }

      // 6. Check maximum directory depth
      if (rules.maxDepth != null) {
        final depth = _getDepth(rootPath, filePath);
        if (depth > rules.maxDepth!) return false;
      }

      // 7. Check file extension restrictions
      final ext = p.extension(filePath).replaceAll('.', '').toLowerCase();
      
      if (rules.includeExtensions.isNotEmpty) {
        final includes = rules.includeExtensions.map((e) => e.replaceAll('.', '').toLowerCase()).toList();
        if (!includes.contains(ext)) {
          return false;
        }
      }

      if (rules.excludeExtensions.isNotEmpty) {
        final excludes = rules.excludeExtensions.map((e) => e.replaceAll('.', '').toLowerCase()).toList();
        if (excludes.contains(ext)) {
          return false;
        }
      }

      return true;
    } catch (_) {
      // If we fail to read properties (e.g. permission error during sync check), reject
      return false;
    }
  }

  bool evaluateDirectory(String rootPath, Directory dir) {
    final dirPath = dir.path;
    final dirName = p.basename(dirPath);

    // Check depth
    if (rules.maxDepth != null) {
      final depth = _getDepth(rootPath, dirPath);
      if (depth > rules.maxDepth!) return false;
    }

    // Check hidden directory
    if (!rules.includeHidden) {
      if (dirName.startsWith('.') || _isHiddenWindows(dirPath)) {
        return false;
      }
    }

    // Check system directory
    if (rules.ignoreSystem) {
      final nameLower = dirName.toLowerCase();
      if (nameLower == 'system volume information' ||
          nameLower == '\$recycle.bin' ||
          nameLower.startsWith('\$')) {
        return false;
      }
    }

    return true;
  }

  int _getDepth(String rootPath, String targetPath) {
    final relative = p.relative(targetPath, from: rootPath);
    if (relative == '.' || relative.isEmpty) return 0;
    return p.split(relative).length;
  }

  bool _isHiddenWindows(String path) {
    if (!Platform.isWindows) return false;
    try {
      // Just check if name starts with . or is in typical hidden system paths
      final name = p.basename(path);
      return name.startsWith('.') || name.startsWith('\$');
    } catch (_) {
      return false;
    }
  }
}
