import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/core/database/database_provider.dart';
import 'package:backup_vault/features/diagnostics/diagnostics_models.dart';
import 'package:backup_vault/features/diagnostics/diagnostics_repository.dart';
import 'package:backup_vault/features/diagnostics/diagnostics_provider.dart';
import 'package:backup_vault/features/diagnostics/performance_analyzer.dart';
import 'package:backup_vault/features/diagnostics/benchmark_service.dart';
import 'package:backup_vault/features/diagnostics/crash_detector.dart';
import 'package:backup_vault/features/diagnostics/test_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late DiagnosticsRepository repository;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('diagnostics_test_');
    repository = DiagnosticsRepository(storagePath: tempDir.path);
    await repository.init();
    db = AppDatabase(executor: NativeDatabase.memory());

    container = ProviderContainer(
      overrides: [
        diagnosticsRepositoryProvider.overrideWithValue(repository),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('Diagnostics Models Serialization Tests', () {
    test('SystemHealthStatus converts to and from JSON', () {
      const status = SystemHealthStatus(
        backupEngineStatus: 'Healthy',
        databaseStatus: 'Corrupted',
      );
      final jsonMap = status.toJson();
      expect(jsonMap['databaseStatus'], equals('Corrupted'));

      final parsed = SystemHealthStatus.fromJson(jsonMap);
      expect(parsed.backupEngineStatus, equals('Healthy'));
      expect(parsed.databaseStatus, equals('Corrupted'));
    });

    test('CrashReport converts to and from JSON', () {
      final now = DateTime.now();
      final crash = CrashReport(
        id: 'CR_123',
        type: 'Database Failure',
        message: 'Write lock timed out',
        stackTrace: 'custom_stack_trace',
        timestamp: now,
        recoveryStatus: 'Pending',
      );

      final jsonMap = crash.toJson();
      expect(jsonMap['recoveryStatus'], equals('Pending'));

      final parsed = CrashReport.fromJson(jsonMap);
      expect(parsed.id, equals('CR_123'));
      expect(parsed.type, equals('Database Failure'));
      expect(parsed.message, equals('Write lock timed out'));
    });
  });

  group('DiagnosticsRepository Tests', () {
    test('should load, save and add reports/crashes/benchmarks', () async {
      // Benchmark persist test
      final bm = BenchmarkResult(
        id: 'BM_1',
        name: 'Speed Test',
        date: DateTime.now(),
        speedMbPerSec: 125.5,
        filesCount: 1000,
        totalSizeMb: 500.0,
        durationSeconds: 4.0,
        type: 'daily',
      );
      await repository.addBenchmark(bm);
      expect(repository.benchmarks.length, equals(1));
      expect(repository.benchmarks.first.speedMbPerSec, equals(125.5));

      // Report persist test
      final report = DiagnosticsReport(
        healthScore: 90,
        overallSystemScore: 85,
        generatedAt: DateTime.now(),
        recommendations: ['Clean database'],
      );
      await repository.addReport(report);
      expect(repository.reports.length, equals(1));
      expect(repository.reports.first.overallSystemScore, equals(85));

      // Clear all history
      await repository.clearAll();
      expect(repository.benchmarks, isEmpty);
      expect(repository.reports, isEmpty);
    });
  });

  group('PerformanceAnalyzer Tests', () {
    test('should collect performance metrics and generate recommendations', () async {
      final analyzer = PerformanceAnalyzer(container);
      final metrics = await analyzer.collectMetrics();

      expect(metrics.cpuUsagePercent, greaterThanOrEqualTo(0.0));
      expect(metrics.ramUsageMb, greaterThanOrEqualTo(0.0));
      expect(metrics.diskUsagePercent, greaterThanOrEqualTo(0.0));

      final recs = analyzer.getRecommendations(metrics);
      expect(recs, isNotEmpty);
    });
  });

  group('BenchmarkService & Reports Exporter Tests', () {
    test('should run simulated benchmark stress test', () async {
      final service = BenchmarkService(container);
      final result = await service.runBenchmark(
        name: 'Stress Test Run',
        targetFilesCount: 100,
        targetSizeMb: 50.0,
        type: 'custom',
      );

      expect(result.filesCount, equals(100));
      expect(result.totalSizeMb, equals(50.0));
      expect(result.speedMbPerSec, greaterThan(0.0));
    });

    test('should export benchmark results to PDF, CSV, and JSON', () async {
      final service = BenchmarkService(container);
      final bm = BenchmarkResult(
        id: 'BM_100',
        name: 'Export Test',
        date: DateTime.now(),
        speedMbPerSec: 90.0,
        filesCount: 500,
        totalSizeMb: 45.0,
        durationSeconds: 0.5,
        type: 'custom',
      );

      // JSON export
      final jsonPath = await service.exportReport(bm, 'JSON');
      final jsonFile = File(jsonPath);
      expect(await jsonFile.exists(), isTrue);
      final jsonContent = await jsonFile.readAsString();
      expect(jsonContent.contains('BM_100'), isTrue);

      // CSV export
      final csvPath = await service.exportReport(bm, 'CSV');
      final csvFile = File(csvPath);
      expect(await csvFile.exists(), isTrue);
      final csvContent = await csvFile.readAsString();
      expect(csvContent.contains('SpeedMbPerSec'), isTrue);

      // PDF export
      final pdfPath = await service.exportReport(bm, 'PDF');
      final pdfFile = File(pdfPath);
      expect(await pdfFile.exists(), isTrue);
      final pdfBytes = await pdfFile.readAsBytes();
      expect(pdfBytes, isNotEmpty);
      expect(utf8.decode(pdfBytes, allowMalformed: true).contains('%PDF-1.4'), isTrue);
    });
  });

  group('CrashDetector & Recovery Validator Tests', () {
    test('should manage lock file for session crashed detection', () async {
      final detector = CrashDetector(container, repository);

      // Verify lock file creation
      await detector.checkUnexpectedShutdown();
      // Second run without cleanup registers crash
      await detector.checkUnexpectedShutdown();

      expect(repository.crashes.length, equals(1));
      expect(repository.crashes.first.type, equals('Unexpected Shutdown'));

      // Clean cleanup registers normal exit
      await detector.registerShutdownClean();
    });

    test('should execute automated self-healing recovery routines', () async {
      final detector = CrashDetector(container, repository);
      final crash = CrashReport(
        id: 'CR_HEAL',
        type: 'Database Failure',
        message: 'Write timed out',
        stackTrace: 'custom_stack',
        timestamp: DateTime.now(),
        recoveryStatus: 'Pending',
      );

      await repository.addCrashReport(crash);
      
      // Attempt recovery
      final recovered = await detector.attemptRecovery(crash);
      expect(recovered, isNotNull);
    });
  });

  group('TestRunner Tests', () {
    test('should run diagnostic test suite and return results', () async {
      final runner = TestRunner();
      final suite = await runner.runDiagnosticSuite();

      expect(suite.containsKey('Unit Tests'), isTrue);
      expect(suite.containsKey('Widget Tests'), isTrue);
      expect(suite.values, contains(anyOf(equals('Passed'), equals('Failed'))));
    });
  });
}
