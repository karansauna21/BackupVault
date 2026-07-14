import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import 'folder_models.dart';
import 'folder_manager_provider.dart';
import 'folder_manager_widgets.dart';
import 'folder_manager_controller.dart';

class FolderManagerScreen extends ConsumerStatefulWidget {
  const FolderManagerScreen({super.key});

  @override
  ConsumerState<FolderManagerScreen> createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends ConsumerState<FolderManagerScreen> {
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.watch(folderManagerControllerProvider(ref));

    final filteredAsync = ref.watch(filteredFoldersProvider);
    final summary = ref.watch(folderStatisticsProvider);
    final selectedIds = ref.watch(selectedFolderIdsProvider);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1000;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isCtrl = HardwareKeyboard.instance.isControlPressed;
          if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
            _showAddFolderDialog(context, controller);
            return KeyEventResult.handled;
          }
          if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyR) {
            controller.scanAllFolders();
            return KeyEventResult.handled;
          }
          if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyA) {
            filteredAsync.whenData((folders) {
              ref.read(selectedFolderIdsProvider.notifier).setSelected(
                  folders.map((f) => f.id).toSet());
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            ref.read(selectedFolderIdsProvider.notifier).clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Backup Folders'),
          leading: isMobile
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () {
                    context.findAncestorStateOfType<ScaffoldState>()?.openDrawer();
                  },
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Scan & Validate All Folders',
              onPressed: () => controller.scanAllFolders(),
            ),
            IconButton(
              icon: const Icon(Icons.file_download_rounded),
              tooltip: 'Import Configurations',
              onPressed: () => _handleImport(context, controller),
            ),
            if (selectedIds.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.file_upload_rounded),
                tooltip: 'Export Selected Configs',
                onPressed: () => _handleExport(context, controller, selectedIds.toList()),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                tooltip: 'Delete Selected',
                onPressed: () => _showBulkDeleteConfirmation(context, controller, selectedIds.toList()),
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: filteredAsync.when(
          data: (folders) => folders.isEmpty
              ? null
              : FloatingActionButton.extended(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Backup Folder'),
                  onPressed: () => _showAddFolderDialog(context, controller),
                ),
          loading: () => null,
          error: (_, _) => null,
        ),
        body: Column(
          children: [
            // Filter & summary bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 8 : 16,
              ),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Stats info
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(theme, 'Watched Folders', '${summary.totalFolders}'),
                                _buildSummaryItem(theme, 'Total Size', formatFolderBytes(summary.totalSize)),
                                _buildSummaryItem(theme, 'Total Files', '${summary.totalFiles}'),
                              ],
                            ),
                            const Divider(height: 20),
                            // Search field
                            TextField(
                              onChanged: (val) {
                                ref.read(folderSearchQueryProvider.notifier).setQuery(val);
                              },
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Search folders...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Filter dropdown
                            DropdownButtonFormField<String>(
                              initialValue: ref.watch(folderSearchFilterProvider),
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Folders')),
                                DropdownMenuItem(value: 'enabled', child: Text('Active Only')),
                                DropdownMenuItem(value: 'disabled', child: Text('Paused Only')),
                                DropdownMenuItem(value: 'failed', child: Text('Health Warnings')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(folderSearchFilterProvider.notifier).setFilter(val);
                                }
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            // Stats info
                            Expanded(
                              child: Wrap(
                                spacing: 24,
                                runSpacing: 8,
                                children: [
                                  _buildSummaryItem(theme, 'Watched Folders', '${summary.totalFolders}'),
                                  _buildSummaryItem(theme, 'Total Size', formatFolderBytes(summary.totalSize)),
                                  _buildSummaryItem(theme, 'Total Files', '${summary.totalFiles}'),
                                ],
                              ),
                            ),
                            // Search field
                            SizedBox(
                              width: 250,
                              child: TextField(
                                onChanged: (val) {
                                  ref.read(folderSearchQueryProvider.notifier).setQuery(val);
                                },
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Search folders...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Filter dropdown
                            DropdownButton<String>(
                              value: ref.watch(folderSearchFilterProvider),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Folders')),
                                DropdownMenuItem(value: 'enabled', child: Text('Active Only')),
                                DropdownMenuItem(value: 'disabled', child: Text('Paused Only')),
                                DropdownMenuItem(value: 'failed', child: Text('Health Warnings')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(folderSearchFilterProvider.notifier).setFilter(val);
                                }
                              },
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // Folders list
            Expanded(
              child: filteredAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading configurations: $err', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                data: (folders) {
                  if (folders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off_rounded, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No backup folders configured',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add folders to start real-time automated backups',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Configure First Folder'),
                            onPressed: () => _showAddFolderDialog(context, controller),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isMobile) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        final stats = ref.watch(folderStatsProvider(folder.id)).value ?? FolderStats(folderId: folder.id);
                        final isSelected = selectedIds.contains(folder.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FolderCard(
                            folder: folder,
                            stats: stats,
                            isSelected: isSelected,
                            onSelectChanged: (val) {
                              final current = Set<int>.from(selectedIds);
                              if (val == true) {
                                current.add(folder.id);
                              } else {
                                current.remove(folder.id);
                              }
                              ref.read(selectedFolderIdsProvider.notifier).setSelected(current);
                            },
                            onEdit: () => _showEditFolderDialog(context, controller, folder, stats.rules),
                            onDelete: () => _showDeleteConfirmation(context, controller, folder),
                            onRescan: () => controller.scanFolder(folder.id),
                          ),
                        );
                      },
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 220,
                    ),
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final stats = ref.watch(folderStatsProvider(folder.id)).value ?? FolderStats(folderId: folder.id);
                      final isSelected = selectedIds.contains(folder.id);

                      return FolderCard(
                        folder: folder,
                        stats: stats,
                        isSelected: isSelected,
                        onSelectChanged: (val) {
                          final current = Set<int>.from(selectedIds);
                          if (val == true) {
                            current.add(folder.id);
                          } else {
                            current.remove(folder.id);
                          }
                          ref.read(selectedFolderIdsProvider.notifier).setSelected(current);
                        },
                        onEdit: () => _showEditFolderDialog(context, controller, folder, stats.rules),
                        onDelete: () => _showDeleteConfirmation(context, controller, folder),
                        onRescan: () => controller.scanFolder(folder.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _showAddFolderDialog(BuildContext context, FolderManagerController controller) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const FolderConfigDialog(),
    );

    if (result != null) {
      await controller.addFolder(
        name: result['name'],
        sourcePath: result['sourcePath'],
        destinationPath: result['destinationPath'],
        interval: result['interval'],
        rules: result['rules'] ?? const FolderRules(),
      );
    }
  }

  Future<void> _showEditFolderDialog(
    BuildContext context,
    FolderManagerController controller,
    BackupFolder folder,
    FolderRules rules,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FolderConfigDialog(
        existingFolder: folder,
        initialRules: rules,
      ),
    );

    if (result != null) {
      await controller.editFolder(
        folder,
        name: result['name'],
        sourcePath: result['sourcePath'],
        destinationPath: result['destinationPath'],
        interval: result['interval'],
        rules: result['rules'],
      );
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    FolderManagerController controller,
    BackupFolder folder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the configuration for "${folder.name}"?\nThis will stop folder watching. Existing backups will NOT be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteFolder(folder.id, folder.name);
    }
  }

  Future<void> _showBulkDeleteConfirmation(
    BuildContext context,
    FolderManagerController controller,
    List<int> ids,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Deletion'),
        content: Text('Are you sure you want to delete ${ids.length} selected configurations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.bulkDelete(ids);
    }
  }

  Future<void> _handleExport(
    BuildContext context,
    FolderManagerController controller,
    List<int> ids,
  ) async {
    final configString = await controller.exportConfigs(ids);
    
    // Copy export data to clipboard
    await Clipboard.setData(ClipboardData(text: configString));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported folder configurations copied to clipboard!')),
      );
    }
  }

  Future<void> _handleImport(BuildContext context, FolderManagerController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty. Copy configuration JSON first.')),
        );
      }
      return;
    }

    try {
      final jsonContent = data!.text!;
      // Try simple validation
      json.decode(jsonContent);

      await controller.importConfigs(jsonContent);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder configurations imported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import configurations: Invalid JSON format ($e)')),
        );
      }
    }
  }
}
