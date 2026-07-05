import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_models.dart';
import 'notification_database.dart';
import 'notification_repository.dart';
import 'notification_service.dart';
import 'notification_history.dart';

final notificationDatabaseProvider = Provider<NotificationDatabase>((ref) {
  final db = NotificationDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final db = ref.watch(notificationDatabaseProvider);
  return NotificationRepository(db);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final service = NotificationService(repo);
  service.startBatchScheduler();
  ref.onDispose(() => service.dispose());
  return service;
});

class NotificationListNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    final repo = ref.watch(notificationRepositoryProvider);
    await repo.init();
    return repo.loadNotifications();
  }

  Future<void> addNotification(NotificationItem item) async {
    final current = state.value ?? [];
    state = AsyncValue.data([item, ...current]);
  }

  Future<void> markAsRead(int id, bool isRead) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(id, isRead);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((item) => item.id == id ? item.copyWith(isRead: isRead) : item).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((item) => item.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> togglePin(int id) async {
    final current = state.value ?? [];
    final item = current.firstWhere((e) => e.id == id);
    final nextPinned = !item.isPinned;

    final repo = ref.read(notificationRepositoryProvider);
    await repo.setPinned(id, nextPinned);

    state = AsyncValue.data(
      current.map((e) => e.id == id ? e.copyWith(isPinned: nextPinned) : e).toList(),
    );
  }

  Future<void> deleteNotification(int id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.deleteNotification(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((item) => item.id != id).toList());
  }

  Future<void> deleteAllNotifications() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.deleteAllNotifications();
    state = const AsyncValue.data([]);
  }
}

final notificationListProvider = AsyncNotifierProvider<NotificationListNotifier, List<NotificationItem>>(() {
  return NotificationListNotifier();
});

class NotificationFiltersNotifier extends Notifier<NotificationFilters> {
  @override
  NotificationFilters build() => const NotificationFilters();

  void updateFilters(NotificationFilters Function(NotificationFilters) update) {
    state = update(state);
  }

  void reset() {
    state = const NotificationFilters();
  }
}

final notificationFiltersProvider = NotifierProvider<NotificationFiltersNotifier, NotificationFilters>(() {
  return NotificationFiltersNotifier();
});

final filteredNotificationsProvider = Provider<AsyncValue<List<NotificationItem>>>((ref) {
  final listAsync = ref.watch(notificationListProvider);
  final filters = ref.watch(notificationFiltersProvider);

  return listAsync.when(
    data: (list) => AsyncValue.data(NotificationHistoryManager.filter(list, filters)),
    error: (err, stack) => AsyncValue.error(err, stack),
    loading: () => const AsyncValue.loading(),
  );
});

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationListProvider).value ?? [];
  return list.where((item) => !item.isRead).length;
});

final latestNotificationProvider = Provider<NotificationItem?>((ref) {
  final list = ref.watch(notificationListProvider).value ?? [];
  if (list.isEmpty) return null;
  return list.first;
});

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    final repo = ref.watch(notificationRepositoryProvider);
    await repo.init();
    return repo.getSettings();
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.saveSettings(settings);
    state = AsyncValue.data(settings);
    // Restart batch scheduler if settings changed
    ref.read(notificationServiceProvider).startBatchScheduler();
  }
}

final notificationSettingsProvider = AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(() {
  return NotificationSettingsNotifier();
});
