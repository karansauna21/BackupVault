import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'diagnostics_models.dart';
import 'diagnostics_repository.dart';
import 'health_check_service.dart';
import 'performance_analyzer.dart';
import 'benchmark_service.dart';
import 'crash_detector.dart';
import 'recovery_validator.dart';
import 'test_runner.dart';

// Repository Provider
final diagnosticsRepositoryProvider = Provider<DiagnosticsRepository>((ref) {
  final repo = DiagnosticsRepository();
  return repo;
});

// Service Providers
final healthCheckServiceProvider = Provider<HealthCheckService>((ref) {
  return HealthCheckService(ref);
});

final performanceAnalyzerProvider = Provider<PerformanceAnalyzer>((ref) {
  return PerformanceAnalyzer(ref);
});

final benchmarkServiceProvider = Provider<BenchmarkService>((ref) {
  return BenchmarkService(ref);
});

final crashDetectorProvider = Provider<CrashDetector>((ref) {
  final repo = ref.watch(diagnosticsRepositoryProvider);
  return CrashDetector(ref, repo);
});

final recoveryValidatorProvider = Provider<RecoveryValidator>((ref) {
  return RecoveryValidator(ref);
});

final testRunnerProvider = Provider<TestRunner>((ref) {
  return TestRunner();
});

// State Notifiers
class HealthStatusNotifier extends Notifier<SystemHealthStatus> {
  @override
  SystemHealthStatus build() {
    return const SystemHealthStatus();
  }

  Future<void> refresh() async {
    final service = ref.read(healthCheckServiceProvider);
    final status = await service.runAllChecks();
    state = status;
  }
}

final healthStatusProvider = NotifierProvider<HealthStatusNotifier, SystemHealthStatus>(() {
  return HealthStatusNotifier();
});

class PerformanceMetricsNotifier extends Notifier<PerformanceMetrics> {
  @override
  PerformanceMetrics build() {
    return const PerformanceMetrics();
  }

  Future<void> refresh() async {
    final analyzer = ref.read(performanceAnalyzerProvider);
    final metrics = await analyzer.collectMetrics();
    state = metrics;
  }
}

final performanceMetricsProvider = NotifierProvider<PerformanceMetricsNotifier, PerformanceMetrics>(() {
  return PerformanceMetricsNotifier();
});

class DiagnosticsReportNotifier extends Notifier<DiagnosticsReport?> {
  @override
  DiagnosticsReport? build() {
    return null;
  }

  Future<DiagnosticsReport> generateReport() async {
    final analyzer = ref.read(performanceAnalyzerProvider);
    final healthService = ref.read(healthCheckServiceProvider);
    final repo = ref.read(diagnosticsRepositoryProvider);

    final health = await healthService.runAllChecks();
    final perf = await analyzer.collectMetrics();
    final recommendations = analyzer.getRecommendations(perf);

    // Calculate scores
    int hScore = 100;
    if (health.backupEngineStatus != 'Healthy') hScore -= 20;
    if (health.restoreEngineStatus != 'Healthy') hScore -= 20;
    if (health.databaseStatus != 'Healthy') hScore -= 30;
    if (health.storageStatus != 'Healthy') hScore -= 30;

    int pScore = 100;
    if (perf.cpuUsagePercent > 80.0) pScore -= 25;
    if (perf.ramUsageMb > 800.0) pScore -= 20;
    if (perf.databaseQuerySpeedMs > 50) pScore -= 25;
    if (perf.diskWriteSpeedMbPerSec < 15) pScore -= 30;

    final report = DiagnosticsReport(
      healthScore: hScore.clamp(0, 100),
      performanceScore: pScore.clamp(0, 100),
      storageScore: 90, // Static/simulated
      databaseScore: health.databaseStatus == 'Healthy' ? 100 : 50,
      overallSystemScore: ((hScore + pScore + 90 + (health.databaseStatus == 'Healthy' ? 100 : 50)) / 4).toInt(),
      recommendations: recommendations,
      generatedAt: DateTime.now(),
    );

    state = report;
    await repo.addReport(report);
    return report;
  }
}

final diagnosticsReportProvider = NotifierProvider<DiagnosticsReportNotifier, DiagnosticsReport?>(() {
  return DiagnosticsReportNotifier();
});

class CrashReportNotifier extends Notifier<List<CrashReport>> {
  @override
  List<CrashReport> build() {
    final repo = ref.watch(diagnosticsRepositoryProvider);
    return List<CrashReport>.from(repo.crashes);
  }

  void refresh() {
    final repo = ref.read(diagnosticsRepositoryProvider);
    state = List<CrashReport>.from(repo.crashes);
  }

  Future<void> addCrash(CrashReport crash) async {
    final repo = ref.read(diagnosticsRepositoryProvider);
    await repo.addCrashReport(crash);
    refresh();
  }
}

final crashReportsProvider = NotifierProvider<CrashReportNotifier, List<CrashReport>>(() {
  return CrashReportNotifier();
});

class BenchmarkResultsNotifier extends Notifier<List<BenchmarkResult>> {
  @override
  List<BenchmarkResult> build() {
    final repo = ref.watch(diagnosticsRepositoryProvider);
    return List<BenchmarkResult>.from(repo.benchmarks);
  }

  void refresh() {
    final repo = ref.read(diagnosticsRepositoryProvider);
    state = List<BenchmarkResult>.from(repo.benchmarks);
  }

  Future<void> addBenchmark(BenchmarkResult bm) async {
    final repo = ref.read(diagnosticsRepositoryProvider);
    await repo.addBenchmark(bm);
    refresh();
  }
}

final benchmarkResultsProvider = NotifierProvider<BenchmarkResultsNotifier, List<BenchmarkResult>>(() {
  return BenchmarkResultsNotifier();
});
