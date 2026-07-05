import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'scheduler_models.dart';
import '../../core/database/app_database.dart';

class RuleCheckResult {
  final bool isAllowed;
  final String? reason;

  const RuleCheckResult({required this.isAllowed, this.reason});
}

class RuleEngine {
  // Simulator or cached values for system state
  static bool useSimulationMode = false;
  static double _simulatedCpuUsage = 24.0;
  static bool _gamingModeActive = false;
  static int _simulatedBatteryLevel = 85;
  static bool _simulatedIsCharging = true;

  static double get cpuUsage => (Platform.isWindows && !useSimulationMode) ? _getWindowsCpuUsage() : _simulatedCpuUsage;
  static bool get gamingMode => _gamingModeActive;
  static int get batteryLevel => (Platform.isWindows && !useSimulationMode) ? _getWindowsBatteryLevel() : _simulatedBatteryLevel;
  static bool get isCharging => (Platform.isWindows && !useSimulationMode) ? _getWindowsIsCharging() : _simulatedIsCharging;

  static void setSimulatedCpu(double val) => _simulatedCpuUsage = val;
  static void setGamingMode(bool val) => _gamingModeActive = val;
  static void setSimulatedBattery(int val) => _simulatedBatteryLevel = val;
  static void setSimulatedCharging(bool val) => _simulatedIsCharging = val;

  /// Main method to evaluate if a backup task is allowed to run based on rules
  Future<RuleCheckResult> evaluateRules({
    required ScheduleConfig config,
    required BackupFolder folder,
    required List<Map<String, dynamic>> activeJobs,
  }) async {
    final rules = config.rules;

    // Rule 1: Run only if destination is available
    if (rules.runOnlyIfDestinationAvailable) {
      final destDir = Directory(folder.destinationPath);
      if (!await destDir.exists()) {
        return const RuleCheckResult(
          isAllowed: false,
          reason: 'Destination path is not available or disconnected.',
        );
      }
    }

    // Rule 2: Skip duplicate jobs
    if (rules.skipDuplicateJobs) {
      final isAlreadyInQueue = activeJobs.any(
        (job) => job['folderId'] == folder.id && (job['status'] == 'pending' || job['status'] == 'running'),
      );
      if (isAlreadyInQueue) {
        return const RuleCheckResult(
          isAllowed: false,
          reason: 'A backup job for this folder is already in the queue or running.',
        );
      }
    }

    // Rule 3: Skip if backup already completed recently
    if (rules.skipIfBackupAlreadyCompleted) {
      if (folder.lastBackupAt != null) {
        final durationSinceLastBackup = DateTime.now().difference(folder.lastBackupAt!);
        // If completed in last 5 minutes, let's skip
        if (durationSinceLastBackup.inMinutes < 5) {
          return const RuleCheckResult(
            isAllowed: false,
            reason: 'Backup was already completed recently (within 5 minutes).',
          );
        }
      }
    }

    // Rule 4: Pause when CPU usage is high
    if (rules.pauseWhenCpuUsageIsHigh && cpuUsage > 80.0) {
      return RuleCheckResult(
        isAllowed: false,
        reason: 'Paused: CPU usage is too high (${cpuUsage.toStringAsFixed(1)}%).',
      );
    }

    // Rule 5: Pause when storage is full (less than 5% or 1GB free)
    if (rules.pauseWhenStorageIsFull) {
      final diskSpace = await _getFreeDiskSpace(folder.destinationPath);
      if (diskSpace != null) {
        final freeGb = diskSpace['freeBytes']! / (1024 * 1024 * 1024);
        final freePercent = (diskSpace['freeBytes']! / diskSpace['totalBytes']!) * 100;
        if (freeGb < 1.0 || freePercent < 5.0) {
          return RuleCheckResult(
            isAllowed: false,
            reason: 'Paused: Destination storage is nearly full (${freeGb.toStringAsFixed(2)} GB / ${freePercent.toStringAsFixed(1)}% free).',
          );
        }
      }
    }

    // Rule 6: Pause during gaming mode
    if (rules.pauseDuringGamingMode && gamingMode) {
      return const RuleCheckResult(
        isAllowed: false,
        reason: 'Paused: Gaming Mode is active.',
      );
    }

    // Rule 7: Pause when battery is low (less than 20% and not charging)
    if (rules.pauseWhenBatteryIsLow && !isCharging && batteryLevel < 20) {
      return RuleCheckResult(
        isAllowed: false,
        reason: 'Paused: Battery is low ($batteryLevel%) and not charging.',
      );
    }

    // Prompt 17 Rules:
    // 8: Backup only while charging
    if (rules.backupOnlyWhileCharging && !isCharging) {
      return const RuleCheckResult(
        isAllowed: false,
        reason: 'Blocked: Device is not charging.',
      );
    }

    // 9: Pause on Battery
    if (rules.pauseOnBattery && !isCharging) {
      return const RuleCheckResult(
        isAllowed: false,
        reason: 'Paused: System is running on battery power.',
      );
    }

    // 10: Backup only when idle (system idle for >= 5 minutes / 300 seconds)
    if (rules.backupOnlyWhenIdle) {
      final idleSec = _getSystemIdleSecondsForRules();
      if (idleSec < 300) {
        return RuleCheckResult(
          isAllowed: false,
          reason: 'Blocked: System is active (idle for only ${idleSec.toStringAsFixed(0)} seconds).',
        );
      }
    }

    // 11: Pause during full screen apps
    if (rules.pauseDuringFullScreenApps && _isAnyFullScreenWindowActive()) {
      return const RuleCheckResult(
        isAllowed: false,
        reason: 'Paused: Full-screen application is active.',
      );
    }

    // 12: Weekend Only
    final now = DateTime.now();
    if (rules.weekendOnly && (now.weekday != DateTime.saturday && now.weekday != DateTime.sunday)) {
      return const RuleCheckResult(
        isAllowed: false,
        reason: 'Blocked: Weekend Only rule is active.',
      );
    }

    // 13: Weekdays Only
    if (rules.weekdaysOnly && (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday)) {
      return const RuleCheckResult(
        isAllowed: false,
        reason: 'Blocked: Weekdays Only rule is active.',
      );
    }

    // 14: Allowed time range
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (rules.allowedTimeRangeStart != null && rules.allowedTimeRangeEnd != null) {
      if (!_isTimeInRange(timeStr, rules.allowedTimeRangeStart!, rules.allowedTimeRangeEnd!)) {
        return RuleCheckResult(
          isAllowed: false,
          reason: 'Blocked: Current time is outside allowed range (${rules.allowedTimeRangeStart} - ${rules.allowedTimeRangeEnd}).',
        );
      }
    }

    // 15: Blocked time range
    if (rules.blockedTimeRangeStart != null && rules.blockedTimeRangeEnd != null) {
      if (_isTimeInRange(timeStr, rules.blockedTimeRangeStart!, rules.blockedTimeRangeEnd!)) {
        return RuleCheckResult(
          isAllowed: false,
          reason: 'Blocked: Current time is in blocked range (${rules.blockedTimeRangeStart} - ${rules.blockedTimeRangeEnd}).',
        );
      }
    }

    return const RuleCheckResult(isAllowed: true);
  }

  /// Check disk space of a path
  Future<Map<String, int>?> _getFreeDiskSpace(String path) async {
    if (!Platform.isWindows) {
      // Cross-platform placeholder calculation
      return {'freeBytes': 50 * 1024 * 1024 * 1024, 'totalBytes': 500 * 1024 * 1024 * 1024};
    }

    try {
      final pathPtr = path.toNativeUtf16();
      final freeBytesAvailable = calloc<Uint64>();
      final totalNumberOfBytes = calloc<Uint64>();
      final totalNumberOfFreeBytes = calloc<Uint64>();

      try {
        final result = GetDiskFreeSpaceEx(
          pathPtr,
          freeBytesAvailable,
          totalNumberOfBytes,
          totalNumberOfFreeBytes,
        );

        if (result != 0) {
          final free = freeBytesAvailable.value;
          final total = totalNumberOfBytes.value;
          return {
            'freeBytes': free,
            'totalBytes': total,
          };
        }
      } finally {
        free(pathPtr);
        free(freeBytesAvailable);
        free(totalNumberOfBytes);
        free(totalNumberOfFreeBytes);
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }

  // Windows-specific CPU check using GetSystemTimes
  static double _lastSysIdle = 0;
  static double _lastSysKernel = 0;
  static double _lastSysUser = 0;

  static double _getWindowsCpuUsage() {
    final idleTime = calloc<FILETIME>();
    final kernelTime = calloc<FILETIME>();
    final userTime = calloc<FILETIME>();

    try {
      final result = GetSystemTimes(idleTime, kernelTime, userTime);
      if (result == 0) return _simulatedCpuUsage;

      final idle = _fileTimeToDouble(idleTime.ref);
      final kernel = _fileTimeToDouble(kernelTime.ref);
      final user = _fileTimeToDouble(userTime.ref);

      if (_lastSysIdle == 0) {
        _lastSysIdle = idle;
        _lastSysKernel = kernel;
        _lastSysUser = user;
        return _simulatedCpuUsage;
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
      return _simulatedCpuUsage;
    } finally {
      free(idleTime);
      free(kernelTime);
      free(userTime);
    }
  }

  static double _fileTimeToDouble(FILETIME ft) {
    return (ft.dwHighDateTime.toDouble() * 4294967296.0) + ft.dwLowDateTime.toDouble();
  }

  static int _getWindowsBatteryLevel() {
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      final result = GetSystemPowerStatus(status);
      if (result != 0 && status.ref.BatteryLifePercent != 255) {
        return status.ref.BatteryLifePercent;
      }
    } catch (_) {
      // ignored
    } finally {
      free(status);
    }
    return _simulatedBatteryLevel;
  }

  static bool _getWindowsIsCharging() {
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      final result = GetSystemPowerStatus(status);
      if (result != 0) {
        // ACLineStatus == 1 means Online / plugged in
        return status.ref.ACLineStatus == 1 || (status.ref.BatteryFlag & 8 != 0); // charging flag
      }
    } catch (_) {
      // ignored
    } finally {
      free(status);
    }
    return _simulatedIsCharging;
  }

  static bool _isTimeInRange(String current, String start, String end) {
    final currentParts = current.split(':');
    final startParts = start.split(':');
    final endParts = end.split(':');
    if (currentParts.length != 2 || startParts.length != 2 || endParts.length != 2) return true;
    final currMin = int.parse(currentParts[0]) * 60 + int.parse(currentParts[1]);
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    if (startMin <= endMin) {
      return currMin >= startMin && currMin <= endMin;
    } else {
      return currMin >= startMin || currMin <= endMin;
    }
  }

  static double _getSystemIdleSecondsForRules() {
    if (!Platform.isWindows || useSimulationMode) return 350.0;
    final lastInput = calloc<LASTINPUTINFO>();
    try {
      lastInput.ref.cbSize = sizeOf<LASTINPUTINFO>();
      if (GetLastInputInfo(lastInput) != 0) {
        final lastInputTicks = lastInput.ref.dwTime;
        final systemTicks = GetTickCount();
        final idleMs = systemTicks - lastInputTicks;
        return idleMs / 1000.0;
      }
    } catch (_) {}
    finally {
      free(lastInput);
    }
    return 350.0;
  }

  static bool _isAnyFullScreenWindowActive() {
    if (!Platform.isWindows || useSimulationMode) return false;
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
    } catch (_) {}
    finally {
      free(rect);
    }
    return false;
  }
}
