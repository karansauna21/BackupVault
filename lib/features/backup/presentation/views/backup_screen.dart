import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/providers/device_provider.dart';
import '../../../../core/models/device_model.dart';
import '../../../../core/backup_job/backup_queue.dart';
import '../../../folder_manager/folder_manager_provider.dart';
import '../../../folder_manager/folder_manager_widgets.dart';
import '../../../folder_manager/folder_manager_controller.dart';
import '../../../folder_manager/folder_models.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderManagerProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups'),
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  context.findAncestorStateOfType<ScaffoldState>()?.openDrawer();
                },
              )
            : null,
      ),
      body: Column(
        children: [
          const BackupQueuePanel(),

          // Main list of configured folders
          Expanded(
            child: foldersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading folders: $err'),
              ),
              data: (folders) {
                if (folders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No folders configured for backup.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final queueState = ref.watch(backupQueueProvider);
                    final isFolderInQueue = queueState.jobs.any((j) => j.folderId == folder.id && (j.status == 'Waiting' || j.status == 'Preparing' || j.status == 'Queued' || j.status == 'Ready'));
                    final isFolderBackingUp = queueState.jobs.any((j) => j.folderId == folder.id && (j.status == 'Preparing' || j.status == 'Ready'));
                    final isDestinationMissing = folder.destinationPath.trim().isEmpty;

                    return Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 12 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: folder.enabled
                                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                            child: Icon(
                                              Icons.folder_rounded,
                                              color: folder.enabled
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  folder.name,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Interval: ${folder.backupInterval.toUpperCase()}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: isDestinationMissing
                                            ? ElevatedButton.icon(
                                                onPressed: () => _openSetDestination(context, ref, folder),
                                                icon: const Icon(Icons.settings_rounded),
                                                label: const Text('Set Destination'),
                                              )
                                            : ElevatedButton.icon(
                                                onPressed: (folder.enabled && !_isBackupDisabled(folder, ref) && !isFolderInQueue)
                                                    ? () => ref.read(backupQueueProvider.notifier).createAndAddJob(folder.id)
                                                    : null,
                                                icon: isFolderBackingUp
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                                        ),
                                                      )
                                                    : const Icon(Icons.play_arrow_rounded),
                                                label: Text(isFolderBackingUp ? 'Backing Up' : (isFolderInQueue ? 'Queued' : 'Backup Now')),
                                              ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: folder.enabled
                                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                        child: Icon(
                                          Icons.folder_rounded,
                                          color: folder.enabled
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              folder.name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Interval: ${folder.backupInterval.toUpperCase()}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Backup Action Button
                                      isDestinationMissing
                                          ? ElevatedButton.icon(
                                              onPressed: () => _openSetDestination(context, ref, folder),
                                              icon: const Icon(Icons.settings_rounded),
                                              label: const Text('Set Destination'),
                                            )
                                          : ElevatedButton.icon(
                                              onPressed: (folder.enabled && !_isBackupDisabled(folder, ref) && !isFolderInQueue)
                                                  ? () => ref.read(backupQueueProvider.notifier).createAndAddJob(folder.id)
                                                  : null,
                                              icon: isFolderBackingUp
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                                      ),
                                                    )
                                                  : const Icon(Icons.play_arrow_rounded),
                                              label: Text(isFolderBackingUp ? 'Backing Up' : (isFolderInQueue ? 'Queued' : 'Backup Now')),
                                            ),
                                    ],
                                  ),
                            const Divider(height: 24),
                            // Details
                            _buildDetailRow(
                              context,
                              label: 'Source',
                              value: folder.sourcePath,
                              icon: Icons.drive_file_rename_outline_rounded,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              label: 'Destination',
                              value: isDestinationMissing ? 'Destination Not Configured' : folder.destinationPath,
                              icon: Icons.folder_zip_rounded,
                              isError: isDestinationMissing,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              label: 'Last Backup',
                              value: folder.lastBackupAt != null
                                  ? DateFormat('yyyy-MM-dd HH:mm').format(folder.lastBackupAt!)
                                  : 'Never backed up',
                              icon: Icons.access_time_rounded,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSetDestination(BuildContext context, WidgetRef ref, BackupFolder folder) async {
    final controller = ref.read(folderManagerControllerProvider(ref));
    final stats = ref.read(folderStatsProvider(folder.id)).value;
    final rules = stats?.rules ?? const FolderRules();

    if (!context.mounted) return;
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
        destinationType: result['destinationType'],
        deviceUuid: result['deviceUuid'],
        deviceName: result['deviceName'],
        remoteFolderId: result['remoteFolderId'],
        remoteFolderPath: result['remoteFolderPath'],
      );
    }
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isError ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isError ? theme.colorScheme.error : null,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isError ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: isError ? FontWeight.bold : null,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  bool _isBackupDisabled(BackupFolder folder, WidgetRef ref) {
    if (folder.destinationPath.trim().isEmpty) return true;
    if (!Directory(folder.sourcePath).existsSync()) return true;
    try {
      Directory(folder.sourcePath).listSync();
    } catch (_) {
      return true;
    }

    if (folder.destinationType == 'remote' && folder.deviceUuid != null) {
      final pairedDevices = ref.watch(pairedDevicesStreamProvider).value ?? [];
      final device = pairedDevices.firstWhere(
        (d) => d.id == folder.deviceUuid,
        orElse: () => DeviceModel(
          id: '',
          name: '',
          platform: '',
          osVersion: '',
          appVersion: '',
          deviceModel: '',
          pairingDate: DateTime.now(),
          lastSeen: DateTime.now(),
          trustStatus: '',
          connectionStatus: 'Offline',
          ipAddress: '',
          port: 0,
          storageInfo: '',
        ),
      );
      if (device.id.isEmpty || device.connectionStatus != 'Online') {
        return true;
      }
    }
    return false;
  }
}

class BackupQueuePanel extends ConsumerWidget {
  const BackupQueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(backupQueueProvider);
    final queueNotifier = ref.read(backupQueueProvider.notifier);
    final theme = Theme.of(context);

    if (queueState.jobs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the active job (Preparing, Ready, etc.)
    final activeJob = queueState.jobs.firstWhere(
      (j) => j.id == queueState.activeJobId,
      orElse: () => queueState.jobs.firstWhere(
        (j) => j.status == 'Preparing' || j.status == 'Ready',
        orElse: () => queueState.jobs.firstWhere(
          (j) => j.status == 'Waiting' || j.status == 'Queued',
          orElse: () => queueState.jobs.last,
        ),
      ),
    );

    final pendingJobs = queueState.jobs.where((j) => j.status == 'Waiting' || j.status == 'Queued').toList();
    final hasFailedJobs = queueState.jobs.any((j) => j.status == 'Failed' || j.status == 'Cancelled');

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backup Queue',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (queueState.isPaused)
                      IconButton.filledTonal(
                        onPressed: queueNotifier.resumeQueue,
                        icon: const Icon(Icons.play_arrow_rounded),
                        tooltip: 'Resume Queue',
                      )
                    else
                      IconButton.filledTonal(
                        onPressed: queueNotifier.pauseQueue,
                        icon: const Icon(Icons.pause_rounded),
                        tooltip: 'Pause Queue',
                      ),
                    const SizedBox(width: 8),
                    if (hasFailedJobs)
                      IconButton.filledTonal(
                        onPressed: queueNotifier.retryAllFailed,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Retry Failed',
                      ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Current / Active Job info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(activeJob.status, theme).withValues(alpha: 0.1),
                  child: Icon(
                    _getStatusIcon(activeJob.status),
                    color: _getStatusColor(activeJob.status, theme),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job ID: ${activeJob.id}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${activeJob.status}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(activeJob.status, theme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Files Count: ${activeJob.totalFiles} (${activeJob.filesToBackup} to backup, ${activeJob.skippedFiles} skipped)',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estimated Size: ${_formatSize(activeJob.totalSize)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (activeJob.error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Error: ${activeJob.error}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
                if (activeJob.status == 'Waiting' ||
                    activeJob.status == 'Preparing' ||
                    activeJob.status == 'Queued' ||
                    activeJob.status == 'Ready')
                  IconButton(
                    onPressed: () => queueNotifier.cancelJob(activeJob.id),
                    icon: const Icon(Icons.cancel_rounded),
                    color: theme.colorScheme.error,
                    tooltip: 'Cancel Job',
                  )
                else if (activeJob.status == 'Failed' || activeJob.status == 'Cancelled')
                  IconButton(
                    onPressed: () => queueNotifier.retryJob(activeJob.id),
                    icon: const Icon(Icons.replay_rounded),
                    color: theme.colorScheme.primary,
                    tooltip: 'Retry Job',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeJob.status == 'Preparing' || activeJob.status == 'Ready') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: activeJob.progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(activeJob.progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            if (pendingJobs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Pending Jobs in Queue (${pendingJobs.length})',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pendingJobs.length,
                  itemBuilder: (context, index) {
                    final job = pendingJobs[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pending_actions_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            job.id,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => queueNotifier.cancelJob(job.id),
                            child: Icon(Icons.close_rounded, size: 16, color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'Waiting':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Queued':
        return Colors.indigo;
      case 'Ready':
        return Colors.teal;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.grey;
      case 'Failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Waiting':
        return Icons.hourglass_empty_rounded;
      case 'Preparing':
        return Icons.analytics_rounded;
      case 'Queued':
        return Icons.queue_play_next_rounded;
      case 'Ready':
        return Icons.play_arrow_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      case 'Failed':
        return Icons.error_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length - 1) ~/ 3;
    if (i >= suffixes.length) i = suffixes.length - 1;
    double size = bytes.toDouble();
    for (int j = 0; j < i; j++) {
      size /= 1024.0;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }
}
