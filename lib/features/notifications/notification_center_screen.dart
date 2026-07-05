import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'notification_models.dart';
import 'notification_provider.dart';
import 'notification_controller.dart';
import 'notification_history.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Custom overlay state for active mock toasting
  OverlayEntry? _activeToast;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      ref.read(notificationFiltersProvider.notifier).updateFilters(
        (f) => f.copyWith(searchPrefix: () => _searchController.text),
      );
    });

    // Register active notification listener for in-app toasts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).registerListener(_showInAppToast);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _activeToast?.remove();
    _activeToast = null;
    super.dispose();
  }

  /// Display a highly animated premium in-app toast card
  void _showInAppToast(NotificationItem item) {
    if (!mounted) return;

    _activeToast?.remove();
    
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    _activeToast = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: isDesktop ? 24 : 56,
          right: isDesktop ? 24 : 16,
          left: isDesktop ? null : 16,
          width: isDesktop ? 380 : null,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, (1 - val) * -20),
                    child: child,
                  ),
                );
              },
              child: Card(
                elevation: 8,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: item.priority.color.withAlpha(80), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                color: theme.colorScheme.surface.withAlpha(240),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.priority.color.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.priority.icon, color: item.priority.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.priority.name.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: item.priority.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(item.timestamp),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.category.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _activeToast?.remove();
                          _activeToast = null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_activeToast!);

    // Automatically remove after display duration
    Future.delayed(item.priority.displayDuration, () {
      if (_activeToast != null) {
        _activeToast?.remove();
        _activeToast = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    
    final notificationsAsync = ref.watch(filteredNotificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final allNotificationsAsync = ref.watch(notificationListProvider);
    final controller = NotificationController(ref);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notification Center & Alerts'),
            const SizedBox(width: 8),
            if (unreadCount > 0)
              Badge(
                label: Text(unreadCount.toString()),
                child: const Icon(Icons.notifications_rounded),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark All as Read',
            onPressed: () => controller.markAllAsRead(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear History',
            onPressed: () => _confirmClearHistory(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            tooltip: 'Trigger Test Notification',
            onPressed: _triggerTestNotification,
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Left pane: sidebar filters and stats
                SizedBox(
                  width: 320,
                  child: Card(
                    margin: const EdgeInsets.only(left: 16, bottom: 16, right: 8, top: 8),
                    child: _buildSidebar(allNotificationsAsync, controller),
                  ),
                ),
                // Right pane: tabbed main content
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.only(right: 16, bottom: 16, left: 8, top: 8),
                    child: _buildMainPane(notificationsAsync, controller),
                  ),
                ),
              ],
            )
          : _buildMainPane(notificationsAsync, controller),
    );
  }

  Widget _buildSidebar(AsyncValue<List<NotificationItem>> allAsync, NotificationController controller) {
    final theme = Theme.of(context);
    final filters = ref.watch(notificationFiltersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          allAsync.when(
            data: (list) {
              final stats = NotificationHistoryManager.calculateStats(list);
              return Column(
                children: [
                  _buildStatRow('Total Received', stats.totalCount.toString(), Colors.blue),
                  _buildStatRow('Unread Alerts', stats.unreadCount.toString(), Colors.red),
                  _buildStatRow('Pinned Items', stats.pinnedCount.toString(), Colors.amber),
                  _buildStatRow('Critical Logs', stats.criticalCount.toString(), Colors.deepOrange),
                  _buildStatRow('Received Today', stats.todayCount.toString(), Colors.green),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => controller.resetFilters(),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Priority Selector Dropdown
          DropdownButtonFormField<NotificationPriority>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Priority Level', border: OutlineInputBorder()),
            initialValue: filters.priority,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Priorities')),
              ...NotificationPriority.values.map(
                (p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())),
              ),
            ],
            onChanged: controller.updatePriorityFilter,
          ),
          const SizedBox(height: 16),
          // Category Selector Dropdown
          DropdownButtonFormField<NotificationCategory>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            initialValue: filters.category,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Categories')),
              ...NotificationCategory.values.map(
                (c) => DropdownMenuItem(value: c, child: Text(c.displayName)),
              ),
            ],
            onChanged: controller.updateCategoryFilter,
          ),
          const SizedBox(height: 16),
          // Date Range picker button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            icon: const Icon(Icons.date_range_rounded),
            label: Text(
              filters.dateRange == null
                  ? 'Pick Date Range'
                  : '${DateFormat('MM/dd').format(filters.dateRange!.start)} - ${DateFormat('MM/dd').format(filters.dateRange!.end)}',
            ),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                initialDateRange: filters.dateRange,
              );
              if (range != null) {
                controller.updateDateRangeFilter(range);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainPane(AsyncValue<List<NotificationItem>> filteredAsync, NotificationController controller) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active_rounded), text: 'Alerts Log'),
            Tab(icon: Icon(Icons.settings_suggest_rounded), text: 'Configure System'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Alerts log view
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search message content, worker, or paths...',
                      leading: const Icon(Icons.search_rounded),
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
                    ),
                  ),
                  const Divider(height: 1),
                  if (!isDesktop) ...[
                    // Show Filter Chips inline for mobile
                    _buildMobileFilterRow(controller),
                    const Divider(height: 1),
                  ],
                  Expanded(
                    child: filteredAsync.when(
                      data: (list) => _buildNotificationList(list, controller),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading alerts: $err')),
                    ),
                  ),
                ],
              ),
              // 2. Configure System view
              _buildSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilterRow(NotificationController controller) {
    final filters = ref.watch(notificationFiltersProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.filter_list_rounded, size: 16),
            label: const Text('Reset Filters'),
            onPressed: () => controller.resetFilters(),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(filters.priority == null ? 'Priority' : filters.priority!.name.toUpperCase()),
            selected: filters.priority != null,
            onSelected: (_) => _showPriorityFilterSheet(controller),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(filters.category == null ? 'Category' : filters.category!.displayName),
            selected: filters.category != null,
            onSelected: (_) => _showCategoryFilterSheet(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> list, NotificationController controller) {
    final theme = Theme.of(context);
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'No alerts found matching current filters',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Toggle your search keywords or priority filter configuration.'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: item.isRead ? theme.colorScheme.outlineVariant : item.priority.color,
              width: item.isRead ? 1.0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(item.priority.icon, color: item.priority.color, size: 28),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  if (item.isPinned)
                    const Icon(Icons.push_pin_rounded, color: Colors.amber, size: 18),
                ],
              ),
              subtitle: Text(
                item.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.message, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Timestamp: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp)}',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text('Priority: ${item.priority.name.toUpperCase()}', style: theme.textTheme.labelSmall),
                        ],
                      ),
                      if (item.source != null) ...[
                        const SizedBox(height: 6),
                        Text('Source: ${item.source}', style: theme.textTheme.labelSmall),
                      ],
                      if (item.destination != null) ...[
                        const SizedBox(height: 6),
                        Text('Destination: ${item.destination}', style: theme.textTheme.labelSmall),
                      ],
                      if (item.worker != null) ...[
                        const SizedBox(height: 6),
                        Text('Backup Worker: ${item.worker}', style: theme.textTheme.labelSmall),
                      ],
                      if (item.relatedBackupId != null) ...[
                        const SizedBox(height: 6),
                        Text('Related Backup Job ID: ${item.relatedBackupId}', style: theme.textTheme.labelSmall),
                      ],
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          IconButton(
                            icon: Icon(item.isRead ? Icons.mark_as_unread_rounded : Icons.mark_chat_read_rounded),
                            tooltip: item.isRead ? 'Mark as Unread' : 'Mark as Read',
                            onPressed: () => controller.markAsRead(item.id, !item.isRead),
                          ),
                          IconButton(
                            icon: Icon(item.isPinned ? Icons.pin_drop_rounded : Icons.push_pin_rounded),
                            tooltip: item.isPinned ? 'Unpin' : 'Pin',
                            onPressed: () => controller.togglePin(item.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copy Details',
                            onPressed: () => controller.copyDetails(item, context),
                          ),
                          if (item.destination != null || item.source != null)
                            IconButton(
                              icon: const Icon(Icons.folder_open_rounded),
                              tooltip: 'Open Directory',
                              onPressed: () => controller.openRelatedFolder(item, context),
                            ),
                          if (item.category == NotificationCategory.backupFailed)
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Retry Backup Job',
                              onPressed: () => controller.retryFailedBackup(item, context),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                            tooltip: 'Delete Notification',
                            onPressed: () => controller.deleteNotification(item.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('General Alert Rules', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Do Not Disturb switch
            SwitchListTile(
              title: const Text('Do Not Disturb (DND)'),
              subtitle: const Text('Mute all alerts except critical system warnings.'),
              value: settings.dndEnabled,
              onChanged: (val) {
                ref.read(notificationSettingsProvider.notifier).updateSettings(
                  settings.copyWith(dndEnabled: val),
                );
              },
            ),
            const Divider(),
            // Quiet hours switch
            SwitchListTile(
              title: const Text('Quiet Hours'),
              subtitle: const Text('Silence non-critical alerts during scheduled hours.'),
              value: settings.quietHoursEnabled,
              onChanged: (val) {
                ref.read(notificationSettingsProvider.notifier).updateSettings(
                  settings.copyWith(quietHoursEnabled: val),
                );
              },
            ),
            if (settings.quietHoursEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time_rounded),
                        label: Text('Starts: ${settings.quietHoursStart}'),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 22, minute: 0),
                          );
                          if (time != null) {
                            final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            ref.read(notificationSettingsProvider.notifier).updateSettings(
                              settings.copyWith(quietHoursStart: formatted),
                            );
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time_rounded),
                        label: Text('Ends: ${settings.quietHoursEnd}'),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (time != null) {
                            final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            ref.read(notificationSettingsProvider.notifier).updateSettings(
                              settings.copyWith(quietHoursEnd: formatted),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),
            // Notification delivery frequency dropdown
            ListTile(
              title: const Text('Notification Frequency'),
              subtitle: const Text('Deliver alerts immediately or in batches.'),
              trailing: DropdownButton<String>(
                value: settings.frequency,
                items: const [
                  DropdownMenuItem(value: 'immediate', child: Text('Immediate')),
                  DropdownMenuItem(value: 'batch', child: Text('Batch Summary')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(notificationSettingsProvider.notifier).updateSettings(
                      settings.copyWith(frequency: val),
                    );
                  }
                },
              ),
            ),
            if (settings.frequency == 'batch') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Batch Interval:'),
                    DropdownButton<int>(
                      value: settings.batchIntervalMinutes,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 minutes')),
                        DropdownMenuItem(value: 15, child: Text('15 minutes')),
                        DropdownMenuItem(value: 30, child: Text('30 minutes')),
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(notificationSettingsProvider.notifier).updateSettings(
                            settings.copyWith(batchIntervalMinutes: val),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),
            const SizedBox(height: 12),
            Text('Toggle Alert Categories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Build category filters
            for (final cat in NotificationCategory.values)
              CheckboxListTile(
                title: Text(cat.displayName),
                value: settings.categoriesEnabled[cat] ?? true,
                onChanged: (val) {
                  if (val != null) {
                    final Map<NotificationCategory, bool> nextCats = Map.from(settings.categoriesEnabled);
                    nextCats[cat] = val;
                    ref.read(notificationSettingsProvider.notifier).updateSettings(
                      settings.copyWith(categoriesEnabled: nextCats),
                    );
                  }
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading configuration: $err')),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showPriorityFilterSheet(NotificationController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text('Filter by Priority Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ListTile(
              title: const Text('All Priorities'),
              onTap: () {
                controller.updatePriorityFilter(null);
                Navigator.pop(context);
              },
            ),
            ...NotificationPriority.values.map(
              (p) => ListTile(
                title: Text(p.name.toUpperCase()),
                leading: Icon(p.icon, color: p.color),
                onTap: () {
                  controller.updatePriorityFilter(p);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryFilterSheet(NotificationController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text('Filter by Alert Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ListTile(
              title: const Text('All Categories'),
              onTap: () {
                controller.updateCategoryFilter(null);
                Navigator.pop(context);
              },
            ),
            ...NotificationCategory.values.map(
              (c) => ListTile(
                title: Text(c.displayName),
                onTap: () {
                  controller.updateCategoryFilter(c);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearHistory(BuildContext context, NotificationController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Notification Log History?'),
          content: const Text('This will permanently delete all notifications from SQLite history database. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                controller.deleteAllNotifications();
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  /// Triggers a mock test notification representing a backup failure
  Future<void> _triggerTestNotification() async {
    await ref.read(notificationServiceProvider).triggerNotification(
      priority: NotificationPriority.critical,
      category: NotificationCategory.backupFailed,
      message: 'CRITICAL: Backup worker job #105 failed. Hard drive destination disk is full.',
      status: 'failed',
      worker: 'Worker-07',
      relatedBackupId: 12,
      destination: '/volumes/backup_drive_x',
    );
  }
}
