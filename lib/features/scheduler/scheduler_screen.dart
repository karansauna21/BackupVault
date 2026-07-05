import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/repositories/repository_providers.dart';
import 'scheduler_models.dart';
import 'scheduler_provider.dart';
import 'scheduler_controller.dart';
import 'schedule_history.dart';
import 'job_manager.dart';

class SchedulerScreen extends ConsumerStatefulWidget {
  const SchedulerScreen({super.key});

  @override
  ConsumerState<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends ConsumerState<SchedulerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cronController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedules = ref.watch(schedulesProvider);
    final upcoming = ref.watch(upcomingJobsProvider);
    final running = ref.watch(runningJobsProvider);
    final paused = ref.watch(pausedJobsProvider);
    final history = ref.watch(scheduleHistoryProvider);
    final autoStatus = ref.watch(automationStatusProvider);
    final controller = ref.watch(schedulerControllerProvider);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isDesktop ? 'Smart Scheduler & Automation' : 'Scheduler',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              if (isDesktop) ...[
                Text(
                  'Automation Engine',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
              ],
              Switch(
                value: autoStatus.enabled,
                onChanged: (val) {
                  controller.toggleAutomation(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Automation engine enabled.' : 'Automation engine paused.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.schedule_rounded), text: 'Schedules'),
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Timeline & Calendar'),
            Tab(icon: Icon(Icons.queue_play_next_rounded), text: 'Job Queue'),
            Tab(icon: Icon(Icons.tune_rounded), text: 'Smart Rules'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleEditor(context, null),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Schedule'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Schedules List
          _buildSchedulesTab(theme, schedules, controller, isDesktop),

          // TAB 2: Calendar & Timeline
          _buildCalendarTimelineTab(theme, upcoming, history, controller, isDesktop),

          // TAB 3: Job Queue
          _buildQueueTab(theme, running, paused, ref.watch(schedulerJobManagerProvider), controller, isDesktop),

          // TAB 4: Smart Rules & Simulator
          _buildSmartRulesTab(theme, autoStatus, controller, isDesktop),
        ],
      ),
    );
  }

  // TAB 1 Builder: Schedule List
  Widget _buildSchedulesTab(
    ThemeData theme,
    List<ScheduleConfig> schedules,
    SchedulerController controller,
    bool isDesktop,
  ) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_off_rounded, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No backup schedules configured', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Create a schedule to automate your folder backups.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showScheduleEditor(context, null),
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Create First Schedule'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];

        final scheduleDetails = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    schedule.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: schedule.enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.scheduleType,
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Folder info
            FutureBuilder<List<BackupFolder>>(
              future: ref.read(backupFolderRepositoryProvider).getAllFolders(),
              builder: (context, snapshot) {
                final folder = snapshot.data?.where((f) => f.id == schedule.folderId).firstOrNull;
                return Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        folder != null ? 'Folder: ${folder.name} (${folder.sourcePath})' : 'Folder missing',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            // Triggers
            if (schedule.triggerTypes.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: schedule.triggerTypes.map((t) {
                  return Chip(
                    labelPadding: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.bolt_rounded, size: 12),
                    label: Text(t, style: const TextStyle(fontSize: 10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            // Run history helper
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      schedule.lastRunTime != null
                          ? 'Last ran: ${DateFormat('yyyy-MM-dd HH:mm').format(schedule.lastRunTime!)}'
                          : 'Never ran',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.next_plan_rounded, size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      schedule.nextRunTime != null
                          ? 'Next run: ${DateFormat('yyyy-MM-dd HH:mm').format(schedule.nextRunTime!)}'
                          : 'Next run: N/A',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final scheduleControls = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: schedule.enabled,
              onChanged: (val) => controller.toggleSchedule(schedule.id, val),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.green),
                  tooltip: 'Run Now',
                  onPressed: () async {
                    final ok = await controller.triggerBackupManually(schedule);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Backup job queued in Priority Queue.' : 'Failed to trigger backup.'),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit',
                  onPressed: () => _showScheduleEditor(context, schedule),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  tooltip: 'Delete',
                  onPressed: () => _showDeleteConfirmation(context, controller, schedule.id),
                ),
              ],
            ),
          ],
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: schedule.enabled ? theme.colorScheme.primary.withValues(alpha: 0.2) : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(child: scheduleDetails),
                      const SizedBox(width: 16),
                      scheduleControls,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      scheduleDetails,
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status: ${schedule.enabled ? "Active" : "Paused"}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: schedule.enabled,
                                onChanged: (val) => controller.toggleSchedule(schedule.id, val),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.green),
                                onPressed: () async {
                                  final ok = await controller.triggerBackupManually(schedule);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'Backup job queued.' : 'Failed to trigger.'),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () => _showScheduleEditor(context, schedule),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                onPressed: () => _showDeleteConfirmation(context, controller, schedule.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // TAB 2 Builder: Calendar & Timeline
  Widget _buildCalendarTimelineTab(
    ThemeData theme,
    List<UpcomingJobInfo> upcoming,
    List<ScheduleHistory> history,
    SchedulerController controller,
    bool isDesktop,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Mini Calendar Highlight & Upcoming Schedule list
          Expanded(
            flex: isDesktop ? 3 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upcoming Backup Schedule', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: upcoming.isEmpty
                      ? Center(child: Text('No upcoming jobs scheduled.', style: theme.textTheme.bodyMedium))
                      : ListView.builder(
                          itemCount: upcoming.length,
                          itemBuilder: (context, index) {
                            final info = upcoming[index];
                            return ListTile(
                              leading: const Icon(Icons.alarm_on_rounded, color: Colors.blueAccent),
                              title: Text(info.schedule.name),
                              subtitle: Text('Folder ID: ${info.schedule.folderId} • Type: ${info.schedule.scheduleType}'),
                              trailing: Text(
                                DateFormat('MM-dd HH:mm').format(info.nextRunTime),
                                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (isDesktop) const VerticalDivider(width: 48),
          // Right side: Timeline of past history
          if (isDesktop)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Execution History Log', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all_rounded, color: Colors.redAccent),
                        label: const Text('Clear Log', style: TextStyle(color: Colors.redAccent)),
                        onPressed: () => controller.clearHistory(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: history.isEmpty
                        ? Center(child: Text('No backup execution history available.', style: theme.textTheme.bodyMedium))
                        : ListView.builder(
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];
                              final isSuccess = item.result == 'success';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isSuccess ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
                                child: ListTile(
                                  leading: Icon(
                                    isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    color: isSuccess ? Colors.green : Colors.red,
                                  ),
                                  title: Text('Trigger: ${item.trigger} • Worker: ${item.workerUsed}'),
                                  subtitle: Text(
                                    'Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(item.executionTime)} • Duration: ${item.duration.inMilliseconds} ms${item.errors != null ? '\nError: ${item.errors}' : ''}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.status.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: isSuccess ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      if (item.retryCount > 0)
                                        Text('Retries: ${item.retryCount}', style: theme.textTheme.labelSmall),
                                    ],
                                  ),
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
    );
  }

  // TAB 3 Builder: Job Queue
  Widget _buildQueueTab(
    ThemeData theme,
    List<ScheduledBackupJob> running,
    List<ScheduledBackupJob> paused,
    List<ScheduledBackupJob> allJobs,
    SchedulerController controller,
    bool isDesktop,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Backup Job Queue', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.cleaning_services_rounded),
                label: const Text('Clear Completed/Failed'),
                onPressed: () => ref.read(schedulerJobManagerProvider.notifier).clearCompletedJobs(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: allJobs.isEmpty
                ? const Center(child: Text('No jobs currently in the queue.'))
                : ListView.builder(
                    itemCount: allJobs.length,
                    itemBuilder: (context, index) {
                      final job = allJobs[index];
                      final isRunning = job.status == 'running';
                      final isPaused = job.status == 'paused';
                      final isFailed = job.status == 'failed';
                      final isCompleted = job.status == 'completed';

                      Color statusColor = Colors.grey;
                      if (isRunning) statusColor = Colors.blue;
                      if (isPaused) statusColor = Colors.orange;
                      if (isCompleted) statusColor = Colors.green;
                      if (isFailed) statusColor = Colors.red;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                          'Folder: ${job.folderName}',
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Source: ${job.sourcePath}',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      job.status.toUpperCase(),
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isRunning) ...[
                                LinearProgressIndicator(value: job.progress),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Progress: ${(job.progress * 100).toStringAsFixed(1)}%', style: theme.textTheme.bodySmall),
                                    Text('Trigger: ${job.triggerSource}', style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ],
                              if (job.error != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Error: ${job.error}',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isRunning)
                                    TextButton.icon(
                                      icon: const Icon(Icons.pause_rounded),
                                      label: const Text('Pause'),
                                      onPressed: () => ref.read(schedulerJobManagerProvider.notifier).pauseJob(job.id),
                                    ),
                                  if (isPaused)
                                    TextButton.icon(
                                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.green),
                                      label: const Text('Resume'),
                                      onPressed: () => ref.read(schedulerJobManagerProvider.notifier).resumeJob(job.id),
                                    ),
                                  if (isRunning || isPaused || job.status == 'pending')
                                    TextButton.icon(
                                      icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                                      label: const Text('Cancel'),
                                      onPressed: () => ref.read(schedulerJobManagerProvider.notifier).cancelJob(job.id),
                                    ),
                                ],
                              ),
                            ],
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

  // TAB 4 Builder: Smart Rules & Simulator
  Widget _buildSmartRulesTab(
    ThemeData theme,
    AutomationStatus status,
    SchedulerController controller,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Automation & Rules Simulation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Override or view system settings to test your smart rules (battery levels, gaming mode, CPU usage, etc.)',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // CPU Load Card
              SizedBox(
                width: isDesktop ? 300 : double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.memory_rounded, color: Colors.orangeAccent),
                            const SizedBox(width: 8),
                            Text('CPU Usage Simulator', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Current Usage: ${status.cpuUsage.toStringAsFixed(1)}%',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          min: 0,
                          max: 100,
                          value: status.cpuUsage,
                          onChanged: (val) {
                            controller.updateSystemSimulation(cpu: val);
                          },
                        ),
                        Text(
                          status.cpuUsage > 80.0 ? 'Rule Triggered: PAUSED' : 'Status: HEALTHY',
                          style: TextStyle(
                            color: status.cpuUsage > 80.0 ? Colors.redAccent : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Battery Card
              SizedBox(
                width: isDesktop ? 300 : double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status.isCharging ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text('Battery State Simulator', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Level: ${status.batteryLevel}%',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('AC Charging'),
                            Switch(
                              value: status.isCharging,
                              onChanged: (val) {
                                controller.updateSystemSimulation(charging: val);
                              },
                            ),
                          ],
                        ),
                        Slider(
                          min: 0,
                          max: 100,
                          value: status.batteryLevel.toDouble(),
                          onChanged: (val) {
                            controller.updateSystemSimulation(battery: val.toInt());
                          },
                        ),
                        Text(
                          (!status.isCharging && status.batteryLevel < 20) ? 'Rule Triggered: PAUSED' : 'Status: HEALTHY',
                          style: TextStyle(
                            color: (!status.isCharging && status.batteryLevel < 20) ? Colors.redAccent : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Gaming Mode Card
              SizedBox(
                width: isDesktop ? 300 : double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gamepad_rounded, color: Colors.purpleAccent),
                            const SizedBox(width: 8),
                            Text('Gaming Mode', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          status.gamingMode ? 'ACTIVE' : 'INACTIVE',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: status.gamingMode ? Colors.purpleAccent : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Toggle Gaming Mode'),
                            Switch(
                              value: status.gamingMode,
                              onChanged: (val) {
                                controller.updateSystemSimulation(gaming: val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status.gamingMode ? 'Rule Triggered: PAUSED' : 'Status: HEALTHY',
                          style: TextStyle(
                            color: status.gamingMode ? Colors.redAccent : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Edit / Add Schedule Dialog Builder
  Future<void> _showScheduleEditor(BuildContext context, ScheduleConfig? existing) async {
    final folders = await ref.read(backupFolderRepositoryProvider).getAllFolders();
    if (!context.mounted) return;
    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one backup folder before setting up a schedule.')),
      );
      return;
    }

    final isEdit = existing != null;
    String name = existing?.name ?? 'My Scheduled Backup';
    int folderId = existing?.folderId ?? folders.first.id;
    String scheduleType = existing?.scheduleType ?? 'Daily';
    List<String> triggerTypes = List<String>.from(existing?.triggerTypes ?? []);
    String triggerSpecificTime = existing?.triggerSpecificTime ?? '12:00';
    DateTime? triggerSpecificDate = existing?.triggerSpecificDate;

    // Smart rules state
    bool runOnlyIfDestinationAvailable = existing?.rules.runOnlyIfDestinationAvailable ?? true;
    bool skipDuplicateJobs = existing?.rules.skipDuplicateJobs ?? true;
    bool skipIfBackupAlreadyCompleted = existing?.rules.skipIfBackupAlreadyCompleted ?? false;
    bool retryAutomaticallyAfterFailure = existing?.rules.retryAutomaticallyAfterFailure ?? true;
    bool pauseWhenCpuUsageIsHigh = existing?.rules.pauseWhenCpuUsageIsHigh ?? false;
    bool pauseWhenStorageIsFull = existing?.rules.pauseWhenStorageIsFull ?? false;
    bool pauseDuringGamingMode = existing?.rules.pauseDuringGamingMode ?? false;
    bool pauseWhenBatteryIsLow = existing?.rules.pauseWhenBatteryIsLow ?? false;
    bool resumeAutomatically = existing?.rules.resumeAutomatically ?? true;

    _cronController.text = existing?.customCronExpression ?? '* * * * *';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Backup Schedule' : 'Create Backup Schedule'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextField(
                        decoration: const InputDecoration(labelText: 'Schedule Name'),
                        controller: TextEditingController(text: name),
                        onChanged: (val) => name = val,
                      ),
                      const SizedBox(height: 16),
                      // Folder Selection
                      DropdownButtonFormField<int>(
                        initialValue: folderId,
                        decoration: const InputDecoration(labelText: 'Backup Folder'),
                        items: folders.map((f) {
                          return DropdownMenuItem(value: f.id, child: Text(f.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => folderId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Schedule Type
                      DropdownButtonFormField<String>(
                        initialValue: scheduleType,
                        decoration: const InputDecoration(labelText: 'Schedule Frequency'),
                        items: const [
                          DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                          DropdownMenuItem(value: 'Real-time', child: Text('Real-time (Folder Watcher)')),
                          DropdownMenuItem(value: 'Every Minute', child: Text('Every Minute')),
                          DropdownMenuItem(value: 'Every 5 Minutes', child: Text('Every 5 Minutes')),
                          DropdownMenuItem(value: 'Every 10 Minutes', child: Text('Every 10 Minutes')),
                          DropdownMenuItem(value: 'Every 30 Minutes', child: Text('Every 30 Minutes')),
                          DropdownMenuItem(value: 'Hourly', child: Text('Hourly')),
                          DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'Custom Cron Expression', child: Text('Custom Cron Expression')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => scheduleType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Cron expression input (conditional)
                      if (scheduleType == 'Custom Cron Expression') ...[
                        TextField(
                          controller: _cronController,
                          decoration: const InputDecoration(
                            labelText: 'Cron Expression',
                            hintText: '* * * * * (minute hour day month weekday)',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Specific Date (conditional)
                      if (triggerTypes.contains('Specific Date')) ...[
                        ListTile(
                          title: Text(triggerSpecificDate != null
                              ? 'Date: ${DateFormat('yyyy-MM-dd').format(triggerSpecificDate!)}'
                              : 'Select Specific Date'),
                          trailing: const Icon(Icons.calendar_month_rounded),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) {
                              setState(() => triggerSpecificDate = d);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Specific Time (conditional)
                      if (scheduleType == 'Daily' || scheduleType == 'Weekly' || scheduleType == 'Monthly' || triggerTypes.contains('Specific Time')) ...[
                        ListTile(
                          title: Text('Run Time: $triggerSpecificTime'),
                          trailing: const Icon(Icons.access_time_rounded),
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 12, minute: 0),
                            );
                            if (t != null) {
                              setState(() {
                                final h = t.hour.toString().padLeft(2, '0');
                                final m = t.minute.toString().padLeft(2, '0');
                                triggerSpecificTime = '$h:$m';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Trigger Types
                      Text('System Triggers (Automation)', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Application Startup',
                          'Windows Startup',
                          'Folder Changed',
                          'New File',
                          'Modified File',
                          'USB Connected',
                          'External Drive Connected',
                          'Network Drive Available',
                          'System Idle',
                          'Charging Started',
                          'Specific Time',
                          'Specific Date',
                        ].map((triggerName) {
                          final selected = triggerTypes.contains(triggerName);
                          return FilterChip(
                            label: Text(triggerName),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  triggerTypes.add(triggerName);
                                } else {
                                  triggerTypes.remove(triggerName);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Smart Rules switches
                      Text('Smart Rules Configuration', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Run only if destination available'),
                        subtitle: const Text('Prevents errors by validating connection first.'),
                        value: runOnlyIfDestinationAvailable,
                        onChanged: (val) => setState(() => runOnlyIfDestinationAvailable = val),
                      ),
                      SwitchListTile(
                        title: const Text('Skip duplicate jobs'),
                        subtitle: const Text('Skip if same job is already running or pending.'),
                        value: skipDuplicateJobs,
                        onChanged: (val) => setState(() => skipDuplicateJobs = val),
                      ),
                      SwitchListTile(
                        title: const Text('Skip if backup already completed'),
                        value: skipIfBackupAlreadyCompleted,
                        onChanged: (val) => setState(() => skipIfBackupAlreadyCompleted = val),
                      ),
                      SwitchListTile(
                        title: const Text('Retry automatically after failure'),
                        value: retryAutomaticallyAfterFailure,
                        onChanged: (val) => setState(() => retryAutomaticallyAfterFailure = val),
                      ),
                      SwitchListTile(
                        title: const Text('Pause when CPU usage is high'),
                        value: pauseWhenCpuUsageIsHigh,
                        onChanged: (val) => setState(() => pauseWhenCpuUsageIsHigh = val),
                      ),
                      SwitchListTile(
                        title: const Text('Pause when storage is full'),
                        value: pauseWhenStorageIsFull,
                        onChanged: (val) => setState(() => pauseWhenStorageIsFull = val),
                      ),
                      SwitchListTile(
                        title: const Text('Pause during gaming mode'),
                        value: pauseDuringGamingMode,
                        onChanged: (val) => setState(() => pauseDuringGamingMode = val),
                      ),
                      SwitchListTile(
                        title: const Text('Pause when battery is low'),
                        value: pauseWhenBatteryIsLow,
                        onChanged: (val) => setState(() => pauseWhenBatteryIsLow = val),
                      ),
                      SwitchListTile(
                        title: const Text('Resume automatically'),
                        value: resumeAutomatically,
                        onChanged: (val) => setState(() => resumeAutomatically = val),
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
                  onPressed: () async {
                    final rulesObj = SmartRules(
                      runOnlyIfDestinationAvailable: runOnlyIfDestinationAvailable,
                      skipDuplicateJobs: skipDuplicateJobs,
                      skipIfBackupAlreadyCompleted: skipIfBackupAlreadyCompleted,
                      retryAutomaticallyAfterFailure: retryAutomaticallyAfterFailure,
                      pauseWhenCpuUsageIsHigh: pauseWhenCpuUsageIsHigh,
                      pauseWhenStorageIsFull: pauseWhenStorageIsFull,
                      pauseDuringGamingMode: pauseDuringGamingMode,
                      pauseWhenBatteryIsLow: pauseWhenBatteryIsLow,
                      resumeAutomatically: resumeAutomatically,
                    );

                    final controller = ref.read(schedulerControllerProvider);
                    if (isEdit) {
                      await controller.editSchedule(
                        existing,
                        name: name,
                        folderId: folderId,
                        scheduleType: scheduleType,
                        customCronExpression: scheduleType == 'Custom Cron Expression' ? _cronController.text : null,
                        triggerTypes: triggerTypes,
                        triggerSpecificTime: triggerSpecificTime,
                        triggerSpecificDate: triggerSpecificDate,
                        rules: rulesObj,
                      );
                    } else {
                      await controller.addSchedule(
                        name: name,
                        folderId: folderId,
                        scheduleType: scheduleType,
                        customCronExpression: scheduleType == 'Custom Cron Expression' ? _cronController.text : null,
                        triggerTypes: triggerTypes,
                        triggerSpecificTime: triggerSpecificTime,
                        triggerSpecificDate: triggerSpecificDate,
                        rules: rulesObj,
                      );
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete Dialog Builder
  Future<void> _showDeleteConfirmation(BuildContext context, SchedulerController controller, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this backup schedule? This cannot be undone.'),
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
      await controller.deleteSchedule(id);
    }
  }
}
