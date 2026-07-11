import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../../../core/services/platform_info.dart';

class WindowsPlatformInfo implements PlatformInfo {
  @override
  String get platformName => 'Windows';

  @override
  bool get isWindows => true;

  @override
  bool get isAndroid => false;

  @override
  bool get isRunningOnBattery {
    if (!Platform.isWindows) return false;
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      if (GetSystemPowerStatus(status) != 0) {
        return status.ref.ACLineStatus == 0; // 0 means offline (on battery)
      }
    } catch (_) {} finally {
      calloc.free(status);
    }
    return false;
  }

  @override
  bool get isCharging {
    if (!Platform.isWindows) return false;
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      final result = GetSystemPowerStatus(status);
      if (result != 0) {
        return status.ref.ACLineStatus == 1 || (status.ref.BatteryFlag & 8 != 0);
      }
    } catch (_) {} finally {
      calloc.free(status);
    }
    return false;
  }

  @override
  int get batteryLevel {
    if (!Platform.isWindows) return 100;
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      final result = GetSystemPowerStatus(status);
      if (result != 0 && status.ref.BatteryLifePercent != 255) {
        return status.ref.BatteryLifePercent;
      }
    } catch (_) {} finally {
      calloc.free(status);
    }
    return 100;
  }

  @override
  double get systemIdleSeconds {
    if (!Platform.isWindows) return 0.0;
    final lastInput = calloc<LASTINPUTINFO>();
    try {
      lastInput.ref.cbSize = sizeOf<LASTINPUTINFO>();
      if (GetLastInputInfo(lastInput) != 0) {
        final lastInputTicks = lastInput.ref.dwTime;
        final systemTicks = GetTickCount();
        final idleMs = systemTicks - lastInputTicks;
        return idleMs / 1000.0;
      }
    } catch (_) {} finally {
      calloc.free(lastInput);
    }
    return 0.0;
  }

  @override
  bool get isFullScreenActive {
    if (!Platform.isWindows) return false;
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) return false;
    final rect = calloc<RECT>();
    try {
      if (GetWindowRect(hwnd, rect) != 0) {
        final width = rect.ref.right - rect.ref.left;
        final height = rect.ref.bottom - rect.ref.top;
        final screenWidth = GetSystemMetrics(SM_CXSCREEN);
        final screenHeight = GetSystemMetrics(SM_CYSCREEN);
        return width >= screenWidth && height >= screenHeight;
      }
    } catch (_) {} finally {
      calloc.free(rect);
    }
    return false;
  }

  @override
  Set<String> getLogicalDrives() {
    final drives = <String>{};
    if (!Platform.isWindows) return drives;

    try {
      final bufferSize = GetLogicalDriveStrings(0, nullptr);
      if (bufferSize == 0) return drives;

      final buffer = calloc<Uint16>(bufferSize);
      try {
        final result = GetLogicalDriveStrings(bufferSize, buffer.cast<Utf16>());
        if (result != 0) {
          final driveStrings = buffer.cast<Utf16>().toDartString();
          int offset = 0;
          while (offset < driveStrings.length) {
            final drive = driveStrings.substring(offset).split('\x00').first;
            if (drive.isNotEmpty) {
              drives.add(drive);
              offset += drive.length + 1;
            } else {
              break;
            }
          }
        }
      } finally {
        free(buffer);
      }
    } catch (_) {}
    return drives;
  }

  static double _lastSysIdle = 0.0;
  static double _lastSysKernel = 0.0;
  static double _lastSysUser = 0.0;

  @override
  double get cpuUsage {
    if (!Platform.isWindows) return 24.0;
    final idleTime = calloc<FILETIME>();
    final kernelTime = calloc<FILETIME>();
    final userTime = calloc<FILETIME>();

    try {
      final result = GetSystemTimes(idleTime, kernelTime, userTime);
      if (result == 0) return 24.0;

      final idle = _fileTimeToDouble(idleTime.ref);
      final kernel = _fileTimeToDouble(kernelTime.ref);
      final user = _fileTimeToDouble(userTime.ref);

      if (_lastSysIdle == 0.0) {
        _lastSysIdle = idle;
        _lastSysKernel = kernel;
        _lastSysUser = user;
        return 24.0;
      }

      final idleDiff = idle - _lastSysIdle;
      final kernelDiff = kernel - _lastSysKernel;
      final userDiff = user - _lastSysUser;

      _lastSysIdle = idle;
      _lastSysKernel = kernel;
      _lastSysUser = user;

      final sysDiff = kernelDiff + userDiff;
      if (sysDiff == 0) return 0.0;

      final cpu = ((sysDiff - idleDiff) * 100.0) / sysDiff;
      return cpu.clamp(0.0, 100.0);
    } catch (_) {
      return 24.0;
    } finally {
      calloc.free(idleTime);
      calloc.free(kernelTime);
      calloc.free(userTime);
    }
  }

  static double _fileTimeToDouble(FILETIME ft) {
    return (ft.dwHighDateTime.toDouble() * 4294967296.0) + ft.dwLowDateTime.toDouble();
  }

  @override
  String getDriveType(String drivePath) {
    if (!Platform.isWindows) return 'Unknown';
    try {
      final pathPtr = drivePath.toNativeUtf16();
      try {
        final type = GetDriveType(pathPtr);
        switch (type) {
          case DRIVE_REMOVABLE:
            return 'Removable';
          case DRIVE_FIXED:
            return 'Fixed';
          case DRIVE_REMOTE:
            return 'Network';
          case DRIVE_CDROM:
            return 'CD-ROM';
          case DRIVE_RAMDISK:
            return 'RAM Disk';
          default:
            return 'Unknown';
        }
      } finally {
        free(pathPtr);
      }
    } catch (_) {}
    return 'Unknown';
  }
}
