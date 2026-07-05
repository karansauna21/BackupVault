import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../folder_manager/folder_manager_provider.dart';
import '../view_models/backup_view_model.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderManagerProvider);
    final backupState = ref.watch(backupProvider);
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
          // Active Backup Progress Panel
          if (backupState.isBackingUp)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backing up "${backupState.currentFolderName}"',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              backupState.currentStatusText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(backupState.progress * 100).toInt()}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: backupState.progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

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
                    final isThisBackingUp = backupState.isBackingUp && backupState.currentFolderId == folder.id;

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
                                        child: ElevatedButton.icon(
                                          onPressed: (!folder.enabled || backupState.isBackingUp)
                                              ? null
                                              : () => ref.read(backupProvider.notifier).runBackup(folder),
                                          icon: isThisBackingUp
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.play_arrow_rounded),
                                          label: Text(isThisBackingUp ? 'Backing Up' : 'Backup Now'),
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
                                      ElevatedButton.icon(
                                        onPressed: (!folder.enabled || backupState.isBackingUp)
                                            ? null
                                            : () => ref.read(backupProvider.notifier).runBackup(folder),
                                        icon: isThisBackingUp
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                                ),
                                              )
                                            : const Icon(Icons.play_arrow_rounded),
                                        label: Text(isThisBackingUp ? 'Backing Up' : 'Backup Now'),
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
                              value: folder.destinationPath,
                              icon: Icons.folder_zip_rounded,
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

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
