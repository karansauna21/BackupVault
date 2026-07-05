import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/features/statistics/statistics_models.dart';
import 'package:backup_vault/features/statistics/storage_analyzer.dart';
import 'package:backup_vault/features/statistics/performance_analyzer.dart';
import 'package:backup_vault/features/statistics/health_analyzer.dart';
import 'package:backup_vault/features/statistics/chart_builder.dart';
import 'package:backup_vault/features/statistics/statistics_exporter.dart';
import 'package:backup_vault/features/statistics/presentation/views/statistics_screen.dart';

void main() {
  group('StatisticsModels Tests', () {
    test('BackupStats copyWith works correctly', () {
      const stats = BackupStats(totalBackupSize: 100, totalFiles: 5);
      final updated = stats.copyWith(totalBackupSize: 200, failedFilesCount: 2);
      expect(updated.totalBackupSize, equals(200));
      expect(updated.totalFiles, equals(5));
      expect(updated.failedFilesCount, equals(2));
    });

    test('StatisticsFilter empty checks', () {
      const filter = StatisticsFilter();
      expect(filter.isEmpty, isTrue);

      final withFolder = filter.copyWith(folderId: 1);
      expect(withFolder.isEmpty, isFalse);
      expect(withFolder.folderId, equals(1));
    });
  });

  group('StorageAnalyzer Tests', () {
    test('Calculates folder size, largest files, and duplicate space correctly', () async {
      final folders = [
        BackupFolder(id: 1, name: 'Documents', sourcePath: 'C:/Docs', destinationPath: 'D:/Back', enabled: true, createdAt: DateTime.now(), backupInterval: 'manual'),
        BackupFolder(id: 2, name: 'Pictures', sourcePath: 'C:/Pics', destinationPath: 'D:/Back', enabled: true, createdAt: DateTime.now(), backupInterval: 'manual'),
      ];

      final files = [
        BackupFile(id: 1, folderId: 1, fileName: 'notes.txt', extension: 'txt', originalPath: 'C:/Docs/notes.txt', backupPath: '', fileSize: 100, sha256: 'abc', createdAt: DateTime.now(), modifiedAt: DateTime.now(), backupStatus: 'success'),
        BackupFile(id: 2, folderId: 1, fileName: 'copy.txt', extension: 'txt', originalPath: 'C:/Docs/copy.txt', backupPath: '', fileSize: 100, sha256: 'abc', createdAt: DateTime.now(), modifiedAt: DateTime.now(), backupStatus: 'success'),
        BackupFile(id: 3, folderId: 2, fileName: 'photo.jpg', extension: 'jpg', originalPath: 'C:/Pics/photo.jpg', backupPath: '', fileSize: 500, sha256: 'xyz', createdAt: DateTime.now(), modifiedAt: DateTime.now(), backupStatus: 'success'),
      ];

      final history = <BackupHistoryData>[];

      final analysis = await StorageAnalyzer.analyze(
        folders: folders,
        files: files,
        history: history,
        availableBytes: 1000,
        totalBytes: 5000,
      );

      expect(analysis.largestFiles.length, equals(3));
      expect(analysis.largestFiles.first.sizeBytes, equals(500)); // photo.jpg
      
      // Duplicates size: notes.txt & copy.txt share same SHA256 ('abc') and are both 'success'.
      // One duplicate of 100 bytes is counted.
      expect(analysis.duplicateStorageSavedBytes, equals(100));
    });
  });

  group('PerformanceAnalyzer Tests', () {
    test('Parses backup speed from logs and calculates queue efficiency', () async {
      final folders = <BackupFolder>[];
      final files = <BackupFile>[];
      final history = [
        BackupHistoryData(id: 1, timestamp: DateTime.now(), status: 'success', message: 'Backup Done', filesCount: 10, totalSize: 500, backupType: 'full'),
        BackupHistoryData(id: 2, timestamp: DateTime.now(), status: 'failed', message: 'Backup Error', filesCount: 0, totalSize: 0, backupType: 'full'),
      ];

      final logs = [
        BackupLog(id: 1, logType: 'info', message: 'Copying finished at 45.2 MB/s', createdAt: DateTime.now()),
        BackupLog(id: 2, logType: 'info', message: 'Completed at 38.8 Mbps', createdAt: DateTime.now()),
      ];

      final analysis = await PerformanceAnalyzer.analyze(
        folders: folders,
        files: files,
        history: history,
        logs: logs,
      );

      // Average speed is (45.2 + 38.8) / 2 = 42.0 MB/s
      expect(analysis.averageCopySpeedMbps, closeTo(42.0, 0.1));
      
      // Queue efficiency: 1 successful run out of 2 = 50%
      expect(analysis.queueEfficiencyPercent, equals(50.0));
    });
  });

  group('HealthAnalyzer Tests', () {
    test('Deducts health score points for failed jobs and low space', () async {
      final folders = <BackupFolder>[];
      final files = <BackupFile>[];
      final history = [
        BackupHistoryData(id: 1, timestamp: DateTime.now(), status: 'failed', message: 'Failed run', filesCount: 0, totalSize: 0, backupType: 'full'),
      ];
      final logs = [
        BackupLog(id: 1, logType: 'error', message: 'verification failed', createdAt: DateTime.now()),
      ];

      final health = await HealthAnalyzer.analyze(
        folders: folders,
        files: files,
        history: history,
        logs: logs,
        availableBytes: 100, // 1% of total (Critically low storage)
        totalBytes: 10000,
        isVersioningEnabled: false, // Deduct 10 points
      );

      // Verify deductions happen
      expect(health.score, lessThan(100));
      expect(health.recommendations.length, greaterThan(0));
    });
  });

  group('ChartBuilder Tests', () {
    test('Groups file formats, success rates, and monthly trends correctly', () {
      final folders = [
        BackupFolder(id: 1, name: 'Folder 1', sourcePath: '', destinationPath: '', enabled: true, createdAt: DateTime.now(), backupInterval: 'manual'),
      ];
      final files = [
        BackupFile(id: 1, folderId: 1, fileName: 'data.json', extension: 'json', originalPath: '', backupPath: '', fileSize: 1024 * 1024, sha256: 'h1', createdAt: DateTime.now(), modifiedAt: DateTime.now(), backupStatus: 'success'),
      ];
      final history = [
        BackupHistoryData(id: 1, timestamp: DateTime.now(), status: 'success', message: '', filesCount: 1, totalSize: 1024 * 1024, backupType: 'full'),
      ];
      final logs = <BackupLog>[];
      final versions = <FileVersion>[];

      final charts = ChartBuilder.build(
        folders: folders,
        files: files,
        history: history,
        logs: logs,
        versions: versions,
      );

      expect(charts.fileTypeDistribution.first.label, equals('JSON'));
      expect(charts.fileTypeDistribution.first.value, equals(1.0)); // 1.0 MB
      expect(charts.backupSuccessRate.first.label, equals('Success'));
    });
  });

  group('StatisticsExporter Tests', () {
    test('Exports CSV formatted strings correctly', () async {
      const stats = BackupStats(totalBackupSize: 1024, totalFiles: 1);
      const storage = StorageAnalysis(mostActiveFolder: 'Docs');
      const performance = PerformanceAnalysis(averageCopySpeedMbps: 25.0);
      const health = BackupHealth(score: 95);

      final tempDir = Directory.systemTemp.createTempSync();
      final path = await StatisticsExporter.exportReport(
        stats: stats,
        storage: storage,
        performance: performance,
        health: health,
        format: 'csv',
        targetDirectory: tempDir.path,
        customFileName: 'test_export',
      );

      final file = File(path);
      expect(await file.exists(), isTrue);
      final text = await file.readAsString();
      expect(text.contains('BackupVault Analytics Report'), isTrue);
      expect(text.contains('Health Score,95/100'), isTrue);
      
      tempDir.deleteSync(recursive: true);
    });
  });

  group('StatisticsScreen Widget Tests', () {
    testWidgets('Renders all tabs and widgets properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StatisticsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Backup Statistics & Analytics'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Charts & Trends'), findsOneWidget);
      expect(find.text('Storage Analysis'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
    });
  });
}
