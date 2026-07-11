abstract class PlatformInfo {
  String get platformName;
  bool get isWindows;
  bool get isAndroid;
  bool get isRunningOnBattery;
  bool get isCharging;
  int get batteryLevel;
  double get systemIdleSeconds;
  bool get isFullScreenActive;
  double get cpuUsage;
  Set<String> getLogicalDrives();
  String getDriveType(String drivePath);
}
