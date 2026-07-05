import 'dart:io';
import 'package:path/path.dart' as p;

class PortableManager {
  /// Check if the application is running in Portable Mode
  Future<bool> isPortableMode() async {
    final exeDir = await getExecutableDirectory();
    final lockFile = File(p.join(exeDir, 'portable.lock'));
    return await lockFile.exists();
  }

  /// Toggle Portable Mode by writing/deleting a lock file beside the executable
  Future<void> setPortableMode(bool enable) async {
    final exeDir = await getExecutableDirectory();
    final lockFile = File(p.join(exeDir, 'portable.lock'));
    if (enable) {
      if (!await lockFile.exists()) {
        await lockFile.writeAsString('BackupVault Portable Mode Enabled');
      }
    } else {
      if (await lockFile.exists()) {
        await lockFile.delete();
      }
    }
  }

  /// Check if this is the first execution in the current folder
  Future<bool> detectFirstRun() async {
    final exeDir = await getExecutableDirectory();
    final settingsFile = File(p.join(exeDir, 'portable_settings.json'));
    return !await settingsFile.exists();
  }

  /// Retrieve the containing folder path of the executable
  Future<String> getExecutableDirectory() async {
    try {
      // In a compiled Flutter app, Platform.resolvedExecutable returns the exe path.
      final exePath = Platform.resolvedExecutable;
      return p.dirname(exePath);
    } catch (_) {
      // Fallback to local working directory during test environments
      return Directory.current.path;
    }
  }

  /// Create a portable configuration backup package zip structure (simulated)
  Future<String> packagePortableZip(String buildPath) async {
    final exeDir = await getExecutableDirectory();
    final zipFile = File(p.join(exeDir, 'BackupVault_portable.zip'));
    if (!await zipFile.exists()) {
      await zipFile.writeAsString('BackupVault Portable Executable and configuration bundle.');
    }
    return zipFile.path;
  }
}
