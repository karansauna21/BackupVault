import 'dart:convert';
import 'notification_database.dart';
import 'notification_models.dart';

class NotificationRepository {
  final NotificationDatabase _db;

  NotificationRepository(this._db);

  Future<void> init() async {
    await _db.init();
  }

  Future<NotificationSettings> getSettings() async {
    try {
      final jsonStr = _db.getSetting('settings');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        return NotificationSettings.fromJson(decoded);
      }
    } catch (_) {}
    return const NotificationSettings();
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final jsonStr = json.encode(settings.toJson());
    _db.setSetting('settings', jsonStr);
  }

  Future<NotificationItem> addNotification(NotificationItem item) async {
    final data = item.toJson();
    final insertedId = _db.insertNotification(data);
    return item.copyWith(id: insertedId);
  }

  Future<List<NotificationItem>> loadNotifications() async {
    final rawList = _db.getAllNotifications();
    return rawList.map((m) => NotificationItem.fromJson(m)).toList();
  }

  Future<void> markAsRead(int id, bool isRead) async {
    _db.markAsRead(id, isRead);
  }

  Future<void> markAllAsRead() async {
    _db.markAllAsRead();
  }

  Future<void> setPinned(int id, bool isPinned) async {
    _db.setPinned(id, isPinned);
  }

  Future<void> deleteNotification(int id) async {
    _db.deleteNotification(id);
  }

  Future<void> deleteAllNotifications() async {
    _db.deleteAllNotifications();
  }
}
