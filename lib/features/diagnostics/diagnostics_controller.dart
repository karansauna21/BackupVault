import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/logging_service.dart';
import 'diagnostics_models.dart';
import 'diagnostics_provider.dart';

class DiagnosticsController {
  final Ref ref;

  DiagnosticsController(this.ref);

  /// Initialize diagnostics repository and run initial checks
  Future<void> init() async {
    final repo = ref.read(diagnosticsRepositoryProvider);
    await repo.init();

    // Check for crash lock files
    final detector = ref.read(crashDetectorProvider);
    await detector.checkUnexpectedShutdown();

    // Refresh state providers
    ref.read(crashReportsProvider.notifier).refresh();
    ref.read(benchmarkResultsProvider.notifier).refresh();
    await refreshMetrics();
  }

  /// Refresh health and performance metrics in parallel
  Future<void> refreshMetrics() async {
    await Future.wait([
      ref.read(healthStatusProvider.notifier).refresh(),
      ref.read(performanceMetricsProvider.notifier).refresh(),
    ]);
  }

  /// Run one-click full diagnostics suite
  Future<DiagnosticsReport> runOneClickDiagnostics() async {
    await refreshMetrics();
    final report = await ref.read(diagnosticsReportProvider.notifier).generateReport();
    await ref.read(loggingServiceProvider).info('Diagnostics', 'One-click diagnostics report generated: Score ${report.overallSystemScore}');
    return report;
  }

  /// Execute a specific I/O stress benchmark
  Future<BenchmarkResult> executeBenchmark({
    required String name,
    required int filesCount,
    required double sizeMb,
    required String type,
  }) async {
    final service = ref.read(benchmarkServiceProvider);
    final result = await service.runBenchmark(
      name: name,
      targetFilesCount: filesCount,
      targetSizeMb: sizeMb,
      type: type,
    );

    // Save benchmark result
    await ref.read(benchmarkResultsProvider.notifier).addBenchmark(result);
    await ref.read(loggingServiceProvider).info('Diagnostics', 'Benchmark executed: ${result.name} - Speed: ${result.speedMbPerSec.toStringAsFixed(2)} MB/s');
    return result;
  }

  /// Trigger a simulated manual crash
  Future<CrashReport> triggerSimulatedCrash(String type, String message) async {
    final detector = ref.read(crashDetectorProvider);
    final report = await detector.logManualCrash(type, message, 'Simulated diagnostics stress-test exception stacktrace.');
    ref.read(crashReportsProvider.notifier).refresh();
    return report;
  }

  /// Export benchmark results
  Future<String> exportBenchmark(BenchmarkResult result, String format) async {
    final service = ref.read(benchmarkServiceProvider);
    final path = await service.exportReport(result, format);
    await ref.read(loggingServiceProvider).info('Diagnostics', 'Exported benchmark report to $path as $format');
    return path;
  }

  /// Run diagnostics test suite
  Future<Map<String, String>> runDiagnosticsTests() async {
    final runner = ref.read(testRunnerProvider);
    return await runner.runDiagnosticSuite();
  }

  /// Clean all report history
  Future<void> clearHistory() async {
    final repo = ref.read(diagnosticsRepositoryProvider);
    await repo.clearAll();
    ref.read(crashReportsProvider.notifier).refresh();
    ref.read(benchmarkResultsProvider.notifier).refresh();
    await ref.read(loggingServiceProvider).info('Diagnostics', 'History cleared.');
  }
}

final diagnosticsControllerProvider = Provider<DiagnosticsController>((ref) {
  return DiagnosticsController(ref);
});
