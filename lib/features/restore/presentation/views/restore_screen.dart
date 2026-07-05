import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../folder_manager/folder_manager_provider.dart';
import '../view_models/restore_view_model.dart';

class RestoreScreen extends ConsumerWidget {
  const RestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restorePointsAsync = ref.watch(restorePointsProvider);
    final restoreState = ref.watch(restoreProvider);
    final foldersAsync = ref.watch(folderManagerProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Map folderId to name for display
    final Map<int, String> folderNames = {};
    foldersAsync.whenData((folders) {
      for (var f in folders) {
        folderNames[f.id] = f.name;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restores'),
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
          // Active Restore Progress Panel
          if (restoreState.isRestoring)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
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
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restoring backup point (ID: ${restoreState.currentHistoryId})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restoreState.statusText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(restoreState.progress * 100).toInt()}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: restoreState.progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),

          // Main list of restore points
          Expanded(
            child: restorePointsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading restore points: $err'),
              ),
              data: (points) {
                if (points.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No restore points available yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete a backup first to create a restore point.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    final folderName = folderNames[point.folderId] ?? 'Deleted Folder (ID ${point.folderId})';
                    final isThisRestoring = restoreState.isRestoring && restoreState.currentHistoryId == point.id;

                    if (isMobile) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.settings_backup_restore_rounded,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Restore point for "$folderName"',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(point.timestamp)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Files: ${point.filesCount} (${FileSizeFormatter.formatBytes(point.totalSize)})',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: restoreState.isRestoring
                                      ? null
                                      : () {
                                          ref.read(restoreProvider.notifier).runRestore(point, folderName);
                                        },
                                  icon: isThisRestoring
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.restore_rounded, size: 18),
                                  label: Text(isThisRestoring ? 'Restoring' : 'Restore'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.settings_backup_restore_rounded,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        title: Text(
                          'Restore point for "$folderName"',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(point.timestamp)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Files: ${point.filesCount} (${FileSizeFormatter.formatBytes(point.totalSize)})',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: restoreState.isRestoring
                              ? null
                              : () {
                                  ref.read(restoreProvider.notifier).runRestore(point, folderName);
                                },
                          icon: isThisRestoring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.restore_rounded, size: 18),
                          label: Text(isThisRestoring ? 'Restoring' : 'Restore'),
                          style: ElevatedButton.styleFrom(
                             backgroundColor: theme.colorScheme.secondary,
                             foregroundColor: Colors.white,
                          ),
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
}
