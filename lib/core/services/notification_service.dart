import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';
import 'notification_scheduler.dart';
import 'platform_notification_service.dart';

typedef NotificationCallback = void Function(NotificationItem item);

class NotificationService {
  final NotificationRepository _repository;
  final PlatformNotificationService _platformNotificationService;
  final List<NotificationItem> _batchBuffer = [];
  final List<NotificationCallback> _onNotificationListeners = [];
  Timer? _batchTimer;

  NotificationService(this._repository, this._platformNotificationService);

  void registerListener(NotificationCallback listener) {
    _onNotificationListeners.add(listener);
  }

  void unregisterListener(NotificationCallback listener) {
    _onNotificationListeners.remove(listener);
  }

  void _dispatchImmediateAlert(NotificationItem item) {
    for (final listener in _onNotificationListeners) {
      try {
        listener(item);
      } catch (_) {}
    }
  }

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

    final itemPending = NotificationItem(
      id: 0,
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

    final savedItem = await _repository.addNotification(itemPending);

    final suppressed = NotificationScheduler.shouldSuppress(savedItem, settings);
    if (suppressed) {
      return savedItem;
    }

    final batched = NotificationScheduler.shouldBatch(savedItem, settings);
    if (batched) {
      _batchBuffer.add(savedItem);
      return savedItem;
    }

    _dispatchImmediateAlert(savedItem);

    _logPlatformNotification(savedItem);

    return savedItem;
  }

  Future<void> flushBatch() async {
    if (_batchBuffer.isEmpty) return;

    final count = _batchBuffer.length;
    final List<NotificationItem> itemsToFlush = List.from(_batchBuffer);
    _batchBuffer.clear();

    final itemsStr = itemsToFlush.map((item) => '[${item.category.displayName}] ${item.message}').join('; ');
    final summaryMessage = 'You have $count updates: $itemsStr';

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

  void _logPlatformNotification(NotificationItem item) {
    debugPrint(' [NATIVE NOTIFICATION CENTER] -> Priority: ${item.priority.name.toUpperCase()} | '
        'Category: ${item.category.displayName} | Message: ${item.message}');
    
    // Delegate to native platform notifications center
    _platformNotificationService.showNotification(
      title: item.category.displayName,
      message: item.message,
      priority: item.priority.name,
    );
  }

  void dispose() {
    _batchTimer?.cancel();
    _onNotificationListeners.clear();
  }
}
