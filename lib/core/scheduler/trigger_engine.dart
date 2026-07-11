// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import '../../core/services/platform_info.dart';

class TriggerEngine {
  final void Function(String triggerType, {int? folderId}) onTriggerFired;
  final PlatformInfo _platformInfo;

  Timer? _pollingTimer;
  Set<String> _existingDrives = {};
  bool _wasCharging = false;
  bool _initialized = false;

  // ignore: use_initializing_formals
  TriggerEngine({
    required this.onTriggerFired,
    required PlatformInfo platformInfo,
  }) : _platformInfo = platformInfo;

  void init() {
    if (_initialized) return;
    _initialized = true;

    // Record initial state
    _existingDrives = _getLogicalDrives();
    _wasCharging = _checkIsCharging();

    // Start polling timer every 5 seconds for triggers:
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollBatteryAndPower();
      _pollDrives();
      _pollIdleState();
      _pollTimeAndDate();
    });

    // Fire "Application Startup" immediately
    onTriggerFired('Application Startup');

    _checkWindowsStartup();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _initialized = false;
  }

  void _checkWindowsStartup() {
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
        onTriggerFired('External Drive Connected');
      }
    }

    _existingDrives = currentDrives;
  }

  /// Polls user activity to detect System Idle
  int _idleCounter = 0;
  void _pollIdleState() {
    final idleSeconds = _getSystemIdleSeconds();
    if (idleSeconds >= 300) {
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

  bool _checkIsCharging() {
    return _platformInfo.isCharging;
  }

  Set<String> _getLogicalDrives() {
    return _platformInfo.getLogicalDrives();
  }

  String _getDriveTypeString(String drivePath) {
    return _platformInfo.getDriveType(drivePath);
  }

  double _getSystemIdleSeconds() {
    return _platformInfo.systemIdleSeconds;
  }
}
