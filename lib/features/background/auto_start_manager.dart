import 'dart:io';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AutoStartManager {
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName.isNotEmpty ? packageInfo.appName : 'BackupVault',
        appPath: Platform.resolvedExecutable,
        args: <String>['--minimized', '--startup'],
      );
      _isInitialized = true;
    } catch (_) {
      // Gracefully handle situations where PackageInfo or platform executable lookup fails (e.g. in tests)
    }
  }

  Future<bool> isEnabled() async {
    if (!_isInitialized) await init();
    try {
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> enable() async {
    if (!_isInitialized) await init();
    try {
      return await launchAtStartup.enable();
    } catch (_) {
      return false;
    }
  }

  Future<bool> disable() async {
    if (!_isInitialized) await init();
    try {
      return await launchAtStartup.disable();
    } catch (_) {
      return false;
    }
  }
}
