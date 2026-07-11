import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/notification_models.dart';
import '../../shared/providers/notification_provider.dart';

class NotificationController {
  final WidgetRef _ref;

  NotificationController(this._ref);

  Future<void> markAsRead(int id, bool isRead) async {
    await _ref.read(notificationListProvider.notifier).markAsRead(id, isRead);
  }

  Future<void> markAllAsRead() async {
    await _ref.read(notificationListProvider.notifier).markAllAsRead();
  }

  Future<void> togglePin(int id) async {
    await _ref.read(notificationListProvider.notifier).togglePin(id);
  }

  Future<void> deleteNotification(int id) async {
    await _ref.read(notificationListProvider.notifier).deleteNotification(id);
  }

  Future<void> deleteAllNotifications() async {
    await _ref.read(notificationListProvider.notifier).deleteAllNotifications();
  }

  void copyDetails(NotificationItem item, BuildContext context) {
    final text = 'Priority: ${item.priority.name.toUpperCase()}\n'
        'Category: ${item.category.displayName}\n'
        'Timestamp: ${item.timestamp}\n'
        'Message: ${item.message}\n'
        'Status: ${item.status ?? "N/A"}\n'
        'Worker: ${item.worker ?? "N/A"}';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification details copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> openRelatedFolder(NotificationItem item, BuildContext context) async {
    final folderPath = item.destination ?? item.source ?? 'No related folder found';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening folder: $folderPath'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Trigger mock notification
    await _ref.read(notificationServiceProvider).triggerNotification(
      priority: NotificationPriority.information,
      category: NotificationCategory.folderResumed,
      message: 'User requested to open directory: $folderPath',
      source: folderPath,
    );
  }

  Future<void> retryFailedBackup(NotificationItem item, BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying backup job...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Trigger mock notification representing job startup
    await _ref.read(notificationServiceProvider).triggerNotification(
      priority: NotificationPriority.success,
      category: NotificationCategory.backupStarted,
      message: 'Retrying backup worker job ${item.worker ?? "W-01"} for backup id: ${item.relatedBackupId ?? 1}',
      worker: item.worker ?? 'W-01',
      relatedBackupId: item.relatedBackupId ?? 1,
    );
  }

  void openLogs(BuildContext context) {
    context.go('/logs');
  }

  // Filter setters
  void updatePriorityFilter(NotificationPriority? priority) {
    _ref.read(notificationFiltersProvider.notifier).updateFilters(
      (f) => f.copyWith(priority: () => priority),
    );
  }

  void updateCategoryFilter(NotificationCategory? category) {
    _ref.read(notificationFiltersProvider.notifier).updateFilters(
      (f) => f.copyWith(category: () => category),
    );
  }

  void updateDateRangeFilter(DateTimeRange? dateRange) {
    _ref.read(notificationFiltersProvider.notifier).updateFilters(
      (f) => f.copyWith(dateRange: () => dateRange),
    );
  }

  void updateSearchPrefix(String text) {
    _ref.read(notificationFiltersProvider.notifier).updateFilters(
      (f) => f.copyWith(searchPrefix: () => text),
    );
  }

  void resetFilters() {
    _ref.read(notificationFiltersProvider.notifier).reset();
  }
}
