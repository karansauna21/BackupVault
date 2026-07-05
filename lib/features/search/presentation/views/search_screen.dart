import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/core/restore/restore_job.dart';
import 'package:backup_vault/core/restore/restore_queue.dart';
import '../../search_models.dart';
import '../../search_provider.dart';
import '../../search_controller.dart' as app_search;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late app_search.SearchController _controller;
  bool _isGridView = false;
  bool _showSuggestions = false;

  // Local filter states
  int? _folderId;
  String? _fileType;
  DateTimeRange? _dateRange;
  int? _minSize;
  int? _maxSize;
  String? _backupStatus;
  String? _logLevel;

  @override
  void initState() {
    super.initState();
    _controller = app_search.SearchController(ref);
    _textController.addListener(_onTextChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showSuggestions = _textController.text.isNotEmpty || _searchFocusNode.hasFocus;
    });
    _controller.updateQuery(_textController.text);
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus;
    });
  }

  void _applyFilters() {
    _controller.updateFilter(SearchFilter(
      folderId: _folderId,
      fileType: _fileType?.trim().isEmpty == true ? null : _fileType,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      minSize: _minSize,
      maxSize: _maxSize,
      backupStatus: _backupStatus,
      logLevel: _logLevel,
    ));
  }

  void _resetFilters() {
    setState(() {
      _folderId = null;
      _fileType = null;
      _dateRange = null;
      _minSize = null;
      _maxSize = null;
      _backupStatus = null;
      _logLevel = null;
    });
    _controller.resetFilters();
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  void _openFileLocation(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      final dirPath = file.parent.path;
      if (Platform.isWindows) {
        // Highlight the file in Explorer if it exists, otherwise open parent folder
        if (await file.exists()) {
          await Process.run('explorer.exe', ['/select,', path]);
        } else if (await Directory(dirPath).exists()) {
          await Process.run('explorer.exe', [dirPath]);
        } else {
          throw Exception('Target path or parent directory does not exist.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open location: $e')),
        );
      }
    }
  }

  void _copyToClipboard(String? text) {
    if (text == null) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied path to clipboard')),
    );
  }

  void _restoreItem(SearchResultItem item) {
    final fileId = item.rawData is BackupFile
        ? (item.rawData as BackupFile).id
        : (item.rawData is FileVersion ? (item.rawData as FileVersion).fileId : 0);

    final sha256 = item.rawData is BackupFile
        ? (item.rawData as BackupFile).sha256
        : (item.rawData is FileVersion ? '' : '');

    final job = RestoreJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileId: fileId,
      sourceBackupPath: item.backupPath ?? '',
      targetRestorePath: item.path ?? '',
      fileSize: item.sizeBytes ?? 0,
      versionNumber: item.type == SearchResultType.version
          ? (item.rawData as FileVersion).versionNumber
          : 1,
      sha256: sha256,
    );

    ref.read(restoreQueueProvider.notifier).addJob(job);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added restore job for "${item.title}" to queue'),
        action: SnackBarAction(
          label: 'View Queue',
          onPressed: () => context.go('/restore'),
        ),
      ),
    );
  }

  void _showDetailsDialog(SearchResultItem item) {
    showDialog(
      context: context,
      builder: (context) {
        final dFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
        return AlertDialog(
          title: Row(
            children: [
              Icon(_getResultIcon(item.type), color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Item Specifications'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Title/Name', item.title),
                _detailRow('Item Type', item.type.name.toUpperCase()),
                _detailRow('Size', _formatBytes(item.sizeBytes)),
                _detailRow('Date', dFormat.format(item.date)),
                _detailRow('Status', item.status.toUpperCase()),
                if (item.path != null) _detailRow('Original Path', item.path!),
                if (item.backupPath != null) _detailRow('Backup Path', item.backupPath!),
                if (item.workerId != null) _detailRow('Worker ID', item.workerId!),
                if (item.versionCount > 0) _detailRow('Versions Saved', item.versionCount.toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          SelectableText(value, style: const TextStyle(fontSize: 14)),
          const Divider(),
        ],
      ),
    );
  }

  IconData _getResultIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.file:
        return Icons.insert_drive_file_rounded;
      case SearchResultType.version:
        return Icons.history_toggle_off_rounded;
      case SearchResultType.folder:
        return Icons.folder_rounded;
      case SearchResultType.log:
        return Icons.terminal_rounded;
      case SearchResultType.backupJob:
        return Icons.backup_table_rounded;
      case SearchResultType.restoreJob:
        return Icons.settings_backup_restore_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    // Providers watch
    final query = ref.watch(searchQueryProvider);
    final sources = ref.watch(searchSourcesProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final historyAsync = ref.watch(searchHistoryProvider);
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(_textController.text));
    final indexerStatsAsync = ref.watch(searchIndexerStatsProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _textController.clear();
          _searchFocusNode.unfocus();
          _controller.updateQuery('');
        },
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Global Search Engine'),
          actions: [
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            ),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Filters sidebar (for Desktop)
            if (isDesktop)
              Container(
                width: 320,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
                ),
                child: _buildFilterPanel(theme, indexerStatsAsync),
              ),

            // Main Area
            Expanded(
              child: Column(
                children: [
                  // Search Bar & Options
                  _buildSearchHeader(theme, query, sources, suggestionsAsync),

                  // Results Area
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _buildResultsSection(theme, resultsAsync, historyAsync, query),
                        ),
                        // Collapsible Filter Drawer Trigger (Mobile only)
                        if (!isDesktop)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => DraggableScrollableSheet(
                                    initialChildSize: 0.75,
                                    maxChildSize: 0.95,
                                    expand: false,
                                    builder: (context, scrollController) => ListView(
                                      controller: scrollController,
                                      children: [
                                        _buildFilterPanel(theme, indexerStatsAsync),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: const Icon(Icons.filter_list_rounded),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(
    ThemeData theme,
    SearchQuery query,
    Map<String, bool> sources,
    AsyncValue<List<String>> suggestionsAsync,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input Row
            Stack(
              clipBehavior: Clip.none,
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type to locate files, logs, versions (Ctrl+F)...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _textController.clear();
                              _controller.updateQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (val) {
                    _controller.addHistory(val);
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                ),

                // Suggestions Panel Overlay
                if (_showSuggestions && _textController.text.isNotEmpty)
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Card(
                      elevation: 8,
                      child: suggestionsAsync.when(
                        data: (sugs) {
                          if (sugs.isEmpty) return const SizedBox.shrink();
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: sugs.length,
                            itemBuilder: (context, i) {
                              return ListTile(
                                leading: const Icon(Icons.history_rounded, size: 18),
                                title: Text(sugs[i]),
                                onTap: () {
                                  _textController.text = sugs[i];
                                  _controller.updateQuery(sugs[i]);
                                  _controller.addHistory(sugs[i]);
                                  _searchFocusNode.unfocus();
                                },
                              );
                            },
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Sources Selector
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _sourceChip(sources, 'files', 'Files', Icons.insert_drive_file_rounded),
                        const SizedBox(width: 8),
                        _sourceChip(sources, 'versions', 'Versions', Icons.history_toggle_off_rounded),
                        const SizedBox(width: 8),
                        _sourceChip(sources, 'folders', 'Folders', Icons.folder_rounded),
                        const SizedBox(width: 8),
                        _sourceChip(sources, 'logs', 'Logs', Icons.terminal_rounded),
                        const SizedBox(width: 8),
                        _sourceChip(sources, 'history', 'Backup Runs', Icons.backup_table_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Mode Selector Dropdown
                DropdownButton<SearchMode>(
                  value: query.mode,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                  items: SearchMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _controller.updateMode(val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceChip(Map<String, bool> sources, String key, String label, IconData icon) {
    final active = sources[key] ?? false;
    return FilterChip(
      selected: active,
      label: Text(label),
      avatar: Icon(icon, size: 14),
      onSelected: (val) => _controller.updateSource(key, val),
    );
  }

  Widget _buildFilterPanel(ThemeData theme, AsyncValue<Map<String, dynamic>> indexerStatsAsync) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Advanced Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset All'),
              ),
            ],
          ),
          const Divider(),

          // File type / extension field
          TextField(
            decoration: const InputDecoration(
              labelText: 'File Extension (e.g. zip, pdf)',
              prefixIcon: Icon(Icons.extension_rounded),
            ),
            onChanged: (val) {
              _fileType = val;
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),

          // Date Range picker button
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded),
            label: Text(_dateRange == null
                ? 'Select Date Range'
                : '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}'),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (range != null) {
                setState(() => _dateRange = range);
                _applyFilters();
              }
            },
          ),
          const SizedBox(height: 16),

          // Size Limits (Min / Max Sizes)
          Text('File Size constraints', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Min'),
                  initialValue: _minSize,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(value: 1024, child: Text('1 KB')),
                    DropdownMenuItem(value: 1024 * 1024, child: Text('1 MB')),
                    DropdownMenuItem(value: 10 * 1024 * 1024, child: Text('10 MB')),
                    DropdownMenuItem(value: 100 * 1024 * 1024, child: Text('100 MB')),
                  ],
                  onChanged: (val) {
                    setState(() => _minSize = val);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Max'),
                  initialValue: _maxSize,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(value: 1024 * 1024, child: Text('1 MB')),
                    DropdownMenuItem(value: 100 * 1024 * 1024, child: Text('100 MB')),
                    DropdownMenuItem(value: 1024 * 1024 * 1024, child: Text('1 GB')),
                  ],
                  onChanged: (val) {
                    setState(() => _maxSize = val);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status & Levels
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Backup/Run Status'),
            initialValue: _backupStatus,
            items: const [
              DropdownMenuItem(value: null, child: Text('Any Status')),
              DropdownMenuItem(value: 'success', child: Text('Success')),
              DropdownMenuItem(value: 'failed', child: Text('Failed')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
            ],
            onChanged: (val) {
              setState(() => _backupStatus = val);
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Log Severity'),
            initialValue: _logLevel,
            items: const [
              DropdownMenuItem(value: null, child: Text('Any Severity')),
              DropdownMenuItem(value: 'info', child: Text('Information')),
              DropdownMenuItem(value: 'warning', child: Text('Warning')),
              DropdownMenuItem(value: 'error', child: Text('Error')),
            ],
            onChanged: (val) {
              setState(() => _logLevel = val);
              _applyFilters();
            },
          ),
          const SizedBox(height: 24),

          // Reindexing & SQLite stats section
          Text('Database Optimization', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          indexerStatsAsync.when(
            data: (stats) => Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Indexed Files: ${stats['totalFiles']}'),
                    Text('Indexed Versions: ${stats['totalVersions']}'),
                    Text('Logs Indexed: ${stats['totalLogs']}'),
                    Text('Index Volume: ${_formatBytes(stats['totalIndexedSizeBytes'])}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _controller.optimizeIndexes(),
                            child: const Text('Optimize'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _controller.reindexDatabase(),
                            child: const Text('Reindex'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed loading database stats: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(
    ThemeData theme,
    AsyncValue<List<SearchResultItem>> resultsAsync,
    AsyncValue<List<SearchHistory>> historyAsync,
    SearchQuery query,
  ) {
    if (query.queryText.isEmpty && query.filter.isEmpty) {
      // Empty query shows search history
      return _buildHistorySection(theme, historyAsync);
    }

    return resultsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                const Text('No records match your specifications.'),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Located ${items.length} records', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  // Sort panel
                  Row(
                    children: [
                      const Text('Sort by: ', style: TextStyle(fontSize: 12)),
                      DropdownButton<SortField>(
                        value: query.sort.field,
                        underline: const SizedBox(),
                        items: SortField.values.map((f) {
                          return DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _controller.updateSort(query.sort.copyWith(field: val));
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(query.sort.order == SortOrder.ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                        onPressed: () {
                          _controller.updateSort(query.sort.copyWith(
                            order: query.sort.order == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending,
                          ));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisExtent: 160,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _buildGridCard(theme, items[i]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _buildListTile(theme, items[i]),
                    ),
            ),
            
            // Pagination controls
            _buildPaginationRow(query),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed executing search query: $e')),
    );
  }

  Widget _buildPaginationRow(SearchQuery query) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: query.page > 1 ? () => _controller.previousPage() : null,
          ),
          Text('Page ${query.page}'),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _controller.nextPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(ThemeData theme, SearchResultItem item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(_getResultIcon(item.type), color: _getStatusColor(item.status)),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.subtitle != null) Text(item.subtitle!),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(DateFormat('MM/dd/yyyy HH:mm').format(item.date), style: const TextStyle(fontSize: 11)),
                if (item.sizeBytes != null) ...[
                  const SizedBox(width: 12),
                  Text(_formatBytes(item.sizeBytes), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildQuickActions(item),
        ),
      ),
    );
  }

  Widget _buildGridCard(ThemeData theme, SearchResultItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getResultIcon(item.type), color: _getStatusColor(item.status), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                item.subtitle ?? item.path ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.sizeBytes != null ? _formatBytes(item.sizeBytes) : DateFormat('MM/dd/yy').format(item.date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildQuickActions(item, compact: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickActions(SearchResultItem item, {bool compact = false}) {
    final actions = <Widget>[];

    // Open location action (available for items with file paths)
    if (item.path != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.folder_open_rounded),
        iconSize: compact ? 16 : 20,
        tooltip: 'Open Backup Location',
        onPressed: () => _openFileLocation(item.backupPath ?? item.path),
      ));
    }

    // Restore action
    if (item.type == SearchResultType.file || item.type == SearchResultType.version) {
      actions.add(IconButton(
        icon: const Icon(Icons.settings_backup_restore_rounded),
        iconSize: compact ? 16 : 20,
        tooltip: 'Restore File',
        onPressed: () => _restoreItem(item),
      ));
    }

    // Copy Path
    if (item.path != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.copy_all_rounded),
        iconSize: compact ? 16 : 20,
        tooltip: 'Copy Path',
        onPressed: () => _copyToClipboard(item.path),
      ));
    }

    // View specifications/details
    actions.add(IconButton(
      icon: const Icon(Icons.info_outline_rounded),
      iconSize: compact ? 16 : 20,
      tooltip: 'Specs Detail',
      onPressed: () => _showDetailsDialog(item),
    ));

    return actions;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'info':
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildHistorySection(ThemeData theme, AsyncValue<List<SearchHistory>> historyAsync) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Search History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _controller.clearHistory(),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(child: Text('No search history. Recent queries will show up here.'));
                }
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, i) {
                    final item = history[i];
                    return ListTile(
                      leading: IconButton(
                        icon: Icon(item.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                        color: item.pinned ? theme.colorScheme.primary : Colors.grey,
                        onPressed: () => _controller.togglePinHistory(item),
                      ),
                      title: Text(item.query),
                      subtitle: Text(DateFormat('MM/dd/yy HH:mm').format(item.createdAt)),
                      onTap: () {
                        _textController.text = item.query;
                        _controller.updateQuery(item.query);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _controller.deleteHistory(item.id),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed loading history: $e'),
            ),
          ),
        ],
      ),
    );
  }
}
