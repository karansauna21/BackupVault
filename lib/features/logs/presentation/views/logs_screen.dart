import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../logs_models.dart';
import '../../logs_provider.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();
  final TextEditingController _fileController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _errorCodeController = TextEditingController();
  final TextEditingController _workerController = TextEditingController();
  
  bool _showAdvancedFilters = false;
  
  // Maintenance configuration local state
  double _retentionDays = 30;
  double _maxDbSize = 50;
  bool _autoCleanup = true;
  bool _notifyCritical = true;
  bool _notifyRepeated = true;
  bool _notifyDbProblems = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set text controllers listeners to trigger search updates
    _keywordController.addListener(_onSearchChanged);
    _folderController.addListener(_onSearchChanged);
    _fileController.addListener(_onSearchChanged);
    _statusController.addListener(_onSearchChanged);
    _errorCodeController.addListener(_onSearchChanged);
    _workerController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordController.dispose();
    _folderController.dispose();
    _fileController.dispose();
    _statusController.dispose();
    _errorCodeController.dispose();
    _workerController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = ref.read(logsSearchQueryProvider);
    ref.read(logsSearchQueryProvider.notifier).update(query.copyWith(
      keyword: _keywordController.text.trim(),
      folder: _folderController.text.trim().isEmpty ? null : _folderController.text.trim(),
      file: _fileController.text.trim().isEmpty ? null : _fileController.text.trim(),
      status: _statusController.text.trim().isEmpty ? null : _statusController.text.trim(),
      errorCode: _errorCodeController.text.trim().isEmpty ? null : _errorCodeController.text.trim(),
      worker: _workerController.text.trim().isEmpty ? null : _workerController.text.trim(),
    ));
  }

  void _clearSearchFilters() {
    _keywordController.clear();
    _folderController.clear();
    _fileController.clear();
    _statusController.clear();
    _errorCodeController.clear();
    _workerController.clear();
    ref.read(logsSearchQueryProvider.notifier).reset();
    ref.read(logsFilterOptionsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final logsState = ref.watch(logsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, size: 28),
            const SizedBox(width: 12),
            Text(
              'Logs & Activity Center',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_outlined), text: 'Activity Center'),
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Log Inspector'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Log Statistics'),
            Tab(icon: Icon(Icons.build_circle_outlined), text: 'Maintenance'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Logs',
            onPressed: () => ref.read(logsControllerProvider.notifier).refreshLogs(),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export Logs',
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear All Logs',
            color: theme.colorScheme.error,
            onPressed: () => _showClearConfirmDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: logsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load system logs', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(err.toString(), style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(logsControllerProvider.notifier).loadLogs(),
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
        data: (allLogs) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildActivityCenterTab(theme, isDesktop),
              _buildLogInspectorTab(theme, isDesktop),
              _buildLogStatisticsTab(theme, isDesktop),
              _buildMaintenanceTab(theme),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 1: ACTIVITY CENTER
  // ==========================================

  Widget _buildActivityCenterTab(ThemeData theme, bool isDesktop) {
    final logs = ref.watch(filteredLogsProvider);
    final pinned = ref.watch(pinnedLogsProvider);
    final errors = ref.watch(logsErrorsProvider);

    // Group logs by time intervals
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    final todayLogs = logs.where((l) => l.timestamp.isAfter(today)).toList();
    final yesterdayLogs = logs.where((l) => l.timestamp.isAfter(yesterday) && l.timestamp.isBefore(today)).toList();
    final sevenDaysLogs = logs.where((l) => l.timestamp.isAfter(sevenDaysAgo) && l.timestamp.isBefore(yesterday)).toList();
    final thirtyDaysLogs = logs.where((l) => l.timestamp.isAfter(thirtyDaysAgo) && l.timestamp.isBefore(sevenDaysAgo)).toList();
    final olderLogs = logs.where((l) => l.timestamp.isBefore(thirtyDaysAgo)).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Timeline Panel
          Expanded(
            flex: 3,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Timeline', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Live Feed Active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          if (todayLogs.isNotEmpty) ...[
                            _buildTimeGroupHeader(theme, 'Today'),
                            ...todayLogs.map((l) => _buildTimelineTile(theme, l)),
                          ],
                          if (yesterdayLogs.isNotEmpty) ...[
                            _buildTimeGroupHeader(theme, 'Yesterday'),
                            ...yesterdayLogs.map((l) => _buildTimelineTile(theme, l)),
                          ],
                          if (sevenDaysLogs.isNotEmpty) ...[
                            _buildTimeGroupHeader(theme, 'Last 7 Days'),
                            ...sevenDaysLogs.map((l) => _buildTimelineTile(theme, l)),
                          ],
                          if (thirtyDaysLogs.isNotEmpty) ...[
                            _buildTimeGroupHeader(theme, 'Last 30 Days'),
                            ...thirtyDaysLogs.map((l) => _buildTimelineTile(theme, l)),
                          ],
                          if (olderLogs.isNotEmpty) ...[
                            _buildTimeGroupHeader(theme, 'Older'),
                            ...olderLogs.map((l) => _buildTimelineTile(theme, l)),
                          ],
                          if (logs.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 60.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.history_toggle_off_rounded, size: 64, color: theme.disabledColor),
                                    const SizedBox(height: 16),
                                    Text('No activities recorded yet', style: theme.textTheme.titleMedium),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Desktop sidebar details (Pinned / Important alerts)
          if (isDesktop) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Pinned Events Card
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber[700]),
                                const SizedBox(width: 8),
                                Text('Pinned Events', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: pinned.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No pinned logs. Tap the star icon on any log to pin it.',
                                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: pinned.length,
                                      itemBuilder: (context, index) => _buildSidebarLogTile(theme, pinned[index]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Critical Warnings / Error List Card
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_rounded, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Text('Critical Events', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: errors.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Hooray! No critical error events found.',
                                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: errors.length,
                                      itemBuilder: (context, index) => _buildSidebarLogTile(theme, errors[index]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeGroupHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(ThemeData theme, LogEntry log) {
    final levelColor = _getLevelColor(log.level);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(
          _getCategoryIcon(log.category),
          color: levelColor,
        ),
        title: Text(
          log.message,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${DateFormat('HH:mm:ss').format(log.timestamp)} - ${log.module.displayName} / ${log.category.displayName}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                log.isPinned ? Icons.star_rounded : Icons.star_border_rounded,
                color: log.isPinned ? Colors.amber[700] : null,
              ),
              onPressed: () => ref.read(logsControllerProvider.notifier).togglePinLog(log.id),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () => _showLogDetailsDialog(context, log),
      ),
    );
  }

  Widget _buildSidebarLogTile(ThemeData theme, LogEntry log) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(
          log.message,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp),
          style: theme.textTheme.bodySmall,
        ),
        onTap: () => _showLogDetailsDialog(context, log),
      ),
    );
  }

  // ==========================================
  // TAB 2: LOG INSPECTOR
  // ==========================================

  Widget _buildLogInspectorTab(ThemeData theme, bool isDesktop) {
    final search = ref.watch(logsSearchQueryProvider);
    final filters = ref.watch(logsFilterOptionsProvider);
    final logs = ref.watch(filteredLogsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Filter & Search Panel Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Main search row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keywordController,
                          decoration: InputDecoration(
                            hintText: 'Search logs...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: Icon(_showAdvancedFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded),
                        tooltip: 'Toggle Filters',
                        onPressed: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        icon: const Icon(Icons.clear_all_rounded),
                        tooltip: 'Clear Filters',
                        onPressed: _clearSearchFilters,
                      ),
                    ],
                  ),
                  
                  // Advanced filter sections
                  if (_showAdvancedFilters) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterField(controller: _folderController, label: 'Folder Name'),
                        _buildFilterField(controller: _fileController, label: 'Filename'),
                        _buildFilterField(controller: _statusController, label: 'Status'),
                        _buildFilterField(controller: _errorCodeController, label: 'Error Code'),
                        _buildFilterField(controller: _workerController, label: 'Worker ID'),
                        _buildDateRangePickerButton(theme, search),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 4),
                    _buildLogTypeChipsRow(theme, filters),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Logs count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${logs.length} matched log entries',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _clearSearchFilters,
                  child: const Text('Reset filters'),
                ),
              ],
            ),
          ),
          
          // Log List
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
              ),
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: theme.disabledColor),
                          const SizedBox(height: 16),
                          Text('No logs matches your query', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Try broadening your filters or keyword query', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final levelColor = _getLevelColor(log.level);
                        return ExpansionTile(
                          key: PageStorageKey<int>(log.id),
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: levelColor,
                            ),
                          ),
                          title: Text(
                            log.message,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp)} | Level: ${log.level.name.toUpperCase()} | Module: ${log.module.displayName}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  log.isPinned ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: log.isPinned ? Colors.amber[700] : null,
                                  size: 20,
                                ),
                                onPressed: () => ref.read(logsControllerProvider.notifier).togglePinLog(log.id),
                              ),
                              const Icon(Icons.expand_more_rounded),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp)),
                                    _buildDetailRow('LogLevel', log.level.name.toUpperCase()),
                                    _buildDetailRow('Module', log.module.displayName),
                                    _buildDetailRow('Category', log.category.displayName),
                                    if (log.sourceFile != null) _buildDetailRow('Source File', log.sourceFile!),
                                    if (log.destinationFile != null) _buildDetailRow('Destination File', log.destinationFile!),
                                    if (log.durationMs != null) _buildDetailRow('Duration', '${log.durationMs} ms'),
                                    if (log.workerId != null) _buildDetailRow('Worker ID', log.workerId!),
                                    if (log.fileSize != null) _buildDetailRow('File Size', '${log.fileSize} bytes'),
                                    if (log.sha256 != null) _buildDetailRow('SHA-256', log.sha256!),
                                    if (log.status != null) _buildDetailRow('Status', log.status!),
                                    if (log.errorCode != null) _buildDetailRow('Error Code', log.errorCode!),
                                    if (log.exceptionDetails != null && log.exceptionDetails!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Exception details:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        log.exceptionDetails!,
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField({required TextEditingController controller, required String label}) {
    return SizedBox(
      width: 140,
      height: 38,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangePickerButton(ThemeData theme, LogSearchQuery query) {
    final displayRange = query.dateRange;
    final label = displayRange == null
        ? 'Select Dates'
        : '${DateFormat('MM/dd').format(displayRange.start)} - ${DateFormat('MM/dd').format(displayRange.end)}';

    return TextButton.icon(
      icon: const Icon(Icons.date_range_rounded, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2025),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: query.dateRange,
        );
        if (picked != null) {
          ref.read(logsSearchQueryProvider.notifier).update(query.copyWith(dateRange: picked));
        }
      },
    );
  }

  Widget _buildLogTypeChipsRow(ThemeData theme, LogFilterOptions options) {
    return Wrap(
      spacing: 6,
      children: [
        FilterChip(
          label: const Text('Errors Only'),
          selected: options.showOnlyErrors,
          onSelected: (val) {
            ref.read(logsFilterOptionsProvider.notifier).update(options.copyWith(showOnlyErrors: val));
          },
        ),
        FilterChip(
          label: const Text('Warnings Only'),
          selected: options.showOnlyWarnings,
          onSelected: (val) {
            ref.read(logsFilterOptionsProvider.notifier).update(options.copyWith(showOnlyWarnings: val));
          },
        ),
        FilterChip(
          label: const Text('Success Only'),
          selected: options.showOnlySuccess,
          onSelected: (val) {
            ref.read(logsFilterOptionsProvider.notifier).update(options.copyWith(showOnlySuccess: val));
          },
        ),
        FilterChip(
          label: const Text('Important Only'),
          selected: options.showOnlyImportant,
          onSelected: (val) {
            ref.read(logsFilterOptionsProvider.notifier).update(options.copyWith(showOnlyImportant: val));
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: STATISTICS
  // ==========================================

  Widget _buildLogStatisticsTab(ThemeData theme, bool isDesktop) {
    final statsAsync = ref.watch(logsStatisticsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error computing stats: $e')),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Metrics Dashboard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Key KPI Cards Grid
              GridView.count(
                crossAxisCount: isDesktop ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(theme, 'Total Logs', stats.totalLogs.toString(), Icons.analytics_outlined, theme.colorScheme.primary),
                  _buildStatCard(theme, 'Errors', stats.errors.toString(), Icons.error_outline_rounded, theme.colorScheme.error),
                  _buildStatCard(theme, 'Warnings', stats.warnings.toString(), Icons.warning_amber_rounded, Colors.orange),
                  _buildStatCard(theme, 'Successful Backups', stats.successfulBackups.toString(), Icons.backup_outlined, Colors.green),
                  _buildStatCard(theme, 'Successful Restores', stats.successfulRestores.toString(), Icons.settings_backup_restore_rounded, Colors.teal),
                  _buildStatCard(theme, 'Avg Backup Duration', '${stats.averageBackupTimeMs} ms', Icons.timer_outlined, Colors.blue),
                  _buildStatCard(theme, 'Avg Restore Duration', '${stats.averageRestoreTimeMs} ms', Icons.update_rounded, Colors.indigo),
                  _buildStatCard(theme, 'Most Active Folder', stats.mostActiveFolder, Icons.folder_shared_outlined, Colors.purple),
                ],
              ),
              const SizedBox(height: 24),
              
              // Common Errors List
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Most Common Errors', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (stats.mostCommonErrors.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text('No logged errors recorded in current database.')),
                        )
                      else
                        ...stats.mostCommonErrors.entries.map((entry) {
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.bug_report_outlined, color: theme.colorScheme.error),
                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.value} times',
                                style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.15)),
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
                Icon(icon, color: color, size: 24),
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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

  // ==========================================
  // TAB 4: MAINTENANCE
  // ==========================================

  Widget _buildMaintenanceTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Database Maintenance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Auto Log Cleanup'),
                    subtitle: const Text('Automatically purge logs exceeding capacity policies'),
                    value: _autoCleanup,
                    onChanged: (val) => setState(() => _autoCleanup = val),
                  ),
                  const Divider(),
                  
                  // Retention Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Log Retention Period', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_retentionDays.toInt()} Days', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Slider(
                          min: 7,
                          max: 180,
                          divisions: 173,
                          value: _retentionDays,
                          onChanged: (val) => setState(() => _retentionDays = val),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Max Database Size Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Maximum Database Log Size Cap', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_maxDbSize.toInt()} MB', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Slider(
                          min: 10,
                          max: 200,
                          divisions: 19,
                          value: _maxDbSize,
                          onChanged: (val) => setState(() => _maxDbSize = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Text('Alert & Notification Channels', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Notify on Critical Errors'),
                    subtitle: const Text('Prompt desktop banner notifications on task crash/fails'),
                    value: _notifyCritical,
                    onChanged: (val) => setState(() => _notifyCritical = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Notify on Repeated Failures'),
                    subtitle: const Text('Alert if a worker fails multiple times sequentially'),
                    value: _notifyRepeated,
                    onChanged: (val) => setState(() => _notifyRepeated = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Notify on Database Problems'),
                    subtitle: const Text('Report sqlite database locks or sync anomalies'),
                    value: _notifyDbProblems,
                    onChanged: (val) => setState(() => _notifyDbProblems = val ?? true),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.cleaning_services_rounded),
                label: const Text('Execute Manual Purge Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final notifier = ref.read(logsControllerProvider.notifier);
                  final deletedCount = await notifier.deleteOldLogs(_retentionDays.toInt());
                  messenger.showSnackBar(
                    SnackBar(content: Text('Successfully purged $deletedCount legacy log entries.')),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Maintenance Settings'),
                onPressed: () {
                  final config = MaintenanceConfig(
                    autoCleanupEnabled: _autoCleanup,
                    logRetentionDays: _retentionDays.toInt(),
                    maxDatabaseSizeMb: _maxDbSize.toInt(),
                  );
                  ref.read(logsControllerProvider.notifier).runAutoCleanup(config);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maintenance policies updated successfully!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOGS EXPORT DIALOG
  // ==========================================

  void _showExportDialog(BuildContext context) {
    String format = 'txt';
    String customFileName = 'backupvault_logs_export';
    DateTimeRange? dateRange;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.file_download_outlined),
                  SizedBox(width: 8),
                  Text('Export logs file'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File type selection
                  const Text('Select Format:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['TXT', 'CSV', 'JSON', 'ZIP'].map((f) {
                      final isSel = format.toUpperCase() == f;
                      return ChoiceChip(
                        label: Text(f),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setDialogState(() => format = f.toLowerCase());
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // File name text field
                  const Text('Filename:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'backupvault_logs_export',
                    ),
                    onChanged: (val) => customFileName = val.trim(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date range selector
                  const Text('Date Range Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(dateRange == null
                        ? 'All Dates'
                        : '${DateFormat('yyyy-MM-dd').format(dateRange!.start)} to ${DateFormat('yyyy-MM-dd').format(dateRange!.end)}'),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setDialogState(() => dateRange = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final controller = ref.read(logsControllerProvider.notifier);
                    
                    // Filter logs to export based on selected range
                    final allLogs = ref.read(filteredLogsProvider);
                    final toExport = allLogs.where((l) {
                      if (dateRange != null) {
                        final end = dateRange!.end.add(const Duration(days: 1));
                        return l.timestamp.isAfter(dateRange!.start) && l.timestamp.isBefore(end);
                      }
                      return true;
                    }).toList();

                    final tempDir = await getTemporaryDirectory();
                    final path = await controller.exportLogs(
                      logsToExport: toExport,
                      format: format,
                      targetDirectory: tempDir.path,
                      customFileName: customFileName.isEmpty ? null : customFileName,
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logs Exported Successfully'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('The exported file has been written to:'),
                              const SizedBox(height: 8),
                              SelectableText(
                                path,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Export File'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // HELPER METHODS & WIDGETS
  // ==========================================

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.success:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.system:
        return Colors.deepPurple;
      case LogLevel.debug:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(LogCategory cat) {
    switch (cat) {
      case LogCategory.backupStarted:
      case LogCategory.backupCompleted:
      case LogCategory.backupFailed:
        return Icons.backup_outlined;
      case LogCategory.restoreStarted:
      case LogCategory.restoreCompleted:
      case LogCategory.restoreFailed:
        return Icons.settings_backup_restore_rounded;
      case LogCategory.folderAdded:
        return Icons.create_new_folder_outlined;
      case LogCategory.folderRemoved:
        return Icons.folder_delete_outlined;
      case LogCategory.folderModified:
        return Icons.folder_shared_outlined;
      case LogCategory.watcherStarted:
      case LogCategory.watcherStopped:
        return Icons.remove_red_eye_outlined;
      case LogCategory.workerStarted:
      case LogCategory.workerStopped:
        return Icons.engineering_outlined;
      case LogCategory.settingsChanged:
        return Icons.settings_outlined;
      case LogCategory.startup:
        return Icons.power_settings_new_rounded;
      case LogCategory.shutdown:
        return Icons.power_off_rounded;
      case LogCategory.crash:
        return Icons.dangerous_outlined;
      case LogCategory.warning:
        return Icons.warning_amber_rounded;
      case LogCategory.information:
        return Icons.info_outline;
      case LogCategory.databaseEvents:
        return Icons.storage_outlined;
      default:
        return Icons.history_edu_outlined;
    }
  }

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('Are you sure you want to permanently clear the logs database? This operation is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(logsControllerProvider.notifier).clearLogs();
              Navigator.pop(context);
            },
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );
  }

  void _showLogDetailsDialog(BuildContext context, LogEntry log) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getCategoryIcon(log.category), color: _getLevelColor(log.level)),
            const SizedBox(width: 8),
            Text(log.category.displayName),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp)),
                _buildDetailRow('LogLevel', log.level.name.toUpperCase()),
                _buildDetailRow('Module', log.module.displayName),
                _buildDetailRow('Message', log.message),
                if (log.sourceFile != null) _buildDetailRow('Source File', log.sourceFile!),
                if (log.destinationFile != null) _buildDetailRow('Destination File', log.destinationFile!),
                if (log.durationMs != null) _buildDetailRow('Duration', '${log.durationMs} ms'),
                if (log.workerId != null) _buildDetailRow('Worker ID', log.workerId!),
                if (log.fileSize != null) _buildDetailRow('File Size', '${log.fileSize} bytes'),
                if (log.sha256 != null) _buildDetailRow('SHA-256', log.sha256!),
                if (log.status != null) _buildDetailRow('Status', log.status!),
                if (log.errorCode != null) _buildDetailRow('Error Code', log.errorCode!),
                if (log.exceptionDetails != null && log.exceptionDetails!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Exception/Stacktrace:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: SelectableText(
                      log.exceptionDetails!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
