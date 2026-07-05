import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/features/logs/logs_models.dart';
import 'package:backup_vault/features/logs/logs_repository.dart';
import 'package:backup_vault/features/logs/log_exporter.dart';
import 'package:backup_vault/features/settings/settings_database.dart';
import 'package:backup_vault/core/repositories/impl/backup_log_repository_impl.dart';
import 'package:backup_vault/features/logs/presentation/views/logs_screen.dart';

void main() {
  group('LogsModels Tests', () {
    test('LogEntry serialization to structured JSON and back', () {
      final entry = LogEntry(
        id: 42,
        timestamp: DateTime.parse('2026-07-04T12:00:00Z'),
        level: LogLevel.error,
        module: LogModule.backup,
        category: LogCategory.backupFailed,
        message: 'Network write failed',
        sourceFile: 'C:\\local\\file.txt',
        destinationFile: 'D:\\remote\\file.txt',
        durationMs: 1200,
        workerId: 'worker_01',
        fileSize: 1024,
        sha256: 'abc123sha',
        status: 'failed',
        errorCode: 'ERR_NET_TIMEOUT',
        exceptionDetails: 'SocketException: connection timed out',
        isPinned: false,
        isImportant: true,
      );

      final jsonStr = entry.toStructuredMessageJson();
      final decoded = json.decode(jsonStr);

      expect(decoded['level'], equals('error'));
      expect(decoded['category'], equals('backupFailed'));
      expect(decoded['errorCode'], equals('ERR_NET_TIMEOUT'));

      // Reconstruct via fromDrift
      // Mock drift record
      final mockDriftLog = _MockDriftLog(
        id: 42,
        logType: 'error',
        message: jsonStr,
        createdAt: DateTime.parse('2026-07-04T12:00:00Z'),
        tag: 'backup',
        stackTrace: 'SocketException: connection timed out',
      );

      final reconstructed = LogEntry.fromDrift(mockDriftLog, isPinned: true);
      expect(reconstructed.id, equals(42));
      expect(reconstructed.level, equals(LogLevel.error));
      expect(reconstructed.module, equals(LogModule.backup));
      expect(reconstructed.category, equals(LogCategory.backupFailed));
      expect(reconstructed.sourceFile, equals('C:\\local\\file.txt'));
      expect(reconstructed.durationMs, equals(1200));
      expect(reconstructed.isPinned, isTrue);
      expect(reconstructed.isImportant, isTrue);
    });

    test('LogSearchQuery filtering matches criteria correctly', () {
      final logs = [
        LogEntry(
          id: 1,
          timestamp: DateTime.now(),
          level: LogLevel.success,
          module: LogModule.backup,
          category: LogCategory.backupCompleted,
          message: 'Job done',
          sourceFile: 'C:\\path\\data.db',
          workerId: 'worker_A',
        ),
        LogEntry(
          id: 2,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          level: LogLevel.error,
          module: LogModule.restore,
          category: LogCategory.restoreFailed,
          message: 'Restore error occurred',
          errorCode: 'ERR_READ',
          workerId: 'worker_B',
        ),
      ];

      // Test keyword filter
      final q1 = const LogSearchQuery(keyword: 'job');
      final matchesKeyword = logs.where((l) => l.message.toLowerCase().contains(q1.keyword)).toList();
      expect(matchesKeyword.length, equals(1));
      expect(matchesKeyword.first.id, equals(1));

      // Test worker filter
      final q2 = const LogSearchQuery(worker: 'worker_B');
      final matchesWorker = logs.where((l) => l.workerId == q2.worker).toList();
      expect(matchesWorker.length, equals(1));
      expect(matchesWorker.first.id, equals(2));
    });
  });

  group('LogExporter Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('logs_export_test');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('Exports TXT, CSV, JSON formats correctly', () async {
      final logs = [
        LogEntry(
          id: 1,
          timestamp: DateTime.parse('2026-07-04T12:00:00Z'),
          level: LogLevel.info,
          module: LogModule.system,
          category: LogCategory.startup,
          message: 'Engine startup',
        ),
      ];

      // Export TXT
      final txtPath = await LogExporter.exportLogs(
        logs: logs,
        format: 'txt',
        targetDirectory: tempDir.path,
        customFileName: 'test_logs_txt',
      );
      final txtFile = File(txtPath);
      expect(txtFile.existsSync(), isTrue);
      expect(await txtFile.readAsString(), contains('BACKUPVAULT LOG EXPORT'));

      // Export CSV
      final csvPath = await LogExporter.exportLogs(
        logs: logs,
        format: 'csv',
        targetDirectory: tempDir.path,
        customFileName: 'test_logs_csv',
      );
      final csvFile = File(csvPath);
      expect(csvFile.existsSync(), isTrue);
      expect(await csvFile.readAsString(), contains('LogLevel,Module,Category,Message'));

      // Export JSON
      final jsonPath = await LogExporter.exportLogs(
        logs: logs,
        format: 'json',
        targetDirectory: tempDir.path,
        customFileName: 'test_logs_json',
      );
      final jsonFile = File(jsonPath);
      expect(jsonFile.existsSync(), isTrue);
      expect(await jsonFile.readAsString(), contains('"category": "startup"'));
    });

    test('Exports ZIP archives correctly', () async {
      final logs = [
        LogEntry(
          id: 1,
          timestamp: DateTime.parse('2026-07-04T12:00:00Z'),
          level: LogLevel.info,
          module: LogModule.system,
          category: LogCategory.startup,
          message: 'Engine startup',
        ),
      ];

      final zipPath = await LogExporter.exportLogs(
        logs: logs,
        format: 'zip',
        targetDirectory: tempDir.path,
        customFileName: 'test_logs_zip',
      );
      final zipFile = File(zipPath);
      expect(zipFile.existsSync(), isTrue);
      expect(zipPath.endsWith('.zip'), isTrue);
    });
  });

  group('LogsRepository & Statistics Tests', () {
    late AppDatabase db;
    late SettingsDatabase settingsDb;
    late LogsRepository repository;

    setUp(() async {
      db = AppDatabase(executor: NativeDatabase.memory());
      settingsDb = SettingsDatabase(isInMemory: true);
      await settingsDb.init();
      final logRepo = BackupLogRepositoryImpl(db.backupLogsDao);
      repository = LogsRepository(db, logRepo, settingsDb);
    });

    tearDown(() async {
      settingsDb.close();
      await db.close();
    });

    test('Persists, retrieves, and toggles log pinning', () async {
      final log = LogEntry(
        id: 0,
        timestamp: DateTime.now(),
        level: LogLevel.info,
        module: LogModule.backup,
        category: LogCategory.backupStarted,
        message: 'Starting worker',
      );

      await repository.addLogEntry(log);
      final list = await repository.getLogs();
      expect(list.length, equals(1));
      expect(list.first.isPinned, isFalse);

      final dbId = list.first.id;
      await repository.togglePinLog(dbId);

      final listPinned = await repository.getLogs();
      expect(listPinned.first.isPinned, isTrue);
    });

    test('Calculates aggregated logs statistics correctly', () async {
      final log1 = LogEntry(
        id: 0,
        timestamp: DateTime.now(),
        level: LogLevel.success,
        module: LogModule.backup,
        category: LogCategory.backupCompleted,
        message: 'Done file',
        durationMs: 500,
        sourceFile: 'C:\\local\\a.txt',
      );
      final log2 = LogEntry(
        id: 0,
        timestamp: DateTime.now(),
        level: LogLevel.error,
        module: LogModule.backup,
        category: LogCategory.backupFailed,
        message: 'Write failed',
        errorCode: 'ERR_DISK_FULL',
        sourceFile: 'C:\\local\\b.txt',
      );

      await repository.addLogEntry(log1);
      await repository.addLogEntry(log2);

      final stats = await repository.calculateStatistics();
      expect(stats.totalLogs, equals(2));
      expect(stats.errors, equals(1));
      expect(stats.successfulBackups, equals(1));
      expect(stats.averageBackupTimeMs, equals(500));
      expect(stats.mostCommonErrors.containsKey('ERR_DISK_FULL'), isTrue);
    });
  });

  group('LogsScreen Widget Tests', () {
    testWidgets('LogsScreen renders and shows tab panels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LogsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check main title
      expect(find.text('Logs & Activity Center'), findsOneWidget);

      // Check Tab bars
      expect(find.text('Activity Center'), findsOneWidget);
      expect(find.text('Log Inspector'), findsOneWidget);
      expect(find.text('Log Statistics'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
    });
  });
}

class _MockDriftLog {
  final int id;
  final String logType;
  final String message;
  final DateTime createdAt;
  final String? tag;
  final String? stackTrace;

  _MockDriftLog({
    required this.id,
    required this.logType,
    required this.message,
    required this.createdAt,
    this.tag,
    this.stackTrace,
  });
}
