import 'notification_models.dart';

class NotificationScheduler {
  /// Check if the notification should be suppressed due to DND or Quiet Hours
  static bool shouldSuppress(NotificationItem item, NotificationSettings settings, {DateTime? customNow}) {
    // Critical notifications bypass DND and Quiet Hours
    if (item.priority == NotificationPriority.critical) {
      return false;
    }

    // Do Not Disturb check
    if (settings.dndEnabled) {
      return true;
    }

    // Quiet Hours check
    if (settings.quietHoursEnabled) {
      final now = customNow ?? DateTime.now();
      if (_isInQuietHours(now, settings.quietHoursStart, settings.quietHoursEnd)) {
        // Only allow Critical and Error priorities to bypass Quiet Hours
        if (item.priority != NotificationPriority.error) {
          return true;
        }
      }
    }

    // Check if this specific category is disabled in settings
    final categoryEnabled = settings.categoriesEnabled[item.category] ?? true;
    if (!categoryEnabled) {
      return true;
    }

    return false;
  }

  /// Determines if a notification should be batched/buffered or sent immediately
  static bool shouldBatch(NotificationItem item, NotificationSettings settings) {
    // Critical and Error notifications should NEVER be batched; they must be shown immediately.
    if (item.priority == NotificationPriority.critical || item.priority == NotificationPriority.error) {
      return false;
    }

    return settings.frequency == 'batch';
  }

  /// Helper to determine if current time is within the start/end time window
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
        // Quiet hours span across midnight (e.g. 22:00 to 08:00)
        return nowMin >= startMinTotal || nowMin < endMinTotal;
      }
    } catch (_) {
      return false;
    }
  }
}
