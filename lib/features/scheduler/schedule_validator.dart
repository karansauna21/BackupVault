import 'dart:io';
import 'scheduler_models.dart';
import '../../core/database/app_database.dart';

class ScheduleValidator {
  /// Validates the cron expression.
  /// Standard cron expression: 5 fields (minute, hour, day of month, month, day of week)
  static bool isValidCron(String cron) {
    final parts = cron.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) return false;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part == '*') continue;

      // Match step syntax: */5, 1-30/5, etc.
      final stepRegex = RegExp(r'^(\*|(?:\d+(?:-\d+)?))(?:/(\d+))+$');
      if (stepRegex.hasMatch(part)) {
        final match = stepRegex.firstMatch(part)!;
        final base = match.group(1)!;
        final stepStr = match.group(2);

        if (stepStr != null) {
          final step = int.tryParse(stepStr);
          if (step == null || step <= 0) return false;
        }

        if (base == '*') continue;
        if (!_validateRangeOrNumber(base, i)) return false;
        continue;
      }

      // Match range or commas
      if (part.contains(',')) {
        final subparts = part.split(',');
        for (final sub in subparts) {
          if (!_validateRangeOrNumber(sub, i)) return false;
        }
        continue;
      }

      if (!_validateRangeOrNumber(part, i)) return false;
    }

    return true;
  }

  static bool _validateRangeOrNumber(String value, int fieldIndex) {
    if (value.contains('-')) {
      final rangeParts = value.split('-');
      if (rangeParts.length != 2) return false;
      final start = int.tryParse(rangeParts[0]);
      final end = int.tryParse(rangeParts[1]);
      if (start == null || end == null || start > end) return false;
      return _isValidValueForField(start, fieldIndex) && _isValidValueForField(end, fieldIndex);
    }

    final val = int.tryParse(value);
    if (val == null) return false;
    return _isValidValueForField(val, fieldIndex);
  }

  static bool _isValidValueForField(int val, int fieldIndex) {
    switch (fieldIndex) {
      case 0: // Minute: 0-59
        return val >= 0 && val <= 59;
      case 1: // Hour: 0-23
        return val >= 0 && val <= 23;
      case 2: // Day of Month: 1-31
        return val >= 1 && val <= 31;
      case 3: // Month: 1-12
        return val >= 1 && val <= 12;
      case 4: // Day of Week: 0-6 (0 is Sunday or Sunday/Monday depending on convention, let's allow 0-7)
        return val >= 0 && val <= 7;
      default:
        return false;
    }
  }

  /// Evaluates whether a given DateTime matches a cron expression.
  static bool matchesCron(String cron, DateTime time) {
    if (!isValidCron(cron)) return false;
    final parts = cron.trim().split(RegExp(r'\s+'));

    return _matchesField(parts[0], time.minute, 0) &&
        _matchesField(parts[1], time.hour, 1) &&
        _matchesField(parts[2], time.day, 2) &&
        _matchesField(parts[3], time.month, 3) &&
        _matchesField(parts[4], time.weekday % 7, 4); // convert 7 (Sunday) to 0 or 7
  }

  static bool _matchesField(String pattern, int val, int fieldIndex) {
    if (pattern == '*') return true;

    // Check steps
    if (pattern.contains('/')) {
      final parts = pattern.split('/');
      final step = int.parse(parts[1]);
      final base = parts[0];

      if (base == '*') {
        return val % step == 0;
      } else if (base.contains('-')) {
        final rangeParts = base.split('-');
        final start = int.parse(rangeParts[0]);
        final end = int.parse(rangeParts[1]);
        if (val < start || val > end) return false;
        return (val - start) % step == 0;
      } else {
        final start = int.parse(base);
        if (val < start) return false;
        return (val - start) % step == 0;
      }
    }

    // Check commas
    if (pattern.contains(',')) {
      final subpatterns = pattern.split(',');
      for (final sub in subpatterns) {
        if (_matchesRangeOrNumber(sub, val)) return true;
      }
      return false;
    }

    return _matchesRangeOrNumber(pattern, val);
  }

  static bool _matchesRangeOrNumber(String pattern, int val) {
    if (pattern.contains('-')) {
      final rangeParts = pattern.split('-');
      final start = int.parse(rangeParts[0]);
      final end = int.parse(rangeParts[1]);
      return val >= start && val <= end;
    }
    return int.parse(pattern) == val;
  }

  /// Validates a schedule config.
  static Future<Map<String, dynamic>> validateSchedule(
    ScheduleConfig config,
    List<BackupFolder> folders,
  ) async {
    final folder = folders.where((f) => f.id == config.folderId).firstOrNull;
    if (folder == null) {
      return {'isValid': false, 'error': 'Selected backup folder no longer exists.'};
    }

    if (!folder.enabled) {
      return {'isValid': false, 'error': 'Selected backup folder is disabled.'};
    }

    if (config.scheduleType == 'Custom Cron Expression') {
      if (config.customCronExpression == null || config.customCronExpression!.isEmpty) {
        return {'isValid': false, 'error': 'Cron expression cannot be empty.'};
      }
      if (!isValidCron(config.customCronExpression!)) {
        return {'isValid': false, 'error': 'Invalid cron expression format. Must be 5 standard fields.'};
      }
    }

    if (config.triggerTypes.contains('Specific Date')) {
      if (config.triggerSpecificDate == null) {
        return {'isValid': false, 'error': 'Specific date trigger requires a date.'};
      }
      if (config.triggerSpecificDate!.isBefore(DateTime.now())) {
        return {'isValid': false, 'error': 'Specific date cannot be in the past.'};
      }
    }

    if (config.triggerTypes.contains('Specific Time')) {
      if (config.triggerSpecificTime == null || config.triggerSpecificTime!.isEmpty) {
        return {'isValid': false, 'error': 'Specific time trigger requires a time (e.g. HH:MM).'};
      }
      final parts = config.triggerSpecificTime!.split(':');
      if (parts.length != 2) {
        return {'isValid': false, 'error': 'Invalid time format. Use HH:MM.'};
      }
      final hour = int.tryParse(parts[0]);
      final min = int.tryParse(parts[1]);
      if (hour == null || min == null || hour < 0 || hour > 23 || min < 0 || min > 59) {
        return {'isValid': false, 'error': 'Invalid hour or minute in specific time trigger.'};
      }
    }

    // Verify destination exists if the smart rule is enabled
    if (config.rules.runOnlyIfDestinationAvailable) {
      final destDir = Directory(folder.destinationPath);
      if (!await destDir.exists()) {
        return {
          'isValid': false,
          'error': 'Destination directory is currently not available: ${folder.destinationPath}'
        };
      }
    }

    return {'isValid': true, 'error': null};
  }
}
