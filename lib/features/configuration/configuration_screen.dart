import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'configuration_provider.dart';
import 'configuration_controller.dart';
import 'configuration_models.dart';

class ConfigurationScreen extends ConsumerStatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  ConsumerState<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Export form state
  final TextEditingController _exportPathController = TextEditingController();
  bool _exportSettings = true;
  bool _exportFolders = true;
  bool _exportSchedules = true;
  bool _exportLogs = false;

  // Import form state
  final TextEditingController _importPathController = TextEditingController();
  ValidationResult? _validationResult;
  bool _importSettings = true;
  bool _importFolders = true;
  bool _importSchedules = true;
  bool _importLogs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set default export path
    _setDefaultExportPath();
  }

  void _setDefaultExportPath() {
    final isWin = Platform.isWindows;
    if (isWin) {
      _exportPathController.text = 'C:\\Backups\\backup_vault_config.zip';
    } else {
      _exportPathController.text = '/tmp/backup_vault_config.zip';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _exportPathController.dispose();
    _importPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(configurationHistoryProvider);
    final exportState = ref.watch(exportStateProvider);
    final importState = ref.watch(importStateProvider);
    final validationState = ref.watch(validationStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: const Text('Configuration Backup & Migration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file_rounded), text: 'Export Wizard'),
            Tab(icon: Icon(Icons.download_for_offline_rounded), text: 'Import Wizard'),
            Tab(icon: Icon(Icons.history_rounded), text: 'History & Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportWizard(theme, exportState),
          _buildImportWizard(theme, importState, validationState),
          _buildHistoryScreen(theme, history),
        ],
      ),
    );
  }

  Widget _buildExportWizard(ThemeData theme, ConfigActionState exportState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.unarchive_rounded, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text('Export Configuration Package', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create a versioned and compressed ZIP archive containing Settings, Folders, Backup/Automation Rules, and Schedules. Restored files are NOT included.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 32),
                  
                  // Destination Path Field
                  Text('Destination File Path', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _exportPathController,
                    decoration: InputDecoration(
                      hintText: Platform.isWindows ? 'C:\\path\\to\\config.zip' : '/path/to/config.zip',
                      prefixIcon: const Icon(Icons.folder_open_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Export Checkboxes
                  Text('Select Items to Include', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Application Settings'),
                    subtitle: const Text('Preferences, notification channels, storage parameters'),
                    value: _exportSettings,
                    onChanged: (val) => setState(() => _exportSettings = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Folders & Backup Rules'),
                    subtitle: const Text('All active folder definitions and ignore rules'),
                    value: _exportFolders,
                    onChanged: (val) => setState(() => _exportFolders = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Schedules & Automation Rules'),
                    subtitle: const Text('Cron/interval backup schedules and trigger criteria'),
                    value: _exportSchedules,
                    onChanged: (val) => setState(() => _exportSchedules = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Include System Logs'),
                    subtitle: const Text('Historical execution and debug logs (optional)'),
                    value: _exportLogs,
                    onChanged: (val) => setState(() => _exportLogs = val ?? false),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: exportState.status == ConfigActionStatus.loading
                          ? null
                          : () => _handleExport(),
                      icon: exportState.status == ConfigActionStatus.loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      label: const Text('Generate Configuration Package'),
                    ),
                  ),
                  
                  if (exportState.status == ConfigActionStatus.success) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exportState.message ?? 'Config exported successfully!',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (exportState.status == ConfigActionStatus.error) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exportState.message ?? 'An error occurred',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportWizard(ThemeData theme, ConfigActionState importState, ConfigActionState validationState) {
    final validation = _validationResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.archive_rounded, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text('Import Configuration Wizard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Restore schedules, paths, settings, or folders from an existing backup ZIP file. Older files will automatically trigger structural migration.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 32),

                  // Import File Selection
                  Text('Configuration Package Path', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _importPathController,
                          decoration: InputDecoration(
                            hintText: Platform.isWindows ? 'C:\\path\\to\\config.zip' : '/path/to/config.zip',
                            prefixIcon: const Icon(Icons.inventory_2_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: validationState.status == ConfigActionStatus.loading
                              ? null
                              : () => _handleValidate(),
                          icon: validationState.status == ConfigActionStatus.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.verified_user_rounded),
                          label: const Text('Validate & Preview Package'),
                        ),
                      ),
                    ],
                  ),

                  // Validation Preview Section
                  if (validation != null) ...[
                    const Divider(height: 40),
                    Text('Validation Preview', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                validation.isValid ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                                color: validation.isValid ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                validation.isValid ? 'Package is compatible and safe to restore' : 'Package validation failed',
                                style: TextStyle(
                                  color: validation.isValid ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Export App Version: ${validation.appVersion}'),
                          Text('Database Format Version: ${validation.databaseVersion}'),
                          
                          if (validation.warnings.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Warnings (${validation.warnings.length}):', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ...validation.warnings.map((w) => Text('• $w', style: const TextStyle(color: Colors.orange, fontSize: 13))),
                          ],

                          if (validation.errors.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Errors (${validation.errors.length}):', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            ...validation.errors.map((e) => Text('• $e', style: const TextStyle(color: Colors.red, fontSize: 13))),
                          ],
                        ],
                      ),
                    ),

                    if (validation.isValid) ...[
                      const SizedBox(height: 24),
                      Text('Restore Selections', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        title: const Text('Restore Settings'),
                        subtitle: const Text('Overwrite general and backup preferences'),
                        value: _importSettings,
                        onChanged: (val) => setState(() => _importSettings = val ?? true),
                      ),
                      CheckboxListTile(
                        title: const Text('Restore Folders & Rules'),
                        subtitle: const Text('Re-register folder paths and criteria'),
                        value: _importFolders,
                        onChanged: (val) => setState(() => _importFolders = val ?? true),
                      ),
                      CheckboxListTile(
                        title: const Text('Restore Schedules'),
                        subtitle: const Text('Replace all interval & triggers configuration'),
                        value: _importSchedules,
                        onChanged: (val) => setState(() => _importSchedules = val ?? true),
                      ),
                      CheckboxListTile(
                        title: const Text('Restore Historical Logs'),
                        subtitle: const Text('Re-import system logs'),
                        value: _importLogs,
                        onChanged: (val) => setState(() => _importLogs = val ?? false),
                      ),

                      const SizedBox(height: 24),
                      
                      // Rollback/Import Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                          ),
                          onPressed: importState.status == ConfigActionStatus.loading
                              ? null
                              : () => _handleImport(),
                          icon: importState.status == ConfigActionStatus.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.install_mobile_rounded),
                          label: const Text('Restore Selected Configurations'),
                        ),
                      ),
                    ],
                  ],

                  if (importState.status == ConfigActionStatus.success) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              importState.message ?? 'Import succeeded!',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (importState.status == ConfigActionStatus.error) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              importState.message ?? 'Restore error.',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryScreen(ThemeData theme, List<HistoryRecord> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text('No configuration export/import history found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Action Logs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Clear Log'),
                onPressed: () => _handleClearHistory(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final h = history[index];
                final isSuccess = h.status == 'success';
                
                IconData icon;
                Color statusColor;
                switch (h.actionType) {
                  case 'export':
                    icon = Icons.unarchive_rounded;
                    statusColor = Colors.blue;
                    break;
                  case 'import':
                    icon = Icons.archive_rounded;
                    statusColor = Colors.green;
                    break;
                  case 'migration':
                    icon = Icons.upgrade_rounded;
                    statusColor = Colors.purple;
                    break;
                  default:
                    icon = Icons.verified_user_rounded;
                    statusColor = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      child: Icon(icon, color: statusColor),
                    ),
                    title: Text(h.details, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Timestamp: ${h.timestamp.toLocal()}'),
                        if (h.filePath != null) Text('Path: ${h.filePath}'),
                        if (h.errorMessage != null) Text('Error: ${h.errorMessage}', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSuccess ? 'Success' : 'Failed',
                        style: TextStyle(
                          color: isSuccess ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    final controller = ref.read(configurationControllerProvider);
    final path = _exportPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify export destination path')),
      );
      return;
    }

    await controller.exportConfig(
      destinationPath: path,
      includeLogs: _exportLogs,
      appVersion: '1.0.0',
      platformName: Platform.operatingSystem,
    );
  }

  Future<void> _handleValidate() async {
    final controller = ref.read(configurationControllerProvider);
    final path = _importPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select import package path')),
      );
      return;
    }

    try {
      final result = await controller.validateBackupFile(path);
      setState(() {
        _validationResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load backup package: $e')),
      );
    }
  }

  Future<void> _handleImport() async {
    final controller = ref.read(configurationControllerProvider);
    final path = _importPathController.text.trim();
    
    await controller.importConfig(
      zipPath: path,
      restoreSettings: _importSettings,
      restoreFolders: _importFolders,
      restoreSchedules: _importSchedules,
      restoreLogs: _importLogs,
      appVersion: '1.0.0',
      platformName: Platform.operatingSystem,
    );
  }

  Future<void> _handleClearHistory() async {
    final controller = ref.read(configurationControllerProvider);
    await controller.clearHistory();
  }
}
