import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:backup_vault/features/dashboard/dashboard_models.dart';
import 'package:backup_vault/features/dashboard/dashboard_provider.dart';
import 'package:backup_vault/features/dashboard/dashboard_widgets.dart';
import 'package:backup_vault/features/dashboard/dashboard_screen.dart';
import 'package:backup_vault/core/copy_engine/copy_job.dart';
import 'package:backup_vault/core/copy_engine/copy_queue.dart';
import 'package:backup_vault/core/auto_backup/auto_backup_provider.dart';
import 'package:backup_vault/core/remote_backup/remote_status_provider.dart';

class MockCopyQueue extends CopyQueue {
  @override
  List<CopyJob> build() {
    return [];
  }
}

void main() {
  group('DashboardModels Tests', () {
    test('DashboardStats initial factory sets correct defaults', () {
      final stats = DashboardStats.initial();
      expect(stats.backupStatus, equals('Idle'));
      expect(stats.engineStatus, equals('Running'));
      expect(stats.totalBackupSize, equals(0));
      expect(stats.todaysBackupSize, equals(0));
      expect(stats.totalFiles, equals(0));
      expect(stats.averageBackupSpeed, equals(0.0));
    });

    test('DashboardStats copyWith copies properties correctly', () {
      final stats = DashboardStats.initial();
      final updated = stats.copyWith(
        backupStatus: 'Backing Up',
        totalBackupSize: 1024,
      );
      expect(updated.backupStatus, equals('Backing Up'));
      expect(updated.totalBackupSize, equals(1024));
      expect(updated.engineStatus, equals('Running'));
    });
  });

  group('DashboardWidgets Unit & Widget Tests', () {
    testWidgets('DashboardCard renders title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Test Card',
              value: '123 MB',
              icon: Icons.folder,
              color: Colors.blue,
              subtitle: 'Active',
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
      expect(find.text('123 MB'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('QuickActionButton triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionButton(
              label: 'Test Button',
              icon: Icons.play_arrow,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.byType(QuickActionButton));
      expect(tapped, isTrue);
    });
  });

  group('DashboardScreen Rendering Tests', () {
    testWidgets('DashboardScreen renders correct panels when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) => Future.value(DashboardStats.initial())),
            recentActivityProvider.overrideWith((ref) => Future.value([])),
            copyQueueProvider.overrideWith(() => MockCopyQueue()),
            autoBackupDashboardStatsProvider.overrideWithValue({
              'connectedDevices': 0,
              'pendingFiles': 0,
              'currentTransfer': 'None',
              'currentSpeed': 0.0,
              'eta': 0,
              'lastSync': null,
              'syncStatus': 'Paused',
            }),
            remoteDashboardStatsProvider.overrideWithValue({
              'remoteDevices': 0,
              'currentUpload': 'None',
              'currentDownload': 'None',
              'internetSpeed': 0.0,
              'syncProgress': 0.0,
              'pendingUploads': 0,
            }),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('System Dashboard'), findsOneWidget);
      expect(find.text('Watched Folders'), findsOneWidget);
      expect(find.text('Total Backup Size'), findsOneWidget);
      expect(find.text('Pending Queue'), findsOneWidget);
      expect(find.text('Backup Speed'), findsOneWidget);
      expect(find.text('Automatic Network Backup Monitor'), findsOneWidget);
      expect(find.text('Remote Backup Monitor (Internet)'), findsOneWidget);
    });
  });
}
