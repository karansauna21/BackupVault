import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:backup_vault/features/notifications/notification_models.dart';
import 'package:backup_vault/features/notifications/notification_database.dart';
import 'package:backup_vault/features/notifications/notification_repository.dart';
import 'package:backup_vault/features/notifications/notification_scheduler.dart';
import 'package:backup_vault/features/notifications/notification_history.dart';
import 'package:backup_vault/features/notifications/notification_service.dart';
import 'package:backup_vault/features/notifications/notification_provider.dart';
import 'package:backup_vault/features/notifications/notification_center_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationDatabase db;
  late NotificationRepository repository;
  late NotificationService service;

  setUp(() async {
    db = NotificationDatabase(isInMemory: true);
    repository = NotificationRepository(db);
    await repository.init();
    service = NotificationService(repository);
  });

  tearDown(() {
    service.dispose();
    db.close();
  });

  group('Notifications Models Tests', () {
    test('NotificationItem parsing and copyWith', () {
      final now = DateTime.now();
      final item = NotificationItem(
        id: 1,
        timestamp: now,
        priority: NotificationPriority.critical,
        category: NotificationCategory.backupFailed,
        message: 'Disk Full',
        source: '/src',
        destination: '/dst',
        status: 'failed',
        worker: 'W-10',
        relatedBackupId: 5,
        isRead: false,
        isPinned: false,
      );

      final copy = item.copyWith(isRead: true, isPinned: true);
      expect(copy.isRead, isTrue);
      expect(copy.isPinned, isTrue);

      final jsonMap = item.toJson();
      expect(jsonMap['priority'], equals('critical'));
      expect(jsonMap['category'], equals('backupFailed'));

      final parsed = NotificationItem.fromJson(jsonMap);
      expect(parsed.id, equals(1));
      expect(parsed.priority, equals(NotificationPriority.critical));
      expect(parsed.category, equals(NotificationCategory.backupFailed));
    });

    test('NotificationSettings default configuration', () {
      const settings = NotificationSettings();
      expect(settings.dndEnabled, isFalse);
      expect(settings.quietHoursEnabled, isFalse);
      expect(settings.frequency, equals('immediate'));
      expect(settings.quietHoursStart, equals('22:00'));
      expect(settings.quietHoursEnd, equals('08:00'));
    });
  });

  group('NotificationScheduler & DND Tests', () {
    test('Suppresses alerts when DND is enabled', () {
      const settings = NotificationSettings(dndEnabled: true);
      final item = NotificationItem(
        id: 1,
        timestamp: DateTime.now(),
        priority: NotificationPriority.warning,
        category: NotificationCategory.folderAdded,
        message: 'Folder added',
      );

      final suppressed = NotificationScheduler.shouldSuppress(item, settings);
      expect(suppressed, isTrue);
    });

    test('Critical alerts bypass DND suppression', () {
      const settings = NotificationSettings(dndEnabled: true);
      final item = NotificationItem(
        id: 1,
        timestamp: DateTime.now(),
        priority: NotificationPriority.critical,
        category: NotificationCategory.backupFailed,
        message: 'Critical error',
      );

      final suppressed = NotificationScheduler.shouldSuppress(item, settings);
      expect(suppressed, isFalse);
    });

    test('Quiet Hours check across midnight', () {
      // Quiet hours from 22:00 to 08:00
      const settings = NotificationSettings(
        quietHoursEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );

      final item = NotificationItem(
        id: 1,
        timestamp: DateTime.now(),
        priority: NotificationPriority.information,
        category: NotificationCategory.backupStarted,
        message: 'Backup started',
      );

      // 23:00 is within quiet hours
      final timeInside = DateTime(2026, 7, 4, 23, 0);
      final suppressedInside = NotificationScheduler.shouldSuppress(item, settings, customNow: timeInside);
      expect(suppressedInside, isTrue);

      // 12:00 (Noon) is outside quiet hours
      final timeOutside = DateTime(2026, 7, 4, 12, 0);
      final suppressedOutside = NotificationScheduler.shouldSuppress(item, settings, customNow: timeOutside);
      expect(suppressedOutside, isFalse);
    });
  });

  group('NotificationHistory & Filtering Tests', () {
    final list = [
      NotificationItem(
        id: 1,
        timestamp: DateTime(2026, 7, 4, 10, 0),
        priority: NotificationPriority.critical,
        category: NotificationCategory.backupFailed,
        message: 'Hard drive full',
        destination: '/volumes/usb_hdd',
        worker: 'Worker-01',
        isRead: false,
        isPinned: false,
      ),
      NotificationItem(
        id: 2,
        timestamp: DateTime(2026, 7, 4, 11, 0),
        priority: NotificationPriority.information,
        category: NotificationCategory.backupStarted,
        message: 'Job W-02 started',
        worker: 'Worker-02',
        isRead: true,
        isPinned: true,
      ),
    ];

    test('Filters by priority and category', () {
      final filterPrio = NotificationHistoryManager.filter(
        list,
        const NotificationFilters(priority: NotificationPriority.critical),
      );
      expect(filterPrio.length, equals(1));
      expect(filterPrio.first.id, equals(1));

      final filterCat = NotificationHistoryManager.filter(
        list,
        const NotificationFilters(category: NotificationCategory.backupStarted),
      );
      expect(filterCat.length, equals(1));
      expect(filterCat.first.id, equals(2));
    });

    test('Filters by search text prefix', () {
      final filterSearch = NotificationHistoryManager.filter(
        list,
        const NotificationFilters(searchPrefix: 'usb_hdd'),
      );
      expect(filterSearch.length, equals(1));
      expect(filterSearch.first.id, equals(1));
    });

    test('Calculates notification statistics', () {
      final stats = NotificationHistoryManager.calculateStats(list);
      expect(stats.totalCount, equals(2));
      expect(stats.unreadCount, equals(1));
      expect(stats.readCount, equals(1));
      expect(stats.pinnedCount, equals(1));
      expect(stats.criticalCount, equals(1));
    });
  });

  group('NotificationService & Batch Tests', () {
    test('Triggering notifications calls registered callback listeners', () async {
      NotificationItem? received;
      service.registerListener((item) {
        received = item;
      });

      await service.triggerNotification(
        priority: NotificationPriority.error,
        category: NotificationCategory.restoreFailed,
        message: 'Restore failed details',
      );

      expect(received, isNotNull);
      expect(received!.message, equals('Restore failed details'));
      expect(received!.priority, equals(NotificationPriority.error));
    });

    test('Buffers and flushes batch notifications correctly', () async {
      // Configure repository settings with batch frequency
      const settings = NotificationSettings(frequency: 'batch');
      await repository.saveSettings(settings);

      NotificationItem? receivedSummary;
      service.registerListener((item) {
        receivedSummary = item;
      });

      // Trigger two non-critical notifications
      await service.triggerNotification(
        priority: NotificationPriority.information,
        category: NotificationCategory.folderAdded,
        message: 'Folder X added',
      );
      await service.triggerNotification(
        priority: NotificationPriority.information,
        category: NotificationCategory.folderPaused,
        message: 'Folder Y paused',
      );

      // Verify no immediate alerts triggered because they are batched
      expect(receivedSummary, isNull);

      // Flush batch summary
      await service.flushBatch();

      expect(receivedSummary, isNotNull);
      expect(receivedSummary!.category, equals(NotificationCategory.queueCompleted));
      expect(receivedSummary!.message, contains('You have 2 updates'));
      expect(receivedSummary!.message, contains('Folder X added'));
      expect(receivedSummary!.message, contains('Folder Y paused'));
    });
  });

  group('NotificationCenterScreen Widget Tests', () {
    testWidgets('NotificationCenterScreen renders tabs, filters, and logs list', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title should render
      expect(find.text('Notification Center & Alerts'), findsOneWidget);

      // Search bar should render
      expect(find.byType(SearchBar), findsOneWidget);

      // Tabs should render
      expect(find.text('Alerts Log'), findsOneWidget);
      expect(find.text('Configure System'), findsOneWidget);

      // Switch to settings tab
      await tester.tap(find.text('Configure System'));
      await tester.pumpAndSettle();

      // Settings widgets should render
      expect(find.text('General Alert Rules'), findsOneWidget);
      expect(find.text('Do Not Disturb (DND)'), findsOneWidget);
      expect(find.text('Quiet Hours'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
