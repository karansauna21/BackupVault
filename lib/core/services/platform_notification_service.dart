abstract class PlatformNotificationService {
  Future<void> showNotification({
    required String title,
    required String message,
    required String priority,
  });
}
