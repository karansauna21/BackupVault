import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:backup_vault/core/database/app_database.dart';
import '../../statistics_models.dart';
import '../../statistics_provider.dart';
import '../../statistics_controller.dart';
import '../widgets/chart_widgets.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _LogsFilterDialog extends StatefulWidget {
  final StatisticsFilter initialFilter;
  final List<BackupFolder> folders;

  const _LogsFilterDialog({
    required this.initialFilter,
    required this.folders,
  });

  @override
  State<_LogsFilterDialog> createState() => _LogsFilterDialogState();
}

class _LogsFilterDialogState extends State<_LogsFilterDialog> {
  int? _folderId;
  DateTimeRange? _dateRange;
  String? _fileType;
  String? _status;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _folderId = widget.initialFilter.folderId;
    _dateRange = widget.initialFilter.dateRange;
    _fileType = widget.initialFilter.fileType;
    _status = widget.initialFilter.status;
    _workerId = widget.initialFilter.workerId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.filter_alt_rounded),
          SizedBox(width: 8),
          Text('Filter Analytics'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _folderId,
              decoration: const InputDecoration(labelText: 'Monitored Folder'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Folders')),
                ...widget.folders.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name),
                    )),
              ],
              onChanged: (val) => setState(() => _folderId = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'success', child: Text('Success')),
                DropdownMenuItem(value: 'failed', child: Text('Failed')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
              ],
              onChanged: (val) => setState(() => _status = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _workerId,
              decoration: const InputDecoration(labelText: 'Worker'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Workers')),
                DropdownMenuItem(value: 'Worker #1', child: Text('Worker #1')),
                DropdownMenuItem(value: 'Worker #2', child: Text('Worker #2')),
                DropdownMenuItem(value: 'Worker #3', child: Text('Worker #3')),
              ],
              onChanged: (val) => setState(() => _workerId = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _fileType,
              decoration: const InputDecoration(
                labelText: 'File Type (e.g. TXT, ZIP)',
                hintText: 'Enter extension',
              ),
              onChanged: (val) => _fileType = val.trim().isEmpty ? null : val.trim(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(_dateRange == null
                      ? 'Select Range'
                      : '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              StatisticsFilter(
                folderId: _folderId,
                dateRange: _dateRange,
                fileType: _fileType,
                status: _status,
                workerId: _workerId,
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ExportDialog extends StatefulWidget {
  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String _format = 'csv';
  final _fileNameController = TextEditingController(text: 'backupvault_analytics_report');

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download_outlined),
          SizedBox(width: 8),
          Text('Export Analytics Report'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _fileNameController,
            decoration: const InputDecoration(
              labelText: 'Filename Prefix',
              hintText: 'Enter report name',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _format,
            decoration: const InputDecoration(labelText: 'Export Format'),
            items: const [
              DropdownMenuItem(value: 'csv', child: Text('CSV (Comma Separated)')),
              DropdownMenuItem(value: 'json', child: Text('JSON (Structured Data)')),
              DropdownMenuItem(value: 'pdf', child: Text('HTML (Printable PDF)')),
            ],
            onChanged: (val) => setState(() => _format = val ?? 'csv'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'format': _format,
              'fileName': _fileNameController.text.trim(),
            });
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BackupFolder> _folders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final rawFolders = await ref.read(statisticsRepositoryProvider).getAllFolders();
    if (mounted) {
      setState(() => _folders = rawFolders);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterDialog(StatisticsFilter filter) async {
    final result = await showDialog<StatisticsFilter>(
      context: context,
      builder: (context) => _LogsFilterDialog(initialFilter: filter, folders: _folders),
    );
    if (result != null) {
      ref.read(statisticsFilterProvider.notifier).update(result);
    }
  }

  void _showExportDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ExportDialog(),
    );

    if (result != null && mounted) {
      final format = result['format'] ?? 'csv';
      final fileName = result['fileName'] ?? 'report';

      try {
        final path = await ref.read(statisticsControllerProvider.notifier).exportReport(
              format: format,
              customFileName: fileName,
            );

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Report Exported'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your analytics report was saved to:'),
                  const SizedBox(height: 8),
                  SelectableText(
                    path,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 11),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to export report: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(statisticsFilterProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final statsAsync = ref.watch(backupStatsProvider);
    final storageAsync = ref.watch(storageAnalysisProvider);
    final performanceAsync = ref.watch(performanceAnalysisProvider);
    final healthAsync = ref.watch(backupHealthProvider);
    final chartsAsync = ref.watch(chartsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Statistics & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(filter.isEmpty ? Icons.filter_alt_outlined : Icons.filter_alt,
                color: filter.isEmpty ? null : theme.colorScheme.primary),
            tooltip: 'Filter Statistics',
            onPressed: () => _showFilterDialog(filter),
          ),
          if (!filter.isEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear Filters',
              onPressed: () => ref.read(statisticsFilterProvider.notifier).reset(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh All',
            onPressed: () => ref.read(statisticsControllerProvider.notifier).refreshAll(),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Reports',
            onPressed: _showExportDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Charts & Trends', icon: Icon(Icons.bar_chart_rounded)),
            Tab(text: 'Storage Analysis', icon: Icon(Icons.storage_rounded)),
            Tab(text: 'Performance', icon: Icon(Icons.speed_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(statsAsync, healthAsync, theme, isDesktop),
          _buildChartsTab(chartsAsync, theme, isDesktop),
          _buildStorageTab(storageAsync, theme, isDesktop),
          _buildPerformanceTab(performanceAsync, theme, isDesktop),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & HEALTH
  // ==========================================

  Widget _buildOverviewTab(
    AsyncValue<BackupStats> statsAsync,
    AsyncValue<BackupHealth> healthAsync,
    ThemeData theme,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health score card row
          healthAsync.when(
            data: (health) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    HealthDial(score: health.score),
                    const SizedBox(width: 32, height: 24),
                    Expanded(
                      flex: isDesktop ? 1 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Backup Health Score Summary',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'This score represents the general state of your file backups, file versions, disk size limits, database exceptions, and watcher status.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          if (health.recommendations.isNotEmpty) ...[
                            Text('Recommendations:',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            ...health.recommendations.take(2).map((r) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(r.icon, size: 16, color: _getSeverityColor(r.severity)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(r.title,
                                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                                    ],
                                  ),
                                )),
                          ] else
                            const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('System is in optimal condition! No recommendations.',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load health score: $e')),
          ),
          const SizedBox(height: 24),

          // Dashboard cards grid
          Text('Dashboard Metrics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          statsAsync.when(
            data: (stats) => GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(theme, 'Total Monitored Size', _formatBytes(stats.totalBackupSize), Icons.inventory_2_outlined),
                _buildMetricCard(theme, 'Backed Up Today', _formatBytes(stats.todaysBackupSize), Icons.today_rounded),
                _buildMetricCard(theme, 'Weekly Volume', _formatBytes(stats.weeklyBackupSize), Icons.view_week_outlined),
                _buildMetricCard(theme, 'Monthly Volume', _formatBytes(stats.monthlyBackupSize), Icons.calendar_month_outlined),
                _buildMetricCard(theme, 'Total Monitored Files', '${stats.totalFiles}', Icons.file_present_rounded),
                _buildMetricCard(theme, 'Files Today', '${stats.backedUpToday}', Icons.edit_calendar_rounded),
                _buildMetricCard(theme, 'Versioned Files', '${stats.versionedFilesCount}', Icons.history_rounded),
                _buildMetricCard(theme, 'Duplicate Files', '${stats.duplicateFilesCount}', Icons.file_copy_outlined),
                _buildMetricCard(theme, 'Skipped Files', '${stats.skippedFilesCount}', Icons.skip_next_rounded),
                _buildMetricCard(theme, 'Failed Files', '${stats.failedFilesCount}', Icons.dangerous_outlined,
                    color: stats.failedFilesCount > 0 ? Colors.red : null),
                _buildMetricCard(theme, 'Restored Files', '${stats.restoredFilesCount}', Icons.settings_backup_restore_rounded),
                _buildMetricCard(theme, 'Monitored Folders', '${stats.foldersMonitored}', Icons.folder_copy_outlined),
                _buildMetricCard(theme, 'Current Queue', '${stats.currentQueueCount}', Icons.hourglass_empty_rounded),
                _buildMetricCard(theme, 'Storage Used', _formatBytes(stats.storageUsedBytes), Icons.storage_rounded),
                _buildMetricCard(theme, 'Storage Available', _formatBytes(stats.storageAvailableBytes), Icons.cloud_done_rounded,
                    color: stats.storageAvailableBytes < 10 * 1024 * 1024 * 1024 ? Colors.orange : null),
                _buildMetricCard(theme, 'Avg Backup Speed', '${stats.averageBackupSpeed.toStringAsFixed(1)} MB/s', Icons.speed_rounded),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load metrics: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(ThemeData theme, String label, String value, IconData icon, {Color? color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
                Text('', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.blue;
    }
  }

  // ==========================================
  // TAB 2: CHARTS & TRENDS
  // ==========================================

  Widget _buildChartsTab(AsyncValue<AnalyticsCharts> chartsAsync, ThemeData theme, bool isDesktop) {
    return chartsAsync.when(
      data: (charts) {
        final gridCount = isDesktop ? 2 : 1;
        return GridView.count(
          padding: const EdgeInsets.all(16.0),
          crossAxisCount: gridCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            GradientAreaChart(
              title: 'Daily Backup Trend (MB)',
              data: charts.dailyBackupTrend,
              themeColor: theme.colorScheme.primary,
            ),
            GradientAreaChart(
              title: 'Storage Growth Trend (MB)',
              data: charts.storageGrowth,
              themeColor: theme.colorScheme.secondary,
            ),
            DistributionBarChart(
              title: 'File Type Distribution (MB)',
              data: charts.fileTypeDistribution,
              themeColor: theme.colorScheme.tertiary,
            ),
            DistributionBarChart(
              title: 'Folder Size Distribution (MB)',
              data: charts.folderSizeDistribution,
              themeColor: theme.colorScheme.secondary,
            ),
            DonutChart(
              title: 'Backup Success Rate',
              data: charts.backupSuccessRate,
            ),
            GradientAreaChart(
              title: 'Error Trend (Daily count)',
              data: charts.errorTrend,
              themeColor: Colors.red,
            ),
            GradientAreaChart(
              title: 'Backup Transfer Speeds (MB/s)',
              data: charts.backupSpeed,
              themeColor: Colors.teal,
            ),
            GradientAreaChart(
              title: 'Queue latency (Seconds)',
              data: charts.queuePerformance,
              themeColor: Colors.deepPurple,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load charts: $e')),
    );
  }

  // ==========================================
  // TAB 3: STORAGE ANALYSIS
  // ==========================================

  Widget _buildStorageTab(AsyncValue<StorageAnalysis> storageAsync, ThemeData theme, bool isDesktop) {
    return storageAsync.when(
      data: (storage) => ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Growth card row
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    storage.isLowStoragePredicted ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    size: 40,
                    color: storage.isLowStoragePredicted ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Future Space Estimates & Low Storage Warnings',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          storage.isLowStoragePredicted
                              ? 'Action Required: Free storage space immediately. Remaining days estimated: ${storage.estimatedRemainingDays == -1 ? "N/A" : storage.estimatedRemainingDays} days.'
                              : 'System storage looks stable. Estimated remaining days at current usage rate: ${storage.estimatedRemainingDays == -1 ? "Infinite / Stable" : "${storage.estimatedRemainingDays} Days"}.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Storage Optimization Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: isDesktop ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildAnalysisSubcard(theme, 'Most Active Folder', storage.mostActiveFolder, Icons.flash_on_rounded),
              _buildAnalysisSubcard(theme, 'Least Active Folder', storage.leastActiveFolder, Icons.snooze_rounded),
              _buildAnalysisSubcard(theme, 'Saved deduplicated space', _formatBytes(storage.duplicateStorageSavedBytes), Icons.verified_user_rounded),
            ],
          ),
          const SizedBox(height: 24),

          // Lists tables
          Text('Largest Monitored Folders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DataTable(
            columns: const [
              DataColumn(label: Text('Folder')),
              DataColumn(label: Text('Path')),
              DataColumn(label: Text('Size')),
            ],
            rows: storage.largestFolders.map((f) {
              return DataRow(cells: [
                DataCell(Text(f.name)),
                DataCell(Text(f.path)),
                DataCell(Text(_formatBytes(f.sizeBytes))),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 24),

          Text('Largest Monitored Files', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DataTable(
            columns: const [
              DataColumn(label: Text('File Name')),
              DataColumn(label: Text('Path')),
              DataColumn(label: Text('Size')),
            ],
            rows: storage.largestFiles.map((f) {
              return DataRow(cells: [
                DataCell(Text(f.name)),
                DataCell(Text(f.path)),
                DataCell(Text(_formatBytes(f.sizeBytes))),
              ]);
            }).toList(),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load storage analysis: $e')),
    );
  }

  Widget _buildAnalysisSubcard(ThemeData theme, String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: PERFORMANCE ANALYSIS
  // ==========================================

  Widget _buildPerformanceTab(AsyncValue<PerformanceAnalysis> perfAsync, ThemeData theme, bool isDesktop) {
    return perfAsync.when(
      data: (perf) => ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Hardware stats
          Text('System Hardware Load (Future-Ready)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProgressLoadCard(theme, 'CPU Resource Allocation', perf.cpuUsagePercent / 100.0, '${perf.cpuUsagePercent}%'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressLoadCard(theme, 'RAM Resource Allocation', perf.ramUsagePercent / 100.0, '${perf.ramUsagePercent}%'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Speed details
          Text('Performance Aggregations', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: isDesktop ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildAnalysisSubcard(theme, 'Avg Copy Transfer Speed', '${perf.averageCopySpeedMbps.toStringAsFixed(1)} MB/s', Icons.trending_up_rounded),
              _buildAnalysisSubcard(theme, 'Avg Hash Verification', '${perf.averageVerifyTimeSeconds.toStringAsFixed(2)} seconds', Icons.verified_user_sharp),
              _buildAnalysisSubcard(theme, 'Avg Restore Duration', '${perf.averageRestoreTimeSeconds.toStringAsFixed(2)} seconds', Icons.restore_rounded),
            ],
          ),
          const SizedBox(height: 24),

          // Job speed breakdown
          Text('Fastest Monitored Transfer Jobs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DataTable(
            columns: const [
              DataColumn(label: Text('Job Name')),
              DataColumn(label: Text('Measured Speed')),
              DataColumn(label: Text('Total Size')),
            ],
            rows: perf.fastestJobs.map((j) {
              return DataRow(cells: [
                DataCell(Text(j.jobName)),
                DataCell(Text('${j.speedMbps.toStringAsFixed(1)} MB/s')),
                DataCell(Text(_formatBytes(j.sizeBytes))),
              ]);
            }).toList(),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load performance analysis: $e')),
    );
  }

  Widget _buildProgressLoadCard(ThemeData theme, String label, double progress, String value) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}
