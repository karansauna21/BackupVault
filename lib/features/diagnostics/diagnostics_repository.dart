import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'diagnostics_models.dart';

class DiagnosticsRepository {
  final String? storagePath;

  DiagnosticsRepository({this.storagePath});

  final List<DiagnosticsReport> _reports = [];
  final List<CrashReport> _crashes = [];
  final List<BenchmarkResult> _benchmarks = [];

  List<DiagnosticsReport> get reports => List.unmodifiable(_reports);
  List<CrashReport> get crashes => List.unmodifiable(_crashes);
  List<BenchmarkResult> get benchmarks => List.unmodifiable(_benchmarks);

  Future<void> init() async {
    await loadReports();
    await loadCrashes();
    await loadBenchmarks();
  }

  Future<File> _getFile(String fileName) async {
    final String basePath;
    if (storagePath != null) {
      basePath = storagePath!;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      basePath = dir.path;
    }
    final path = p.join(basePath, 'backup_vault', 'diagnostics');
    await Directory(path).create(recursive: true);
    return File(p.join(path, fileName));
  }

  // --- Reports ---
  Future<void> loadReports() async {
    try {
      _reports.clear();
      final file = await _getFile('diagnostics_reports.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = json.decode(content) as List;
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _reports.add(DiagnosticsReport.fromJson(item));
          }
        }
      }
    } catch (_) {
      _reports.clear();
    }
  }

  Future<void> saveReports() async {
    final file = await _getFile('diagnostics_reports.json');
    final content = json.encode(_reports.map((r) => r.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<void> addReport(DiagnosticsReport report) async {
    _reports.add(report);
    await saveReports();
  }

  // --- Crashes ---
  Future<void> loadCrashes() async {
    try {
      _crashes.clear();
      final file = await _getFile('crash_reports.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = json.decode(content) as List;
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _crashes.add(CrashReport.fromJson(item));
          }
        }
      }
    } catch (_) {
      _crashes.clear();
    }
  }

  Future<void> saveCrashes() async {
    final file = await _getFile('crash_reports.json');
    final content = json.encode(_crashes.map((c) => c.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<void> addCrashReport(CrashReport crash) async {
    _crashes.add(crash);
    await saveCrashes();
  }

  Future<void> updateCrashReport(CrashReport crash) async {
    final idx = _crashes.indexWhere((c) => c.id == crash.id);
    if (idx != -1) {
      _crashes[idx] = crash;
      await saveCrashes();
    }
  }

  // --- Benchmarks ---
  Future<void> loadBenchmarks() async {
    try {
      _benchmarks.clear();
      final file = await _getFile('benchmarks.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = json.decode(content) as List;
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            _benchmarks.add(BenchmarkResult.fromJson(item));
          }
        }
      }
    } catch (_) {
      _benchmarks.clear();
    }
  }

  Future<void> saveBenchmarks() async {
    final file = await _getFile('benchmarks.json');
    final content = json.encode(_benchmarks.map((b) => b.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<void> addBenchmark(BenchmarkResult benchmark) async {
    _benchmarks.add(benchmark);
    await saveBenchmarks();
  }

  Future<void> clearAll() async {
    _reports.clear();
    _crashes.clear();
    _benchmarks.clear();
    await saveReports();
    await saveCrashes();
    await saveBenchmarks();
  }
}
