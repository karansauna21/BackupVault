import 'dart:io';
import '../../core/services/platform_info.dart';
import '../../core/services/storage_provider.dart';
import '../models/scheduler_models.dart';
import '../../core/database/app_database.dart';

class RuleCheckResult {
  final bool isAllowed;
  final String? reason;

  const RuleCheckResult({required this.isAllowed, this.reason});
}

class RuleEngine {
  final PlatformInfo _platformInfo;
  final StorageProvider _storageProvider;

  RuleEngine(this._platformInfo, this._storageProvider);

  // Simulator or cached values for system state
  static bool useSimulationMode = false;
  static double _simulatedCpuUsage = 24.0;
  static bool _gamingModeActive = false;
  static int _simulatedBatteryLevel = 85;
  static bool _simulatedIsCharging = true;

  double get cpuUsage => useSimulationMode ? _simulatedCpuUsage : _platformInfo.cpuUsage;
  static bool get gamingMode => _gamingModeActive;
  int get batteryLevel => useSimulationMode ? _simulatedBatteryLevel : _platformInfo.batteryLevel;
  bool get isCharging => useSimulationMode ? _simulatedIsCharging : _platformInfo.isCharging;

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
      final diskSpace = await _storageProvider.getDiskFreeSpace(folder.destinationPath);
      if (diskSpace != null && diskSpace['total'] != null && diskSpace['total']! > 0) {
        final freeGb = diskSpace['free']! / (1024 * 1024 * 1024);
        final freePercent = (diskSpace['free']! / diskSpace['total']!) * 100;
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
      final idleSec = useSimulationMode ? 350.0 : _platformInfo.systemIdleSeconds;
      if (idleSec < 300) {
        return RuleCheckResult(
          isAllowed: false,
          reason: 'Blocked: System is active (idle for only ${idleSec.toStringAsFixed(0)} seconds).',
        );
      }
    }

    // 11: Pause during full screen apps
    if (rules.pauseDuringFullScreenApps && (useSimulationMode ? false : _platformInfo.isFullScreenActive)) {
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
}
