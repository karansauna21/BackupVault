import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/database/app_database.dart';
import 'folder_models.dart';
import 'folder_manager_controller.dart';
import '../../core/utils/android_storage.dart';
import '../../shared/providers/platform_providers.dart';
import '../../shared/providers/device_provider.dart';
import '../../core/transport/transport_provider.dart';
import '../../core/transport/transport_models.dart';
import '../../core/models/device_model.dart';

// Helper formatting utilities
String formatFolderBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

class FolderCard extends ConsumerWidget {
  final BackupFolder folder;
  final FolderStats stats;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRescan;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;

  const FolderCard({
    super.key,
    required this.folder,
    required this.stats,
    required this.onEdit,
    required this.onDelete,
    required this.onRescan,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(folderManagerControllerProvider(ref));
    final isMobile = MediaQuery.of(context).size.width < 600;

    Color scoreColor = Colors.green;
    if (stats.health.score < 60) {
      scoreColor = Colors.red;
    } else if (stats.health.score < 90) {
      scoreColor = Colors.orange;
    }

    Widget buildHeader() {
      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectChanged,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Created: ${folder.createdAt.toString().split(' ')[0]}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                    if (val == 'rescan') onRescan();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rescan',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Rescan Folder'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Configuration'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Folder', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: scoreColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.health.score}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Active',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: folder.enabled,
                      onChanged: (val) => controller.toggleFolder(folder.id, val),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      }

      return Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: onSelectChanged,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Created: ${folder.createdAt.toString().split(' ')[0]}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.health_and_safety_rounded, color: scoreColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${stats.health.score}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: folder.enabled,
            onChanged: (val) => controller.toggleFolder(folder.id, val),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
              if (val == 'rescan') onRescan();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rescan',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Rescan Folder'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Configuration'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Folder', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              const Divider(height: 24),

              // Paths
              _buildPathRow(theme, Icons.source_rounded, 'Source', folder.sourcePath),
              const SizedBox(height: 8),
              _buildPathRow(theme, Icons.drive_file_move_rounded, 'Destination', folder.destinationPath),
              
              const SizedBox(height: 16),

              // Stats & Watcher Info
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildStatItem(theme, Icons.folder_open_rounded, '${stats.fileCount} files'),
                  _buildStatItem(theme, Icons.storage_rounded, formatFolderBytes(stats.totalSize)),
                  _buildStatItem(
                    theme,
                    Icons.history_toggle_off_rounded,
                    stats.lastScanTime != null
                        ? '${stats.lastScanTime!.hour}:${stats.lastScanTime!.minute.toString().padLeft(2, '0')}'
                        : 'Never Scanned',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: folder.enabled ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      folder.enabled ? 'WATCHING' : 'PAUSED',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: folder.enabled ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDisplayPath(String path) {
    if (path.startsWith('content://')) {
      try {
        final decoded = Uri.decodeFull(path);
        if (decoded.contains('/tree/')) {
          final treePart = decoded.split('/tree/').last;
          final segments = treePart.split(':');
          final volume = segments.first == 'primary' ? 'Internal Storage' : segments.first;
          final relativePath = segments.length > 1 ? segments[1] : '';
          if (relativePath.isNotEmpty) {
            return '$volume: $relativePath';
          }
          return volume;
        }
      } catch (_) {}
      return path;
    }
    return path;
  }

  Widget _buildPathRow(ThemeData theme, IconData icon, String label, String path) {
    final displayPath = _formatDisplayPath(path);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            displayPath.isEmpty ? 'Not Configured' : displayPath,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: displayPath.isEmpty ? theme.colorScheme.error : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class RuleEditorDialog extends StatefulWidget {
  final FolderRules initialRules;

  const RuleEditorDialog({super.key, required this.initialRules});

  @override
  State<RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<RuleEditorDialog> {
  late List<String> _includes;
  late List<String> _excludes;
  late bool _includeHidden;
  late bool _ignoreTemp;
  late bool _ignoreSystem;
  late bool _ignoreEmpty;
  final _includeController = TextEditingController();
  final _excludeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _includes = List.from(widget.initialRules.includeExtensions);
    _excludes = List.from(widget.initialRules.excludeExtensions);
    _includeHidden = widget.initialRules.includeHidden;
    _ignoreTemp = widget.initialRules.ignoreTemp;
    _ignoreSystem = widget.initialRules.ignoreSystem;
    _ignoreEmpty = widget.initialRules.ignoreEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Configure Folder Exclusion Rules'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switches
            SwitchListTile(
              title: const Text('Backup Hidden Files'),
              value: _includeHidden,
              onChanged: (val) => setState(() => _includeHidden = val),
            ),
            SwitchListTile(
              title: const Text('Ignore Temporary Files'),
              subtitle: const Text('Excludes .tmp, .temp, ~ files'),
              value: _ignoreTemp,
              onChanged: (val) => setState(() => _ignoreTemp = val),
            ),
            SwitchListTile(
              title: const Text('Ignore OS System Files'),
              subtitle: const Text('Excludes desktop.ini, DS_Store, etc.'),
              value: _ignoreSystem,
              onChanged: (val) => setState(() => _ignoreSystem = val),
            ),
            SwitchListTile(
              title: const Text('Ignore Empty Files (0-byte)'),
              value: _ignoreEmpty,
              onChanged: (val) => setState(() => _ignoreEmpty = val),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Extensions include
            Text('Include Only Extensions', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _includeController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. pdf, docx, png',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () {
                    final ext = _includeController.text.trim();
                    if (ext.isNotEmpty && !_includes.contains(ext)) {
                      setState(() => _includes.add(ext));
                      _includeController.clear();
                    }
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              children: _includes.map((ext) => Chip(
                label: Text(ext),
                onDeleted: () => setState(() => _includes.remove(ext)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Extensions exclude
            Text('Exclude Specific Extensions', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _excludeController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. mp4, zip, exe',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () {
                    final ext = _excludeController.text.trim();
                    if (ext.isNotEmpty && !_excludes.contains(ext)) {
                      setState(() => _excludes.add(ext));
                      _excludeController.clear();
                    }
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              children: _excludes.map((ext) => Chip(
                label: Text(ext),
                onDeleted: () => setState(() => _excludes.remove(ext)),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final rules = FolderRules(
              includeExtensions: _includes,
              excludeExtensions: _excludes,
              includeHidden: _includeHidden,
              ignoreTemp: _ignoreTemp,
              ignoreSystem: _ignoreSystem,
              ignoreEmpty: _ignoreEmpty,
            );
            Navigator.of(context).pop(rules);
          },
          child: const Text('Save Rules'),
        ),
      ],
    );
  }
}

class FolderConfigDialog extends ConsumerStatefulWidget {
  final BackupFolder? existingFolder;
  final FolderRules? initialRules;

  const FolderConfigDialog({
    super.key,
    this.existingFolder,
    this.initialRules,
  });

  @override
  ConsumerState<FolderConfigDialog> createState() => _FolderConfigDialogState();
}

class _FolderConfigDialogState extends ConsumerState<FolderConfigDialog> {
  final _nameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _destController = TextEditingController();
  String _interval = 'manual';
  FolderRules _rules = const FolderRules();
  String? _destinationType;
  String? _deviceUuid;
  String? _deviceName;
  String? _remoteFolderId;
  String? _remoteFolderPath;

  @override
  void initState() {
    super.initState();
    if (widget.existingFolder != null) {
      _nameController.text = widget.existingFolder!.name;
      _sourceController.text = widget.existingFolder!.sourcePath;
      _destController.text = widget.existingFolder!.destinationPath;
      _interval = widget.existingFolder!.backupInterval;
      _destinationType = widget.existingFolder!.destinationType;
      _deviceUuid = widget.existingFolder!.deviceUuid;
      _deviceName = widget.existingFolder!.deviceName;
      _remoteFolderId = widget.existingFolder!.remoteFolderId;
      _remoteFolderPath = widget.existingFolder!.remoteFolderPath;
    }
    if (widget.initialRules != null) {
      _rules = widget.initialRules!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingFolder != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Backup Folder Configuration' : 'Configure New Backup Folder'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Identifier Name',
                  hintText: 'e.g. My Documents',
                ),
              ),
              const SizedBox(height: 16),

              // Source path picker
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Source Directory Path',
                        hintText: 'C:\\Users\\User\\Documents',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.folder_open_rounded),
                    tooltip: 'Browse Folder',
                    onPressed: () async {
                      final picker = ref.read(folderPickerProvider);
                      final path = await picker.pickFolder(context);
                      if (path != null) {
                        setState(() {
                          _sourceController.text = path;
                          if (_nameController.text.isEmpty) {
                            if (path.startsWith('content://')) {
                              final decoded = Uri.decodeFull(path);
                              final lastSegment = decoded.split('%3A').last.split('/').last;
                              _nameController.text = lastSegment.isNotEmpty ? lastSegment : 'Android Folder';
                            } else {
                              _nameController.text = p.basename(path);
                            }
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick source locations
              Text('Quick Source Shortcuts:', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: Platform.isAndroid
                    ? [
                        _buildQuickShortcut('Documents'),
                        _buildQuickShortcut('Downloads'),
                        _buildQuickShortcut('DCIM'),
                        _buildQuickShortcut('Pictures'),
                        _buildQuickShortcut('Music'),
                        _buildQuickShortcut('Movies'),
                      ]
                    : [
                        _buildQuickShortcut('Desktop'),
                        _buildQuickShortcut('Documents'),
                        _buildQuickShortcut('Downloads'),
                        _buildQuickShortcut('Pictures'),
                        _buildQuickShortcut('Music'),
                      ],
              ),
              const SizedBox(height: 16),

              // Destination path picker
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _destController,
                      decoration: const InputDecoration(
                        labelText: 'Backup Target Destination',
                        hintText: 'D:\\BackupVaultStore',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_rounded),
                    tooltip: 'Browse Destination',
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => const SelectBackupDestinationDialog(),
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _destController.text = result['destinationPath'] ?? '';
                          _destinationType = result['destinationType'];
                          _deviceUuid = result['deviceUuid'];
                          _deviceName = result['deviceName'];
                          _remoteFolderId = result['remoteFolderId'];
                          _remoteFolderPath = result['remoteFolderPath'];
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _interval,
                decoration: const InputDecoration(labelText: 'Backup Interval'),
                items: const [
                  DropdownMenuItem(value: 'manual', child: Text('Manual (Triggered by watcher)')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily Scheduled')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly Scheduled')),
                ],
                onChanged: (val) => setState(() => _interval = val ?? 'manual'),
              ),
              const SizedBox(height: 24),

              // Rules manager link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('Folder Exclusion Rules:', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      final updatedRules = await showDialog<FolderRules>(
                        context: context,
                        builder: (context) => RuleEditorDialog(initialRules: _rules),
                      );
                      if (updatedRules != null) {
                        setState(() => _rules = updatedRules);
                      }
                    },
                    child: const Text('Configure Rules'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty || _sourceController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please specify folder name and source path')),
              );
              return;
            }
            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'sourcePath': _sourceController.text.trim(),
              'destinationPath': _destController.text.trim(),
              'interval': _interval,
              'rules': _rules,
              'destinationType': _destinationType,
              'deviceUuid': _deviceUuid,
              'deviceName': _deviceName,
              'remoteFolderId': _remoteFolderId,
              'remoteFolderPath': _remoteFolderPath,
            });
          },
          child: Text(isEdit ? 'Save Changes' : 'Configure Folder'),
        ),
      ],
    );
  }

  Future<void> _handleAndroidShortcut(String type) async {
    String uri = 'content://com.android.externalstorage.documents/tree/primary%3A';
    if (type == 'Documents') uri += 'Documents';
    if (type == 'Downloads') uri += 'Download';
    if (type == 'DCIM') uri += 'DCIM';
    if (type == 'Pictures') uri += 'Pictures';
    if (type == 'Music') uri += 'Music';
    if (type == 'Movies') uri += 'Movies';

    final hasPerm = await AndroidStorage.isUriPermissionPersisted(uri);
    if (hasPerm) {
      setState(() {
        _sourceController.text = uri;
        if (_nameController.text.isEmpty) {
          _nameController.text = type;
        }
      });
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Authorize access by tapping "Use this folder" in the next screen.'),
        duration: const Duration(seconds: 4),
      ),
    );

    final result = await AndroidStorage.pickDirectory(initialUri: uri);
    if (result != null && result['uri'] != null && result['uri']!.isNotEmpty) {
      setState(() {
        _sourceController.text = result['uri']!;
        if (_nameController.text.isEmpty) {
          _nameController.text = type;
        }
      });
    }
  }

  Widget _buildQuickShortcut(String type) {
    return ActionChip(
      label: Text(type),
      onPressed: () async {
        try {
          if (Platform.isAndroid) {
            await _handleAndroidShortcut(type);
            return;
          }
          
          Directory? dir;
          if (type == 'Desktop') dir = await getAppDirectory('desktop');
          if (type == 'Documents') dir = await getApplicationDocumentsDirectory();
          if (type == 'Downloads') dir = await getAppDirectory('downloads');
          if (type == 'Pictures') dir = await getAppDirectory('pictures');
          if (type == 'Music') dir = await getAppDirectory('music');
          
          if (dir != null) {
            setState(() {
              _sourceController.text = dir!.path;
              if (_nameController.text.isEmpty) {
                _nameController.text = type;
              }
            });
          }
        } catch (_) {}
      },
    );
  }

  Future<Directory?> getAppDirectory(String type) async {
    try {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (home == null) return null;
      if (type == 'desktop') return Directory(p.join(home, 'Desktop'));
      if (type == 'downloads') return Directory(p.join(home, 'Downloads'));
      if (type == 'pictures') return Directory(p.join(home, 'Pictures'));
      if (type == 'music') return Directory(p.join(home, 'Music'));
    } catch (_) {}
    return null;
  }
}

class CustomFolderPickerDialog extends StatefulWidget {
  const CustomFolderPickerDialog({super.key});

  @override
  State<CustomFolderPickerDialog> createState() => _CustomFolderPickerDialogState();
}

class _CustomFolderPickerDialogState extends State<CustomFolderPickerDialog> {
  late Directory _currentDirectory;
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    try {
      // Start at user home/docs or root dir
      if (Platform.isWindows) {
        final home = Platform.environment['USERPROFILE'] ?? 'C:\\';
        _currentDirectory = Directory(home);
      } else {
        final home = Platform.environment['HOME'] ?? '/';
        _currentDirectory = Directory(home);
      }
      await _loadDirectoryContents();
    } catch (_) {
      setState(() {
        _isLoading = false;
        _entities = [];
      });
    }
  }

  Future<void> _loadDirectoryContents() async {
    setState(() => _isLoading = true);
    try {
      final list = await _currentDirectory.list().toList();
      // Filter directories only
      final dirs = list.whereType<Directory>().toList()
        ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
      
      setState(() {
        _entities = dirs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _entities = [];
        _isLoading = false;
      });
    }
  }

  void _navigateUp() {
    final parent = _currentDirectory.parent;
    if (parent.path != _currentDirectory.path) {
      setState(() {
        _currentDirectory = parent;
      });
      _loadDirectoryContents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_open_rounded, color: Colors.amber),
          const SizedBox(width: 8),
          const Text('Select Folder'),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded),
                  onPressed: _navigateUp,
                  tooltip: 'Up One Level',
                ),
                Expanded(
                  child: Text(
                    _currentDirectory.path,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _entities.isEmpty
                      ? const Center(child: Text('No directories or permission denied'))
                      : ListView.builder(
                          itemCount: _entities.length,
                          itemBuilder: (context, index) {
                            final dir = _entities[index] as Directory;
                            final name = p.basename(dir.path);
                            return ListTile(
                              leading: const Icon(Icons.folder, color: Colors.amber),
                              title: Text(name),
                              onTap: () {
                                setState(() {
                                  _currentDirectory = dir;
                                });
                                _loadDirectoryContents();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_currentDirectory.path);
          },
          child: const Text('Select Current'),
        ),
      ],
    );
  }
}

class SelectBackupDestinationDialog extends ConsumerStatefulWidget {
  const SelectBackupDestinationDialog({super.key});

  @override
  ConsumerState<SelectBackupDestinationDialog> createState() => _SelectBackupDestinationDialogState();
}

class _SelectBackupDestinationDialogState extends ConsumerState<SelectBackupDestinationDialog> {
  String _stage = 'options';
  DeviceModel? _selectedDevice;
  
  String _currentPath = '';
  List<Map<String, String>> _directories = [];
  bool _isLoadingBrowser = false;
  String? _browserError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_stage == 'options') {
      return _buildOptionsStage(context, theme);
    } else if (_stage == 'devices') {
      return _buildDevicesStage(context, theme);
    } else if (_stage == 'remote_browser') {
      return _buildBrowserStage(context, theme);
    }

    return const SizedBox();
  }

  Widget _buildOptionsStage(BuildContext context, ThemeData theme) {
    return AlertDialog(
      title: const Text('Select Backup Destination'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Platform.isAndroid ? Icons.phone_android_rounded : Icons.computer_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              title: const Text(
                'This Device (Local Storage)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Back up to folder directories on this device.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              onTap: () async {
                final picker = ref.read(folderPickerProvider);
                if (!context.mounted) return;
                final path = await picker.pickFolder(context);
                if (path != null && context.mounted) {
                  Navigator.of(context).pop({
                    'destinationType': 'local',
                    'destinationPath': path,
                    'deviceUuid': null,
                    'deviceName': null,
                    'remoteFolderId': null,
                    'remoteFolderPath': null,
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.devices_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              title: const Text(
                'Connected Devices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Back up to an online paired remote computer or phone.'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              onTap: () {
                setState(() {
                  _stage = 'devices';
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildDevicesStage(BuildContext context, ThemeData theme) {
    final pairedAsync = ref.watch(pairedDevicesStreamProvider);

    return AlertDialog(
      title: const Text('Select Paired Device'),
      content: SizedBox(
        width: 450,
        height: 300,
        child: pairedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading devices: $e')),
          data: (devices) {
            if (devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices_other_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No paired devices found.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Go to Pairing screen to pair devices.'),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final device = devices[index];
                final isOnline = device.connectionStatus == 'Online';

                return ListTile(
                  leading: Icon(
                    device.platform.toLowerCase() == 'windows'
                        ? Icons.laptop_windows_rounded
                        : Icons.phone_android_rounded,
                    color: isOnline ? theme.colorScheme.primary : Colors.grey,
                  ),
                  title: Text(
                    device.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOnline ? null : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  subtitle: Text(
                    'IP: ${device.ipAddress} | Platform: ${device.platform}',
                    style: TextStyle(
                      color: isOnline ? null : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  enabled: isOnline,
                  onTap: () {
                    setState(() {
                      _selectedDevice = device;
                      _stage = 'remote_browser';
                      _currentPath = '';
                    });
                    _loadRemoteDirectories('');
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _stage = 'options';
            });
          },
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _loadRemoteDirectories(String path) async {
    if (_selectedDevice == null) return;

    setState(() {
      _isLoadingBrowser = true;
      _browserError = null;
    });

    try {
      final transportManager = ref.read(transportManagerProvider);
      final response = await transportManager.sendRequestAndWait(
        _selectedDevice!.id,
        PacketType.remoteFoldersRequest,
        {'path': path},
        PacketType.remoteFoldersResponse,
      );

      if (response['success'] == true) {
        final List<dynamic> list = response['folders'] ?? response['roots'] ?? [];
        setState(() {
          _directories = list.map((item) => Map<String, String>.from(item.cast<String, dynamic>())).toList();
          _currentPath = path;
          _isLoadingBrowser = false;
        });
      } else {
        setState(() {
          _browserError = response['error'] ?? 'Unknown remote error';
          _isLoadingBrowser = false;
        });
      }
    } catch (e) {
      setState(() {
        _browserError = e.toString();
        _isLoadingBrowser = false;
      });
    }
  }

  Future<void> _createRemoteFolder(String name) async {
    if (_selectedDevice == null || name.trim().isEmpty) return;

    setState(() {
      _isLoadingBrowser = true;
      _browserError = null;
    });

    try {
      final transportManager = ref.read(transportManagerProvider);
      final response = await transportManager.sendRequestAndWait(
        _selectedDevice!.id,
        PacketType.createFolderRequest,
        {'parentPath': _currentPath, 'folderName': name},
        PacketType.createFolderResponse,
      );

      if (response['success'] == true) {
        await _loadRemoteDirectories(_currentPath);
      } else {
        setState(() {
          _browserError = response['error'] ?? 'Failed to create folder';
          _isLoadingBrowser = false;
        });
      }
    } catch (e) {
      setState(() {
        _browserError = e.toString();
        _isLoadingBrowser = false;
      });
    }
  }

  Future<void> _renameRemoteFolder(String path, String newName) async {
    if (_selectedDevice == null || newName.trim().isEmpty) return;

    setState(() {
      _isLoadingBrowser = true;
      _browserError = null;
    });

    try {
      final transportManager = ref.read(transportManagerProvider);
      final response = await transportManager.sendRequestAndWait(
        _selectedDevice!.id,
        PacketType.renameFolderRequest,
        {'folderPath': path, 'newName': newName},
        PacketType.renameFolderResponse,
      );

      if (response['success'] == true) {
        await _loadRemoteDirectories(_currentPath);
      } else {
        setState(() {
          _browserError = response['error'] ?? 'Failed to rename folder';
          _isLoadingBrowser = false;
        });
      }
    } catch (e) {
      setState(() {
        _browserError = e.toString();
        _isLoadingBrowser = false;
      });
    }
  }

  Widget _buildBrowserStage(BuildContext context, ThemeData theme) {
    final isRoot = _currentPath.isEmpty;

    return AlertDialog(
      title: Text('Choose Location on ${_selectedDevice?.name}'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRoot ? 'Device Root Directory' : _currentPath,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoadingBrowser
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Reading remote directory...'),
                        ],
                      ),
                    )
                  : _browserError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Error: $_browserError',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _loadRemoteDirectories(_currentPath),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            if (!isRoot)
                              ListTile(
                                leading: const Icon(Icons.arrow_upward_rounded),
                                title: const Text('.. (Parent Directory)'),
                                onTap: () {
                                  if (Platform.isWindows || (_selectedDevice?.platform.toLowerCase() == 'windows')) {
                                    final parts = _currentPath.split('\\');
                                    if (parts.length > 2) {
                                      parts.removeLast();
                                      final parent = parts.join('\\');
                                      _loadRemoteDirectories(parent.endsWith(':') ? '$parent\\' : parent);
                                    } else {
                                      _loadRemoteDirectories('');
                                    }
                                  } else {
                                    final parts = _currentPath.split('/');
                                    if (parts.length > 2) {
                                      parts.removeLast();
                                      _loadRemoteDirectories(parts.join('/'));
                                    } else {
                                      _loadRemoteDirectories('');
                                    }
                                  }
                                },
                              ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _directories.length,
                                itemBuilder: (context, index) {
                                  final item = _directories[index];
                                  final name = item['name'] ?? '';
                                  final path = item['path'] ?? '';

                                  return ListTile(
                                    leading: const Icon(Icons.folder_rounded, color: Colors.amber),
                                    title: Text(name),
                                    onTap: () {
                                      _loadRemoteDirectories(path);
                                    },
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded),
                                      onSelected: (action) {
                                        if (action == 'rename') {
                                          _showTextPromptDialog(
                                            context,
                                            title: 'Rename Folder',
                                            initialValue: name,
                                            hintText: 'New folder name',
                                            onConfirm: (val) => _renameRemoteFolder(path, val),
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'rename',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, size: 18),
                                              SizedBox(width: 8),
                                              Text('Rename'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: () => _loadRemoteDirectories(_currentPath),
        ),
        IconButton(
          icon: const Icon(Icons.create_new_folder_rounded),
          tooltip: 'Create New Folder',
          onPressed: isRoot
              ? null
              : () {
                  _showTextPromptDialog(
                    context,
                    title: 'Create New Folder',
                    hintText: 'Folder name',
                    onConfirm: (val) => _createRemoteFolder(val),
                  );
                },
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            setState(() {
              _stage = 'devices';
            });
          },
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: isRoot
              ? null
              : () {
                  Navigator.of(context).pop({
                    'destinationType': 'remote',
                    'destinationPath': '${_selectedDevice!.name}: $_currentPath',
                    'deviceUuid': _selectedDevice!.id,
                    'deviceName': _selectedDevice!.name,
                    'remoteFolderId': _currentPath,
                    'remoteFolderPath': _currentPath,
                  });
                },
          child: const Text('Choose Folder'),
        ),
      ],
    );
  }

  Future<void> _showTextPromptDialog(
    BuildContext context, {
    required String title,
    String initialValue = '',
    required String hintText,
    required ValueChanged<String> onConfirm,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hintText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onConfirm(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
