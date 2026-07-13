import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_controller.dart';
import 'dashboard_models.dart';
import 'dashboard_provider.dart';
import 'dashboard_widgets.dart';
import '../../core/copy_engine/copy_job.dart';
import '../../core/copy_engine/copy_queue.dart';
import '../../core/auto_backup/auto_backup_provider.dart';
import '../../core/remote_backup/remote_status_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final controller = ref.watch(dashboardControllerProvider);

    final copyQueue = ref.watch(copyQueueProvider);
    final runningJobs = copyQueue.where((j) => j.status == CopyStatus.copying).toList();

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1000;
    final isDesktop = width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(dashboardProvider);
              ref.invalidate(recentActivityProvider);
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading dashboard: $err', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        data: (stats) {
          final int cardCount = isDesktop
              ? 4
              : (isTablet ? 3 : 2);
          final double aspectRatio = isDesktop
              ? 2.8
              : (isTablet ? 2.2 : 1.25);

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Dashboard',
                            style: (isMobile
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.headlineMedium)
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time automated backup & restoration monitoring',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: stats.backupStatus == 'Backing Up'
                            ? Colors.green
                            : Colors.grey,
                        radius: 6,
                      ),
                      label: Text(stats.backupStatus),
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary cards grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cardCount,
                  crossAxisSpacing: isMobile ? 12 : 16,
                  mainAxisSpacing: isMobile ? 12 : 16,
                  childAspectRatio: aspectRatio,
                  children: [
                    DashboardCard(
                      title: 'Watched Folders',
                      value: '${stats.watchedFoldersCount}',
                      icon: Icons.folder_shared_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    DashboardCard(
                      title: 'Total Backup Size',
                      value: formatBytes(stats.totalBackupSize),
                      icon: Icons.storage_rounded,
                      color: Colors.blue,
                    ),
                    DashboardCard(
                      title: 'Pending Queue',
                      value: '${stats.pendingQueueSize} files',
                      icon: Icons.backup_table_rounded,
                      color: Colors.orange,
                    ),
                    DashboardCard(
                      title: 'Backup Speed',
                      value: formatSpeed(stats.averageBackupSpeed),
                      icon: Icons.speed_rounded,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAutoBackupMonitor(context, theme, ref),
                const SizedBox(height: 24),
                _buildRemoteBackupMonitor(context, theme, ref),
                const SizedBox(height: 24),

                // Split Layout for Large Screen, Linear for Mobile
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLiveActivityPanel(theme, runningJobs),
                            const SizedBox(height: 24),
                            _buildQueuePanel(theme, copyQueue, ref),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStorageGrowthPanel(theme, stats),
                            const SizedBox(height: 24),
                            _buildQuickActionsPanel(context, theme, controller),
                            const SizedBox(height: 24),
                            _buildRecentActivityPanel(theme, activityAsync),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLiveActivityPanel(theme, runningJobs),
                            const SizedBox(height: 24),
                            _buildQueuePanel(theme, copyQueue, ref),
                            const SizedBox(height: 24),
                            _buildRecentActivityPanel(theme, activityAsync),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStorageGrowthPanel(theme, stats),
                            const SizedBox(height: 24),
                            _buildQuickActionsPanel(context, theme, controller),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildLiveActivityPanel(theme, runningJobs),
                  const SizedBox(height: 24),
                  _buildQueuePanel(theme, copyQueue, ref),
                  const SizedBox(height: 24),
                  _buildStorageGrowthPanel(theme, stats),
                  const SizedBox(height: 24),
                  _buildQuickActionsPanel(context, theme, controller),
                  const SizedBox(height: 24),
                  _buildRecentActivityPanel(theme, activityAsync),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveActivityPanel(ThemeData theme, List<CopyJob> runningJobs) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Activity',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            if (runningJobs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No active backup processes running',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: runningJobs.map((job) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                job.sourcePath,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatSpeed(job.speed),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: job.progress,
                          backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(job.progress * 100).toStringAsFixed(1)}% completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueuePanel(ThemeData theme, List<CopyJob> copyQueue, WidgetRef ref) {
    final notifier = ref.read(copyQueueProvider.notifier);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Backup Queue (${copyQueue.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.pause_circle_filled_rounded),
                      tooltip: 'Pause Queue',
                      onPressed: () => notifier.pauseQueue(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_filled_rounded),
                      tooltip: 'Resume Queue',
                      onPressed: () => notifier.resumeQueue(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            if (copyQueue.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Queue is empty',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(copyQueue.length, 5),
                itemBuilder: (context, index) {
                  final job = copyQueue[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      job.sourcePath,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Status: ${job.status.name.toUpperCase()} • Size: ${formatBytes(job.fileSize)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (job.status == CopyStatus.copying)
                          IconButton(
                            icon: const Icon(Icons.pause_rounded, size: 20),
                            onPressed: () => notifier.pauseJob(job.id),
                          ),
                        if (job.status == CopyStatus.paused)
                          IconButton(
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            onPressed: () => notifier.resumeJob(job.id),
                          ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 20, color: Colors.redAccent),
                          onPressed: () => notifier.cancelJob(job.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageGrowthPanel(ThemeData theme, DashboardStats stats) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Growth & Storage',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            SizedBox(
              height: 180,
              child: DashboardLineChart(
                dataPoints: const [12.0, 15.0, 18.0, 22.0, 24.0, 30.0, 35.0],
                labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                lineColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsPanel(
    BuildContext context,
    ThemeData theme,
    DashboardController controller,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                QuickActionButton(
                  label: 'Start Engine',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => controller.startBackup(),
                  color: Colors.green,
                ),
                QuickActionButton(
                  label: 'Pause Engine',
                  icon: Icons.pause_rounded,
                  onTap: () => controller.pauseBackup(),
                  color: Colors.orange,
                ),
                QuickActionButton(
                  label: 'Folders Manager',
                  icon: Icons.folder_shared_rounded,
                  onTap: () => controller.navigateToFolders(context),
                  color: theme.colorScheme.primary,
                ),
                QuickActionButton(
                  label: 'Restore Center',
                  icon: Icons.settings_backup_restore_rounded,
                  onTap: () => controller.navigateToRestore(context),
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityPanel(ThemeData theme, AsyncValue<List<ActivityEvent>> activityAsync) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity Logs',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            activityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading activity: $err'),
              data: (events) {
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No recent activity events logged',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    Color iconColor = Colors.blue;
                    IconData icon = Icons.info_outline;

                    if (event.type == 'error') {
                      iconColor = Colors.red;
                      icon = Icons.error_outline;
                    } else if (event.type == 'warning') {
                      iconColor = Colors.orange;
                      icon = Icons.warning_amber_rounded;
                    } else if (event.type == 'success') {
                      iconColor = Colors.green;
                      icon = Icons.check_circle_outline_rounded;
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(icon, color: iconColor),
                      title: Text(event.title, style: theme.textTheme.bodyMedium),
                      subtitle: Text(event.description, style: theme.textTheme.bodySmall),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupMonitor(BuildContext context, ThemeData theme, WidgetRef ref) {
    final autoBackupStats = ref.watch(autoBackupDashboardStatsProvider);

    final String status = autoBackupStats['syncStatus'] ?? 'Paused';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Syncing':
        statusColor = Colors.green;
        statusIcon = Icons.sync_rounded;
        break;
      case 'Connected':
      case 'Waiting':
        statusColor = Colors.blue;
        statusIcon = Icons.wifi_rounded;
        break;
      case 'Failed':
        statusColor = Colors.red;
        statusIcon = Icons.error_rounded;
        break;
      case 'Paused':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_rounded;
        break;
      case 'Offline':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_off_rounded;
        break;
    }

    final int connected = autoBackupStats['connectedDevices'] ?? 0;
    final int pending = autoBackupStats['pendingFiles'] ?? 0;
    final double speed = autoBackupStats['currentSpeed'] ?? 0.0;
    final int eta = autoBackupStats['eta'] ?? 0;
    final String currentFile = autoBackupStats['currentTransfer'] ?? 'None';
    final DateTime? lastSync = autoBackupStats['lastSync'] as DateTime?;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi_tethering_rounded, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Automatic Network Backup Monitor',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _buildStatTile(theme, 'Connected Devices', '$connected online', Icons.devices_rounded),
                _buildStatTile(theme, 'Pending Files', '$pending in queue', Icons.queue_rounded),
                _buildStatTile(theme, 'Current Speed', formatSpeed(speed), Icons.speed_rounded),
                _buildStatTile(theme, 'ETA', eta > 0 ? '${eta}s' : 'N/A', Icons.timer_rounded),
                _buildStatTile(theme, 'Last Sync', lastSync != null ? _formatDateTime(lastSync) : 'Never', Icons.history_rounded),
                _buildStatTile(theme, 'Current Syncing File', currentFile, Icons.file_present_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _buildRemoteBackupMonitor(BuildContext context, ThemeData theme, WidgetRef ref) {
    final remoteStats = ref.watch(remoteDashboardStatsProvider);

    final int remoteDevices = remoteStats['remoteDevices'] ?? 0;
    final String currentUpload = remoteStats['currentUpload'] ?? 'None';
    final String currentDownload = remoteStats['currentDownload'] ?? 'None';
    final double speed = remoteStats['internetSpeed'] ?? 0.0;
    final double progress = remoteStats['syncProgress'] ?? 0.0;
    final int pendingUploads = remoteStats['pendingUploads'] ?? 0;

    final hasActiveSync = currentUpload != 'None';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_queue_rounded, color: theme.colorScheme.tertiary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Remote Backup Monitor (Internet)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (hasActiveSync ? Colors.green : Colors.blue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasActiveSync ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded,
                        color: hasActiveSync ? Colors.green : Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasActiveSync ? 'SYNCING' : 'READY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: hasActiveSync ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _buildStatTile(theme, 'Remote Devices', '$remoteDevices paired', Icons.cloud_circle_rounded),
                _buildStatTile(theme, 'Pending Uploads', '$pendingUploads files', Icons.queue_play_next_rounded),
                _buildStatTile(theme, 'Current Upload', currentUpload, Icons.upload_file_rounded),
                _buildStatTile(theme, 'Current Download', currentDownload, Icons.download_for_offline_rounded),
                _buildStatTile(theme, 'Internet Speed', formatSpeed(speed), Icons.speed_rounded),
                _buildStatTile(
                  theme,
                  'Sync Progress',
                  hasActiveSync ? '${(progress * 100).toStringAsFixed(1)}%' : 'N/A',
                  Icons.donut_large_rounded,
                ),
              ],
            ),
            if (hasActiveSync) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
