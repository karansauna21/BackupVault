import '../../../core/services/platform_info.dart';

class AndroidPlatformInfo implements PlatformInfo {
  @override
  String get platformName => 'Android';

  @override
  bool get isWindows => false;

  @override
  bool get isAndroid => true;

  @override
  bool get isRunningOnBattery => false;

  @override
  bool get isCharging => true;

  @override
  int get batteryLevel => 100;

  @override
  double get systemIdleSeconds => 0.0;

  @override
  bool get isFullScreenActive => false;
  
  @override
  double get cpuUsage => 5.0; // Sensible default for mobile CPU load during idle check

  @override
  Set<String> getLogicalDrives() => {};

  @override
  String getDriveType(String drivePath) => 'Unknown';
}
