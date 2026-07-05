import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_models.dart';
import 'notification_repository.dart';
import 'notification_scheduler.dart';

typedef NotificationCallback = void Function(NotificationItem item);

class NotificationService {
  final NotificationRepository _repository;
  final List<NotificationItem> _batchBuffer = [];
  final List<NotificationCallback> _onNotificationListeners = [];
  Timer? _batchTimer;

  NotificationService(this._repository);

  /// Register callback for active immediate notification alerts
  void registerListener(NotificationCallback listener) {
    _onNotificationListeners.add(listener);
  }

  void unregisterListener(NotificationCallback listener) {
    _onNotificationListeners.remove(listener);
  }

  /// Dispatch an active alert to registered listeners
  void _dispatchImmediateAlert(NotificationItem item) {
    for (final listener in _onNotificationListeners) {
      try {
        listener(item);
      } catch (_) {}
    }
  }

  /// Initialize and start batch timer if set to batch frequency
  Future<void> startBatchScheduler() async {
    final settings = await _repository.getSettings();
    _batchTimer?.cancel();

    if (settings.frequency == 'batch') {
      _batchTimer = Timer.periodic(
        Duration(minutes: settings.batchIntervalMinutes),
        (timer) => flushBatch(),
      );
    }
  }

  /// Trigger a new notification from any app module (Backup Engine, Restore Engine, Database, etc.)
  Future<NotificationItem> triggerNotification({
    required NotificationPriority priority,
    required NotificationCategory category,
    required String message,
    String? action,
    String? source,
    String? destination,
    String? status,
    String? worker,
    int? relatedBackupId,
  }) async {
    final settings = await _repository.getSettings();

    // Construct the notification item
    final itemPending = NotificationItem(
      id: 0, // Assigned by database
      timestamp: DateTime.now(),
      priority: priority,
      category: category,
      message: message,
      action: action,
      source: source,
      destination: destination,
      status: status,
      worker: worker,
      relatedBackupId: relatedBackupId,
    );

    // Save notification to database history
    final savedItem = await _repository.addNotification(itemPending);

    // Check if notification is suppressed (DND, Quiet Hours, or category disabled)
    final suppressed = NotificationScheduler.shouldSuppress(savedItem, settings);
    if (suppressed) {
      // Notification is saved to database but not actively popped up
      return savedItem;
    }

    // Check if notification should be batched
    final batched = NotificationScheduler.shouldBatch(savedItem, settings);
    if (batched) {
      _batchBuffer.add(savedItem);
      return savedItem;
    }

    // Otherwise, dispatch immediately (in-app toast, toast channel)
    _dispatchImmediateAlert(savedItem);

    // Trigger mock platform notifications on Windows/Android stdout console
    _logPlatformNotification(savedItem);

    return savedItem;
  }

  /// Consolidate and flush all batched notifications into a single summary alert
  Future<void> flushBatch() async {
    if (_batchBuffer.isEmpty) return;

    final count = _batchBuffer.length;
    final List<NotificationItem> itemsToFlush = List.from(_batchBuffer);
    _batchBuffer.clear();

    // Create a consolidated summary notification
    final itemsStr = itemsToFlush.map((item) => '[${item.category.displayName}] ${item.message}').join('; ');
    final summaryMessage = 'You have $count updates: $itemsStr';

    // Trigger the consolidated summary notification immediately
    final summaryNotification = NotificationItem(
      id: 0,
      timestamp: DateTime.now(),
      priority: NotificationPriority.information,
      category: NotificationCategory.queueCompleted,
      message: summaryMessage,
    );

    final savedSummary = await _repository.addNotification(summaryNotification);
    _dispatchImmediateAlert(savedSummary);
    _logPlatformNotification(savedSummary);
  }

  /// Print structured native notifications log to simulate platform toast behaviors
  void _logPlatformNotification(NotificationItem item) {
    // Print mock log representing Windows toast / Android system channel notification
    // This provides future-ready console hooks for Linux/macOS
    debugPrint(' [NATIVE NOTIFICATION CENTER] -> Priority: ${item.priority.name.toUpperCase()} | '
        'Category: ${item.category.displayName} | Message: ${item.message}');
  }

  void dispose() {
    _batchTimer?.cancel();
    _onNotificationListeners.clear();
  }
}
