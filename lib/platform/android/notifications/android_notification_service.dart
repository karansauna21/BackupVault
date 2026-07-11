import 'package:flutter/foundation.dart';
import '../../../core/services/platform_notification_service.dart';

class AndroidNotificationService implements PlatformNotificationService {
  @override
  Future<void> showNotification({
    required String title,
    required String message,
    required String priority,
  }) async {
    debugPrint('[ANDROID SYSTEM CHANNEL NOTIFICATION] -> $title: $message (Priority: $priority)');
  }
}
