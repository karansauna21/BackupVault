import 'package:flutter/foundation.dart';
import '../../../core/services/platform_notification_service.dart';

class WindowsNotificationService implements PlatformNotificationService {
  @override
  Future<void> showNotification({
    required String title,
    required String message,
    required String priority,
  }) async {
    debugPrint('[WINDOWS NATIVE TOAST] -> $title: $message (Priority: $priority)');
  }
}
