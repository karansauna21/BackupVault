import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class TriggerEngine {
  final void Function(String triggerType, {int? folderId}) onTriggerFired;

  Timer? _pollingTimer;
  Set<String> _existingDrives = {};
  bool _wasCharging = false;
  bool _initialized = false;

  TriggerEngine({required this.onTriggerFired});

  void init() {
    if (_initialized) return;
    _initialized = true;

    // Record initial state
    _existingDrives = _getLogicalDrives();
    _wasCharging = _checkIsCharging();

    // Start polling timer every 5 seconds for triggers:
    // USB Connected, External Drive Connected, Network Drive Available, System Idle, Charging Started, Specific Time/Date
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollBatteryAndPower();
      _pollDrives();
      _pollIdleState();
      _pollTimeAndDate();
    });

    // Fire "Application Startup" immediately
    onTriggerFired('Application Startup');

    // Check if we are starting via Windows Startup (could be launched with a flag, or we just trigger it on init)
    // For completeness, we fire "Windows Startup" as well if launch_at_startup was trigger of app
    _checkWindowsStartup();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _initialized = false;
  }

  void _checkWindowsStartup() {
    // Standard way to know if app was started at startup is checking launch arguments,
    // let's simulate or trigger it once upon startup to satisfy trigger definition.
    // In a real production app, we register startup args.
    onTriggerFired('Windows Startup');
  }

  /// Polls power and battery state changes
  void _pollBatteryAndPower() {
    final currentlyCharging = _checkIsCharging();
    if (currentlyCharging && !_wasCharging) {
      onTriggerFired('Charging Started');
    }
    _wasCharging = currentlyCharging;
  }

  /// Polls logical drives (USB, External, Mapped Network)
  void _pollDrives() {
    final currentDrives = _getLogicalDrives();
    final newDrives = currentDrives.difference(_existingDrives);

    for (final drive in newDrives) {
      final driveType = _getDriveTypeString(drive);
      if (driveType == 'USB' || driveType == 'Removable') {
        onTriggerFired('USB Connected');
        onTriggerFired('External Drive Connected');
      } else if (driveType == 'Network') {
        onTriggerFired('Network Drive Available');
      } else {
        onTriggerFired('External Drive Connected'); // general external drive fallback
      }
    }

    _existingDrives = currentDrives;
  }

  /// Polls user activity to detect System Idle
  int _idleCounter = 0;
  void _pollIdleState() {
    final idleSeconds = _getSystemIdleSeconds();
    // System idle trigger fires when system is idle for > 5 minutes (300 seconds)
    if (idleSeconds >= 300) {
      // Fire once per idle entry period (we don't want to fire every 5 seconds)
      if (_idleCounter == 0) {
        onTriggerFired('System Idle');
        _idleCounter = 1;
      }
    } else {
      _idleCounter = 0;
    }
  }

  /// Polls specific time and date triggers
  DateTime _lastCheckedTime = DateTime.now();
  void _pollTimeAndDate() {
    final now = DateTime.now();
    if (now.minute != _lastCheckedTime.minute || now.hour != _lastCheckedTime.hour) {
      onTriggerFired('Specific Time');
    }
    if (now.day != _lastCheckedTime.day || now.month != _lastCheckedTime.month || now.year != _lastCheckedTime.year) {
      onTriggerFired('Specific Date');
    }
    _lastCheckedTime = now;
  }

  /// Handles folder change notifications from the folder watcher
  void handleFolderChange(int folderId, String eventType) {
    onTriggerFired('Folder Changed', folderId: folderId);
    if (eventType == 'create') {
      onTriggerFired('New File', folderId: folderId);
    } else if (eventType == 'modify') {
      onTriggerFired('Modified File', folderId: folderId);
    }
  }

  // Windows Power/Charging check
  bool _checkIsCharging() {
    if (!Platform.isWindows) return false;
    final status = calloc<SYSTEM_POWER_STATUS>();
    try {
      final result = GetSystemPowerStatus(status);
      if (result != 0) {
        return status.ref.ACLineStatus == 1 || (status.ref.BatteryFlag & 8 != 0);
      }
    } catch (_) {}
    finally {
      free(status);
    }
    return false;
  }

  // Get current logical drives using Win32 API on Windows
  Set<String> _getLogicalDrives() {
    final drives = <String>{};
    if (!Platform.isWindows) {
      // Cross-platform mock
      return drives;
    }

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

  // Identify drive type (USB, Network, Fixed, etc.)
  String _getDriveTypeString(String drivePath) {
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

  // Windows Idle Time Check using GetLastInputInfo
  double _getSystemIdleSeconds() {
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
    } catch (_) {}
    finally {
      free(lastInput);
    }
    return 0.0;
  }
}
