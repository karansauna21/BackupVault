import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/features/version_history/version_models.dart';
import 'package:backup_vault/features/version_history/version_comparer.dart';
import 'package:backup_vault/features/version_history/version_search.dart';
import 'package:backup_vault/features/version_history/version_exporter.dart';
import 'package:backup_vault/features/version_history/version_history_screen.dart';
import 'package:backup_vault/core/database/database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  // Set up in-memory database and mock platform channels before testing
  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return '.';
        }
        return null;
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('VersionHistory Models Tests', () {
    test('VersionHistoryFilter copyWith works correctly', () {
      const filter = VersionHistoryFilter(type: VersionFilterType.all);
      final updated = filter.copyWith(type: VersionFilterType.latest, folderId: 4);

      expect(updated.type, equals(VersionFilterType.latest));
      expect(updated.folderId, equals(4));
      expect(updated.searchPrefix, isNull);
    });

    test('VersionHistoryStats.empty yields correct defaults', () {
      final stats = VersionHistoryStats.empty();
      expect(stats.totalVersions, equals(0));
      expect(stats.averageVersionsPerFile, equals(0.0));
      expect(stats.largestVersionChain, equals(0));
      expect(stats.versionStorageUsageBytes, equals(0));
    });
  });

  group('VersionComparer Tests', () {
    test('Identifies shifts in version metadata', () {
      final file = BackupFile(
        id: 1,
        folderId: 2,
        fileName: 'test.txt',
        extension: '.txt',
        originalPath: '/data/test.txt',
        backupPath: '/backup/test_v1.txt',
        fileSize: 100,
        sha256: 'sha-old',
        createdAt: DateTime(2026, 1, 1),
        modifiedAt: DateTime(2026, 1, 1),
        backupStatus: 'success',
      );

      final folder = BackupFolder(
        id: 2,
        name: 'Docs',
        sourcePath: '/data',
        destinationPath: '/backup',
        enabled: true,
        createdAt: DateTime(2026, 1, 1),
        backupInterval: 'manual',
        lastBackupAt: null,
        nextBackupAt: null,
      );

      final v1 = FileVersion(id: 1, fileId: 1, versionNumber: 1, backupPath: '/backup/test_v1.txt', createdAt: DateTime(2026, 1, 1));
      final v2 = FileVersion(id: 2, fileId: 1, versionNumber: 2, backupPath: '/backup/test_v2.txt', createdAt: DateTime(2026, 1, 2));

      final detailA = VersionDetail(
        version: v1,
        parentFile: file,
        folder: folder,
        modifiedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        sha256: 'sha-old',
        sizeBytes: 100,
        backupWorker: 'Worker 1',
        backupDuration: const Duration(milliseconds: 500),
        verificationStatus: 'verified',
      );

      final detailB = VersionDetail(
        version: v2,
        parentFile: file,
        folder: folder,
        modifiedAt: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 1),
        sha256: 'sha-new',
        sizeBytes: 150,
        backupWorker: 'Worker 2',
        backupDuration: const Duration(milliseconds: 600),
        verificationStatus: 'verified',
      );

      final compareResult = VersionComparer.compare(detailA, detailB);

      expect(compareResult.sizeChanged, isTrue);
      expect(compareResult.shaChanged, isTrue);
      expect(compareResult.dateChanged, isTrue);
      expect(compareResult.modifiedDateChanged, isTrue);
      expect(compareResult.metadataChanged, isTrue);
    });
  });

  group('VersionSearch & Filtering Tests', () {
    test('Filtering matches target conditions', () {
      final file = BackupFile(
        id: 1,
        folderId: 1,
        fileName: 'test.txt',
        extension: '.txt',
        originalPath: '/data/test.txt',
        backupPath: '/backup/test_v1.txt',
        fileSize: 100,
        sha256: 'sha-old',
        createdAt: DateTime(2026, 1, 1),
        modifiedAt: DateTime(2026, 1, 1),
        backupStatus: 'success',
      );

      final folder = BackupFolder(
        id: 1,
        name: 'Docs',
        sourcePath: '/data',
        destinationPath: '/backup',
        enabled: true,
        createdAt: DateTime(2026, 1, 1),
        backupInterval: 'manual',
        lastBackupAt: null,
        nextBackupAt: null,
      );

      final list = [
        VersionDetail(
          version: FileVersion(id: 1, fileId: 1, versionNumber: 1, backupPath: '/backup/test_v1.txt', createdAt: DateTime(2026, 1, 1)),
          parentFile: file,
          folder: folder,
          modifiedAt: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          sha256: 'hash-abc',
          sizeBytes: 100,
          backupWorker: 'Worker 1',
          backupDuration: const Duration(milliseconds: 500),
          verificationStatus: 'verified',
        ),
        VersionDetail(
          version: FileVersion(id: 2, fileId: 1, versionNumber: 2, backupPath: '/backup/test_v2.txt', createdAt: DateTime(2026, 1, 2)),
          parentFile: file,
          folder: folder,
          modifiedAt: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 1),
          sha256: 'hash-xyz',
          sizeBytes: 120,
          backupWorker: 'Worker 2',
          backupDuration: const Duration(milliseconds: 500),
          verificationStatus: 'failed',
        ),
      ];

      // Prefix Search matching worker
      final searchResult = VersionSearchEvaluator.search(list, 'Worker 2');
      expect(searchResult.length, equals(1));
      expect(searchResult.first.version.versionNumber, equals(2));

      // Filter Type: Latest
      final latest = VersionSearchEvaluator.filter(list, const VersionHistoryFilter(type: VersionFilterType.latest));
      expect(latest.length, equals(1));
      expect(latest.first.version.versionNumber, equals(2));

      // Filter Type: Failed
      final failed = VersionSearchEvaluator.filter(list, const VersionHistoryFilter(type: VersionFilterType.failed));
      expect(failed.length, equals(1));
      expect(failed.first.version.versionNumber, equals(2));
    });
  });

  group('VersionExporter Tests', () {
    test('Generates exporting formats correctly', () async {
      final file = BackupFile(
        id: 1,
        folderId: 1,
        fileName: 'test.txt',
        extension: '.txt',
        originalPath: '/data/test.txt',
        backupPath: '/backup/test_v1.txt',
        fileSize: 100,
        sha256: 'sha-old',
        createdAt: DateTime(2026, 1, 1),
        modifiedAt: DateTime(2026, 1, 1),
        backupStatus: 'success',
      );

      final folder = BackupFolder(
        id: 1,
        name: 'Docs',
        sourcePath: '/data',
        destinationPath: '/backup',
        enabled: true,
        createdAt: DateTime(2026, 1, 1),
        backupInterval: 'manual',
        lastBackupAt: null,
        nextBackupAt: null,
      );

      final list = [
        VersionDetail(
          version: FileVersion(id: 1, fileId: 1, versionNumber: 1, backupPath: '/backup/test_v1.txt', createdAt: DateTime(2026, 1, 1)),
          parentFile: file,
          folder: folder,
          modifiedAt: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          sha256: 'hash-abc',
          sizeBytes: 100,
          backupWorker: 'Worker 1',
          backupDuration: const Duration(milliseconds: 500),
          verificationStatus: 'verified',
        )
      ];

      final csvFile = await VersionExporter.exportToCSV(list);
      expect(csvFile.existsSync(), isTrue);
      final csvContent = await csvFile.readAsString();
      expect(csvContent, contains('Version,File Name,Original Path'));
      expect(csvContent, contains('test.txt'));

      final jsonFile = await VersionExporter.exportToJSON(list);
      expect(jsonFile.existsSync(), isTrue);
      final jsonContent = await jsonFile.readAsString();
      final parsed = json.decode(jsonContent);
      expect(parsed['totalRecords'], equals(1));

      final txtFile = await VersionExporter.exportToTXT(list);
      expect(txtFile.existsSync(), isTrue);
      final txtContent = await txtFile.readAsString();
      expect(txtContent, contains('BACKUPVAULT FILE VERSION HISTORY EXPORT'));

      final pdfFile = await VersionExporter.exportToPDF(list);
      expect(pdfFile.existsSync(), isTrue);
      final pdfContent = await pdfFile.readAsString();
      expect(pdfContent, contains('%PDF-1.4'));

      // Clean up temp files
      await csvFile.delete();
      await jsonFile.delete();
      await txtFile.delete();
      await pdfFile.delete();
    });
  });

  group('VersionHistoryScreen Widget Tests', () {
    testWidgets('VersionHistoryScreen renders and shows analytics when no file is selected', (WidgetTester tester) async {
      // Set desktop view size so that Row with split layout is rendered
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: VersionHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title should render
      expect(find.text('File Version History & Timeline'), findsOneWidget);

      // Search bar in sidebar should render
      expect(find.byType(SearchBar), findsOneWidget);

      // Statistics header should render
      expect(find.text('Version Statistics & Repository Analytics'), findsOneWidget);

      // Reset test view properties
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
