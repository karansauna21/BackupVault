import 'dart:io';
import 'package:path/path.dart' as p;

class PathResolver {
  String getDesktopPath() {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return p.join(userProfile, 'Desktop');
      }
    }
    return Directory.systemTemp.path;
  }

  String getDownloadsPath() {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return p.join(userProfile, 'Downloads');
      }
    }
    return Directory.systemTemp.path;
  }

  String resolveTargetRestorePath({
    required String originalPath,
    required String destinationOption, // 'original', 'custom', 'desktop', 'downloads'
    String? customFolderPath,
  }) {
    if (destinationOption == 'original') {
      return originalPath;
    }

    final filename = p.basename(originalPath);

    if (destinationOption == 'desktop') {
      return p.join(getDesktopPath(), filename);
    }

    if (destinationOption == 'downloads') {
      return p.join(getDownloadsPath(), filename);
    }

    if (destinationOption == 'custom' && customFolderPath != null) {
      return p.join(customFolderPath, filename);
    }

    return originalPath;
  }
}
