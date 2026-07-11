import '../models/notification_models.dart';

class NotificationScheduler {
  static bool shouldSuppress(NotificationItem item, NotificationSettings settings, {DateTime? customNow}) {
    if (item.priority == NotificationPriority.critical) {
      return false;
    }

    if (settings.dndEnabled) {
      return true;
    }

    if (settings.quietHoursEnabled) {
      final now = customNow ?? DateTime.now();
      if (_isInQuietHours(now, settings.quietHoursStart, settings.quietHoursEnd)) {
        if (item.priority != NotificationPriority.error) {
          return true;
        }
      }
    }

    final categoryEnabled = settings.categoriesEnabled[item.category] ?? true;
    if (!categoryEnabled) {
      return true;
    }

    return false;
  }

  static bool shouldBatch(NotificationItem item, NotificationSettings settings) {
    if (item.priority == NotificationPriority.critical || item.priority == NotificationPriority.error) {
      return false;
    }

    return settings.frequency == 'batch';
  }

  static bool _isInQuietHours(DateTime now, String startStr, String endStr) {
    try {
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');

      if (startParts.length != 2 || endParts.length != 2) return false;

      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);

      final nowMin = now.hour * 60 + now.minute;
      final startMinTotal = startHour * 60 + startMin;
      final endMinTotal = endHour * 60 + endMin;

      if (startMinTotal < endMinTotal) {
        return nowMin >= startMinTotal && nowMin < endMinTotal;
      } else {
        return nowMin >= startMinTotal || nowMin < endMinTotal;
      }
    } catch (_) {
      return false;
    }
  }
}
