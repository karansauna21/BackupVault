import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'diagnostics_models.dart';
import 'diagnostics_provider.dart';
import 'diagnostics_controller.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, String> _testResults = {};
  bool _runningTests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(diagnosticsControllerProvider).init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final health = ref.watch(healthStatusProvider);
    final metrics = ref.watch(performanceMetricsProvider);
    final report = ref.watch(diagnosticsReportProvider);
    final crashes = ref.watch(crashReportsProvider);
    final benchmarks = ref.watch(benchmarkResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.analytics_rounded, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Self-Diagnostics & Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshAll(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
            tooltip: 'Clear History',
            onPressed: () => _clearHistory(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.speed_rounded), text: 'Dashboard & Scores'),
            Tab(icon: Icon(Icons.health_and_safety_rounded), text: 'Health & Monitors'),
            Tab(icon: Icon(Icons.query_stats_rounded), text: 'Stress & Benchmarks'),
            Tab(icon: Icon(Icons.bug_report_rounded), text: 'Recovery & Tests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(theme, report),
                _buildHealthMonitors(theme, health, metrics),
                _buildBenchmarks(theme, benchmarks),
                _buildRecoveryAndTests(theme, crashes),
              ],
            ),
    );
  }

  // --- 1. Dashboard & Recommendations Tab ---
  Widget _buildDashboard(ThemeData theme, DiagnosticsReport? report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('One-Click Diagnostics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _runOneClick(),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Run Diagnostics Suite'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (report == null)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.query_stats_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text('No diagnostics run yet. Click "Run Diagnostics Suite" to evaluate system metrics.'),
                  ],
                ),
              ),
            )
          else ...[
            // Scores Grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildScoreCard(theme, 'Overall System', report.overallSystemScore, Colors.blue),
                _buildScoreCard(theme, 'System Health', report.healthScore, Colors.green),
                _buildScoreCard(theme, 'Performance', report.performanceScore, Colors.purple),
                _buildScoreCard(theme, 'Database', report.databaseScore, Colors.orange),
                _buildScoreCard(theme, 'Storage', report.storageScore, Colors.teal),
              ],
            ),
            const SizedBox(height: 32),

            // Recommendations
            Text('Recommendations for Improvement', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: report.recommendations.map((rec) {
                    final isOptimal = rec.contains('optimally');
                    return ListTile(
                      leading: Icon(
                        isOptimal ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: isOptimal ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        rec,
                        style: TextStyle(fontWeight: isOptimal ? FontWeight.normal : FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCard(ThemeData theme, String title, int score, Color color) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$score%',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: 32),
                ),
                CircularProgressIndicator(
                  value: score / 100.0,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.1),
                  strokeWidth: 5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Health Cards & Monitors Tab ---
  Widget _buildHealthMonitors(ThemeData theme, SystemHealthStatus health, PerformanceMetrics metrics) {
    final statusMap = {
      'Backup Engine': health.backupEngineStatus,
      'Restore Engine': health.restoreEngineStatus,
      'File Watcher': health.fileWatcherStatus,
      'Scheduler': health.schedulerStatus,
      'Notification Service': health.notificationStatus,
      'SQLite Database': health.databaseStatus,
      'Background Service': health.backgroundStatus,
      'System Tray': health.systemTrayStatus,
      'Storage Devices': health.storageStatus,
      'Configuration': health.configurationStatus,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monitors Section
          Text('System Performance Monitors', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildMonitorCard(theme, 'CPU Load', '${metrics.cpuUsagePercent.toStringAsFixed(1)}%', Icons.developer_board_rounded, Colors.blue, metrics.cpuUsagePercent / 100.0),
              _buildMonitorCard(theme, 'RAM Usage', '${metrics.ramUsageMb.toStringAsFixed(0)} MB', Icons.memory_rounded, Colors.green, (metrics.ramUsageMb / 1024.0).clamp(0.0, 1.0)),
              _buildMonitorCard(theme, 'Storage Capacity', '${metrics.diskUsagePercent.toStringAsFixed(1)}%', Icons.storage_rounded, Colors.purple, metrics.diskUsagePercent / 100.0),
              _buildMonitorCard(theme, 'Disk Read / Write Speed', '${metrics.diskReadSpeedMbPerSec.toStringAsFixed(1)} / ${metrics.diskWriteSpeedMbPerSec.toStringAsFixed(1)} MB/s', Icons.speed_rounded, Colors.teal, null),
              _buildMonitorCard(theme, 'Active Backup / Restore Speed', '${metrics.backupSpeedMbPerSec.toStringAsFixed(1)} / ${metrics.restoreSpeedMbPerSec.toStringAsFixed(1)} MB/s', Icons.swap_calls_rounded, Colors.orange, null),
              _buildMonitorCard(theme, 'Database Query Time', '${metrics.databaseQuerySpeedMs.toStringAsFixed(1)} ms', Icons.dns_rounded, Colors.blueGrey, (metrics.databaseQuerySpeedMs / 100.0).clamp(0.0, 1.0)),
            ],
          ),
          const SizedBox(height: 32),

          // Health Cards
          Text('Integrity Health Diagnostics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: statusMap.entries.map((e) {
                final isHealthy = e.value == 'Healthy';
                final isWarning = e.value.contains('Warning');

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isHealthy
                        ? Colors.green.withValues(alpha: 0.1)
                        : (isWarning ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                    child: Icon(
                      isHealthy ? Icons.check_circle_rounded : (isWarning ? Icons.warning_rounded : Icons.cancel_rounded),
                      color: isHealthy ? Colors.green : (isWarning ? Colors.orange : Colors.red),
                    ),
                  ),
                  title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status check verification value: ${e.value}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHealthy
                          ? Colors.green.withValues(alpha: 0.15)
                          : (isWarning ? Colors.orange.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.value.toUpperCase(),
                      style: TextStyle(
                        color: isHealthy ? Colors.green : (isWarning ? Colors.orange : Colors.red),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorCard(ThemeData theme, String title, String value, IconData icon, Color color, double? progress) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Stress Testing & Benchmarks Tab ---
  Widget _buildBenchmarks(ThemeData theme, List<BenchmarkResult> benchmarks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stress Test Simulator', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showBenchmarkWizard(),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('New Benchmark Test'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (benchmarks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.query_stats_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text('No benchmarks recorded. Run a test to evaluate file read/write performance under load.'),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: benchmarks.length,
              itemBuilder: (context, index) {
                final bm = benchmarks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.speed_rounded)),
                    title: Text(bm.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Files: ${bm.filesCount} | Size: ${bm.totalSizeMb.toStringAsFixed(1)} MB | Time: ${bm.durationSeconds.toStringAsFixed(2)}s | Speed: ${bm.speedMbPerSec.toStringAsFixed(1)} MB/s',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _exportReport(bm, 'PDF'),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                          label: const Text('PDF'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _exportReport(bm, 'CSV'),
                          icon: const Icon(Icons.table_view_rounded, size: 16),
                          label: const Text('CSV'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _exportReport(bm, 'JSON'),
                          icon: const Icon(Icons.code_rounded, size: 16),
                          label: const Text('JSON'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 4. Recovery & Diagnostics Test Suite Tab ---
  Widget _buildRecoveryAndTests(ThemeData theme, List<CrashReport> crashes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Continuous Integration Tests', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _runningTests ? null : () => _runDiagnosticSuite(),
                icon: const Icon(Icons.playlist_play_rounded),
                label: Text(_runningTests ? 'Running Suite...' : 'Run Test Suite'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_testResults.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _testResults.entries.map((e) {
                  final isPass = e.value == 'Passed';
                  return ListTile(
                    leading: Icon(
                      isPass ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: isPass ? Colors.green : Colors.red,
                    ),
                    title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      e.value,
                      style: TextStyle(
                        color: isPass ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Simulated Crash Recovery Diagnostics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                onPressed: () => _triggerCrashDialog(),
                icon: const Icon(Icons.flash_on_rounded, color: Colors.red),
                label: const Text('Simulate Failure', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (crashes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text('No crash/recovery records exist. Use "Simulate Failure" to test automatic healing.'),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: crashes.length,
              itemBuilder: (context, index) {
                final c = crashes[index];
                final isRecovered = c.recoveryStatus == 'Recovered';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: isRecovered
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      child: Icon(
                        isRecovered ? Icons.healing_rounded : Icons.report_problem_rounded,
                        color: isRecovered ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text('${c.type}: ${c.message}'),
                    subtitle: Text('Occurred: ${c.timestamp.toLocal()}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRecovered
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.recoveryStatus.toUpperCase(),
                        style: TextStyle(
                          color: isRecovered ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            'Stack Trace:\n${c.stackTrace}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Controls & Logic Handlers ---
  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    await ref.read(diagnosticsControllerProvider).refreshMetrics();
    setState(() => _isLoading = false);
  }

  Future<void> _clearHistory() async {
    await ref.read(diagnosticsControllerProvider).clearHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics history cleared successfully.')),
    );
  }

  Future<void> _runOneClick() async {
    setState(() => _isLoading = true);
    await ref.read(diagnosticsControllerProvider).runOneClickDiagnostics();
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('One-click self-diagnostics completed!')),
    );
  }

  void _showBenchmarkWizard() {
    int filesCount = 1000;
    double sizeMb = 100.0;
    String name = 'Fast Write Benchmark';
    String type = 'custom';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Execute New Stress Benchmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Simulated File Count scale'),
              initialValue: filesCount,
              items: const [
                DropdownMenuItem(value: 100, child: Text('100 Files (Light)')),
                DropdownMenuItem(value: 1000, child: Text('1,000 Files (Medium)')),
                DropdownMenuItem(value: 10000, child: Text('10,000 Files (Heavy)')),
                DropdownMenuItem(value: 100000, child: Text('100,000 Files (Critical Stress)')),
              ],
              onChanged: (val) => filesCount = val ?? filesCount,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              decoration: const InputDecoration(labelText: 'Target File Data Size scale'),
              initialValue: sizeMb,
              items: const [
                DropdownMenuItem(value: 10.0, child: Text('10 MB')),
                DropdownMenuItem(value: 100.0, child: Text('100 MB')),
                DropdownMenuItem(value: 1024.0, child: Text('1 GB')),
                DropdownMenuItem(value: 10240.0, child: Text('10 GB (Huge File Load)')),
              ],
              onChanged: (val) => sizeMb = val ?? sizeMb,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Report Interval Schedule'),
              initialValue: type,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily Performance')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly Performance')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly Performance')),
                DropdownMenuItem(value: 'custom', child: Text('Custom Stress Test')),
              ],
              onChanged: (val) => type = val ?? type,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              if (filesCount == 100000) {
                name = 'Critical File Watcher stress-test';
              } else if (sizeMb == 10240.0) {
                name = '10GB archive write-speed test';
              } else {
                name = 'I/O throughput Benchmark';
              }

              await ref.read(diagnosticsControllerProvider).executeBenchmark(
                name: name,
                filesCount: filesCount,
                sizeMb: sizeMb,
                type: type,
              );
              setState(() => _isLoading = false);
            },
            child: const Text('Run Benchmark'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(BenchmarkResult result, String format) async {
    final path = await ref.read(diagnosticsControllerProvider).exportBenchmark(result, format);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export $format Successful'),
        content: Text('Report has been written to path:\n\n$path'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnosticSuite() async {
    setState(() => _runningTests = true);
    final results = await ref.read(diagnosticsControllerProvider).runDiagnosticsTests();
    if (!mounted) return;
    setState(() {
      _testResults = results;
      _runningTests = false;
    });
  }

  void _triggerCrashDialog() {
    String type = 'Database Failure';
    String message = 'SQLite file descriptor lock timed out.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulate System Failure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Failure Target'),
              items: const [
                DropdownMenuItem(value: 'Database Failure', child: Text('Database Lock / Write Failure')),
                DropdownMenuItem(value: 'Watcher Failure', child: Text('File Watcher handle leak')),
                DropdownMenuItem(value: 'Unexpected Shutdown', child: Text('Power interruption crash')),
              ],
              onChanged: (val) => type = val ?? type,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: message,
              decoration: const InputDecoration(labelText: 'Error Message details'),
              onChanged: (val) => message = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await ref.read(diagnosticsControllerProvider).triggerSimulatedCrash(type, message);
              setState(() => _isLoading = false);
            },
            child: const Text('Trigger Crash'),
          ),
        ],
      ),
    );
  }
}
