import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import 'version_models.dart';
import 'version_history_provider.dart';
import 'version_history_controller.dart';
import 'version_comparer.dart';
import 'version_timeline.dart';

class VersionHistoryScreen extends ConsumerStatefulWidget {
  const VersionHistoryScreen({super.key});

  @override
  ConsumerState<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends ConsumerState<VersionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _fileSearchController = TextEditingController();
  final TextEditingController _versionSearchController = TextEditingController();
  
  // For Comparison Selection
  VersionDetail? _compareVersionA;
  VersionDetail? _compareVersionB;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fileSearchController.dispose();
    _versionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    final filesAsync = ref.watch(backupFilesListProvider);
    final selectedFileId = ref.watch(selectedFileIdProvider);
    final controller = VersionHistoryController(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Version History & Timeline'),
        actions: [
          if (selectedFileId != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Deselect File',
              onPressed: () => controller.selectFile(null),
            ),
          ],
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Left pane: Files selection list
                SizedBox(
                  width: 320,
                  child: Card(
                    margin: const EdgeInsets.only(left: 16, bottom: 16, right: 8, top: 8),
                    child: _buildFilesSidebar(filesAsync, selectedFileId, controller),
                  ),
                ),
                // Right pane: Timeline / Version inspection
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.only(right: 16, bottom: 16, left: 8, top: 8),
                    child: _buildDetailsPane(selectedFileId, controller),
                  ),
                ),
              ],
            )
          : selectedFileId == null
              ? _buildFilesSidebar(filesAsync, selectedFileId, controller)
              : _buildDetailsPane(selectedFileId, controller),
    );
  }

  Widget _buildFilesSidebar(
    AsyncValue<List<dynamic>> filesAsync,
    int? selectedId,
    VersionHistoryController controller,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SearchBar(
            controller: _fileSearchController,
            hintText: 'Search backed up files...',
            leading: const Icon(Icons.search_rounded),
            onChanged: (val) {
              setState(() {});
            },
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filesAsync.when(
            data: (files) {
              final query = _fileSearchController.text.toLowerCase();
              final filtered = files.where((f) {
                final file = f as BackupFile;
                return file.fileName.toLowerCase().contains(query) ||
                    file.originalPath.toLowerCase().contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No files match your query.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final file = filtered[index] as BackupFile;
                  final isSelected = file.id == selectedId;

                  return ListTile(
                    selected: isSelected,
                    leading: Icon(
                      _getFileIcon(file.extension),
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      file.originalPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      controller.selectFile(file.id);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsPane(int? selectedFileId, VersionHistoryController controller) {
    final theme = Theme.of(context);
    if (selectedFileId == null) {
      return _buildStatisticsDashboard();
    }

    final searchResultsAsync = ref.watch(versionSearchResultsProvider);
    final timelineAsync = ref.watch(versionTimelineProvider);
    final filters = ref.watch(versionFiltersProvider);

    return Column(
      children: [
        // TabBar to switch between interactive timeline and versions checklist
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.timeline_rounded), text: 'Timeline View'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Versions Checklist'),
          ],
        ),
        // Filter options row
        _buildFiltersRow(controller, filters),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Timeline Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: timelineAsync.when(
                  data: (events) => VersionTimelineWidget(events: events),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error loading timeline: $err')),
                ),
              ),
              // Versions checklist Tab
              searchResultsAsync.when(
                data: (versions) => _buildVersionsChecklist(versions, controller),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading versions: $err')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(VersionHistoryController controller, VersionHistoryFilter filters) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Text Search Prefix input
          SizedBox(
            width: 200,
            height: 40,
            child: TextField(
              controller: _versionSearchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search versions...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _versionSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _versionSearchController.clear();
                          controller.updateSearchPrefix('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (val) {
                controller.updateSearchPrefix(val);
              },
            ),
          ),
          // Filter Type chips
          for (final filterVal in VersionFilterType.values)
            FilterChip(
              label: Text(
                filterVal.name[0].toUpperCase() + filterVal.name.substring(1),
                style: theme.textTheme.labelMedium,
              ),
              selected: filters.type == filterVal,
              onSelected: (selected) {
                if (selected) {
                  controller.updateFilterType(filterVal);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Filters',
            onPressed: () {
              _versionSearchController.clear();
              controller.resetFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVersionsChecklist(List<VersionDetail> list, VersionHistoryController controller) {
    final theme = Theme.of(context);
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
              const SizedBox(height: 12),
              Text('No version snapshots match the filters.', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Bulk action header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Versions: ${list.length}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showExportDialog(list, controller),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export History'),
                  ),
                  if (_compareVersionA != null && _compareVersionB != null)
                    FilledButton.icon(
                      onPressed: _showCompareDialog,
                      icon: const Icon(Icons.compare_rounded, size: 16),
                      label: const Text('Compare Selection'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final detail = list[index];
              final isSelectedForCompare = _compareVersionA == detail || _compareVersionB == detail;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isSelectedForCompare
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: isSelectedForCompare ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: Checkbox(
                    value: isSelectedForCompare,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          if (_compareVersionA == null) {
                            _compareVersionA = detail;
                          } else if (_compareVersionB == null) {
                            _compareVersionB = detail;
                          } else {
                            _compareVersionB = detail; // Replace second selection
                          }
                        } else {
                          if (_compareVersionA == detail) {
                            _compareVersionA = null;
                          } else if (_compareVersionB == detail) {
                            _compareVersionB = null;
                          }
                        }
                      });
                    },
                  ),
                  title: Text(
                    'Version #${detail.version.versionNumber} snapshot',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Backup Completed: ${DateFormat('yyyy-MM-dd HH:mm').format(detail.version.createdAt)}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Original Location', detail.parentFile.originalPath),
                          _buildDetailRow('Backup Store Path', detail.version.backupPath),
                          _buildDetailRow('File Size', _formatBytes(detail.sizeBytes)),
                          _buildDetailRow('SHA-256 Hash', detail.sha256),
                          _buildDetailRow('Modified Date', detail.modifiedAt.toIso8601String()),
                          _buildDetailRow('Verification Status', detail.verificationStatus.toUpperCase()),
                          _buildDetailRow('Worker ID', detail.backupWorker),
                          _buildDetailRow('Backup Duration', '${detail.backupDuration.inMilliseconds} ms'),
                          if (detail.notes != null) _buildDetailRow('Version Notes', detail.notes!),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showRestoreDialog(detail, controller),
                                icon: const Icon(Icons.restore_rounded),
                                label: const Text('Restore This Version'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsDashboard() {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(versionStatisticsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version Statistics & Repository Analytics',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a file from the sidebar to inspect its timeline, compare differences, and restore specific versions. Below is the total repository volume analytics.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          statsAsync.when(
            data: (stats) {
              return Column(
                children: [
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: MediaQuery.of(context).size.width > 1200 ? 1.6 : 2.0,
                    children: [
                      _buildStatCard('Total Version Snapshots', stats.totalVersions.toString(), Icons.history_rounded, Colors.blue),
                      _buildStatCard('Average Versions/File', stats.averageVersionsPerFile.toStringAsFixed(1), Icons.analytics_rounded, Colors.purple),
                      _buildStatCard('Storage Volume Used', _formatBytes(stats.versionStorageUsageBytes), Icons.storage_rounded, Colors.teal),
                      _buildStatCard('Verification Rate', '${stats.verificationSuccessRate}%', Icons.verified_user_rounded, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repository Metadata Details',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Largest Version Chain', '${stats.largestVersionChain} versions (${stats.largestChainFileName})'),
                          _buildDetailRow('Restore Operations Run', stats.restoreFrequency.toString()),
                          const SizedBox(height: 12),
                          Text(
                            'Most Frequently Updated Files:',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (stats.mostFrequentlyUpdatedFiles.isEmpty)
                            const Text('No updates recorded yet.')
                          else
                            for (final entry in stats.mostFrequentlyUpdatedFiles.entries)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    Text(
                                      '${entry.value} versions',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error computing statistics: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withAlpha(13),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withAlpha(76)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompareDialog() {
    if (_compareVersionA == null || _compareVersionB == null) return;
    
    final result = VersionComparer.compare(_compareVersionA!, _compareVersionB!);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Version Comparison Report'),
          content: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(color: theme.colorScheme.outlineVariant),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
                  children: const [
                    TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold)))),
                    TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Version A', style: TextStyle(fontWeight: FontWeight.bold)))),
                    TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Version B', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Version #'))),
                    TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(result.versionA.version.versionNumber.toString()))),
                    TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(result.versionB.version.versionNumber.toString()))),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('File Size'))),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _formatBytes(result.versionA.sizeBytes),
                          style: TextStyle(color: result.sizeChanged ? Colors.red : null, fontWeight: result.sizeChanged ? FontWeight.bold : null),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _formatBytes(result.versionB.sizeBytes),
                          style: TextStyle(color: result.sizeChanged ? Colors.red : null, fontWeight: result.sizeChanged ? FontWeight.bold : null),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('SHA-256 Hash'))),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${result.versionA.sha256.substring(0, 8)}...',
                          style: TextStyle(color: result.shaChanged ? Colors.red : null, fontWeight: result.shaChanged ? FontWeight.bold : null),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${result.versionB.sha256.substring(0, 8)}...',
                          style: TextStyle(color: result.shaChanged ? Colors.red : null, fontWeight: result.shaChanged ? FontWeight.bold : null),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Backup Date'))),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(result.versionA.version.createdAt),
                          style: TextStyle(color: result.dateChanged ? Colors.red : null),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(result.versionB.version.createdAt),
                          style: TextStyle(color: result.dateChanged ? Colors.red : null),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Modified Date'))),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(result.versionA.modifiedAt),
                          style: TextStyle(color: result.modifiedDateChanged ? Colors.red : null),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(result.versionB.modifiedAt),
                          style: TextStyle(color: result.modifiedDateChanged ? Colors.red : null),
                        ),
                      ),
                    ),
                  ],
                ),
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

  void _showRestoreDialog(VersionDetail detail, VersionHistoryController controller) {
    String conflictPolicy = 'rename';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configure Restore Version'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You are about to restore Version #${detail.version.versionNumber} of the file:'),
                  const SizedBox(height: 8),
                  Text(
                    detail.parentFile.fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Restore Target Destination:'),
                  Text(
                    detail.parentFile.originalPath,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'If file already exists:'),
                    initialValue: conflictPolicy,
                    items: const [
                      DropdownMenuItem(value: 'rename', child: Text('Keep both (Rename restored version)')),
                      DropdownMenuItem(value: 'skip', child: Text('Skip (Do not overwrite)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => conflictPolicy = val);
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
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.restoreSelectedVersions(
                      versions: [detail],
                      conflictPolicy: conflictPolicy,
                      context: this.context,
                    );
                  },
                  child: const Text('Confirm Restore'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExportDialog(List<VersionDetail> list, VersionHistoryController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Version History'),
          content: const Text('Select a format to save the version log history report:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.exportHistory(versions: list, format: 'txt', context: this.context);
              },
              child: const Text('TXT'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.exportHistory(versions: list, format: 'csv', context: this.context);
              },
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.exportHistory(versions: list, format: 'json', context: this.context);
              },
              child: const Text('JSON'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.exportHistory(versions: list, format: 'pdf', context: this.context);
              },
              child: const Text('PDF'),
            ),
          ],
        );
      },
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive_rounded;
      case '.pdf':
        return Icons.picture_as_pdf_rounded;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.webp':
        return Icons.image_rounded;
      case '.log':
      case '.txt':
        return Icons.description_rounded;
      case '.db':
      case '.sqlite':
        return Icons.storage_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.toString().length - 1) ~/ 3;
    if (i >= suffixes.length) i = suffixes.length - 1;
    final doubleVal = bytes / (1 << (i * 10));
    return '${doubleVal.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
