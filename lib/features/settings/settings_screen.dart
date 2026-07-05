import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'settings_controller.dart';
import 'settings_models.dart';
import 'settings_provider.dart';
import 'settings_widgets.dart';
import '../../core/services/logging_service.dart';
import '../background/background_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'title': 'General', 'icon': Icons.settings_rounded},
    {'title': 'Startup', 'icon': Icons.power_settings_new_rounded},
    {'title': 'Backup Defaults', 'icon': Icons.backup_rounded},
    {'title': 'Monitoring', 'icon': Icons.monitor_heart_rounded},
    {'title': 'Restore Defaults', 'icon': Icons.restore_rounded},
    {'title': 'Notifications', 'icon': Icons.notifications_active_rounded},
    {'title': 'Logging', 'icon': Icons.notes_rounded},
    {'title': 'Performance', 'icon': Icons.speed_rounded},
    {'title': 'Security', 'icon': Icons.security_rounded},
    {'title': 'Storage', 'icon': Icons.storage_rounded},
    {'title': 'Import / Export', 'icon': Icons.swap_vertical_circle_rounded},
    {'title': 'About', 'icon': Icons.info_outline_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_page_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () => _confirmReset(context, notifier),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SettingsSearchField(
            query: _searchQuery,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          Expanded(
            child: isLargeScreen
                ? _buildDesktopLayout(settings, notifier, theme)
                : _buildMobileLayout(settings, notifier, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    SettingsState settings,
    SettingsController notifier,
    ThemeData theme,
  ) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResultsView(settings, notifier, theme);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Navigation
        SizedBox(
          width: 260,
          child: ListView.builder(
            itemCount: _categories.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategoryIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                  selectedColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Icon(cat['icon']),
                  title: Text(
                    cat['title'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // Active Category Detail View
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: _buildCategoryView(_selectedCategoryIndex, settings, notifier, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    SettingsState settings,
    SettingsController notifier,
    ThemeData theme,
  ) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResultsView(settings, notifier, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryView(index, settings, notifier, theme);
      },
    );
  }

  Widget _buildCategoryView(
    int index,
    SettingsState settings,
    SettingsController notifier,
    ThemeData theme,
  ) {
    switch (index) {
      case 0:
        return _buildGeneralCategory(settings, notifier, theme);
      case 1:
        return _buildStartupCategory(settings, notifier, theme);
      case 2:
        return _buildBackupCategory(settings, notifier, theme);
      case 3:
        return _buildMonitoringCategory(settings, notifier, theme);
      case 4:
        return _buildRestoreCategory(settings, notifier, theme);
      case 5:
        return _buildNotificationsCategory(settings, notifier, theme);
      case 6:
        return _buildLoggingCategory(settings, notifier, theme);
      case 7:
        return _buildPerformanceCategory(settings, notifier, theme);
      case 8:
        return _buildSecurityCategory(settings, notifier, theme);
      case 9:
        return _buildStorageCategory(settings, notifier, theme);
      case 10:
        return _buildImportExportCategory(settings, notifier, theme);
      case 11:
      default:
        return _buildAboutCategory(settings, theme);
    }
  }

  Widget _buildSearchResultsView(
    SettingsState settings,
    SettingsController notifier,
    ThemeData theme,
  ) {
    final query = _searchQuery.toLowerCase();
    final List<Widget> matchingCategories = [];

    // Filter categories that contain fields matching search query
    // 0. General
    if (_matchesGeneral(settings, query)) {
      matchingCategories.add(_buildGeneralCategory(settings, notifier, theme));
    }
    // 1. Startup
    if (_matchesStartup(settings, query)) {
      matchingCategories.add(_buildStartupCategory(settings, notifier, theme));
    }
    // 2. Backup
    if (_matchesBackup(settings, query)) {
      matchingCategories.add(_buildBackupCategory(settings, notifier, theme));
    }
    // 3. Monitoring
    if (_matchesMonitoring(settings, query)) {
      matchingCategories.add(_buildMonitoringCategory(settings, notifier, theme));
    }
    // 4. Restore
    if (_matchesRestore(settings, query)) {
      matchingCategories.add(_buildRestoreCategory(settings, notifier, theme));
    }
    // 5. Notifications
    if (_matchesNotifications(settings, query)) {
      matchingCategories.add(_buildNotificationsCategory(settings, notifier, theme));
    }
    // 6. Logging
    if (_matchesLogging(settings, query)) {
      matchingCategories.add(_buildLoggingCategory(settings, notifier, theme));
    }
    // 7. Performance
    if (_matchesPerformance(settings, query)) {
      matchingCategories.add(_buildPerformanceCategory(settings, notifier, theme));
    }
    // 8. Security
    if (_matchesSecurity(settings, query)) {
      matchingCategories.add(_buildSecurityCategory(settings, notifier, theme));
    }
    // 9. Storage
    if (_matchesStorage(settings, query)) {
      matchingCategories.add(_buildStorageCategory(settings, notifier, theme));
    }

    if (matchingCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No settings match "$_searchQuery"', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: matchingCategories,
    );
  }

  // --- Search matches helpers ---
  bool _matchesGeneral(SettingsState s, String q) {
    return 'general theme dark light system language language code autosave save update check'.contains(q) ||
        s.general.theme.toLowerCase().contains(q) ||
        s.general.language.toLowerCase().contains(q);
  }

  bool _matchesStartup(SettingsState s, String q) {
    return 'startup windows launch minimize tray background engine pending job resume session'.contains(q);
  }

  bool _matchesBackup(SettingsState s, String q) {
    return 'backup destination path versioning max versions sha256 sha-256 verify duplicate overwrite format date naming'.contains(q) ||
        s.backup.defaultBackupDestination.toLowerCase().contains(q);
  }

  bool _matchesMonitoring(SettingsState s, String q) {
    return 'monitoring realtime watch scan delay queue threads workers background'.contains(q);
  }

  bool _matchesRestore(SettingsState s, String q) {
    return 'restore folder path conflicts original location verify history'.contains(q) ||
        s.restore.defaultRestoreFolder.toLowerCase().contains(q);
  }

  bool _matchesNotifications(SettingsState s, String q) {
    return 'notifications alerts alerts complete fail low storage warning offline background error'.contains(q);
  }

  bool _matchesLogging(SettingsState s, String q) {
    return 'logging logs debug log size retention export clear'.contains(q);
  }

  bool _matchesPerformance(SettingsState s, String q) {
    return 'performance cpu limit ram limit thread limit parallel jobs buffer size large file power saving'.contains(q);
  }

  bool _matchesSecurity(SettingsState s, String q) {
    return 'security integrity encryption delete confirmation protect lock database'.contains(q);
  }

  bool _matchesStorage(SettingsState s, String q) {
    return 'storage space capacity free space limit warning pause full'.contains(q);
  }

  // --- Category Builders ---
  Widget _buildGeneralCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'General Settings',
      icon: Icons.settings_rounded,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('Application Name'),
          trailing: Text(s.general.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('Application Version'),
          trailing: Text(s.general.appVersion, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        SettingsDropdownTile<String>(
          title: 'Theme Mode',
          subtitle: 'Choose between light, dark or system themes',
          icon: Icons.brightness_medium_rounded,
          value: s.general.theme,
          items: const [
            DropdownMenuItem(value: 'system', child: Text('System Default')),
            DropdownMenuItem(value: 'light', child: Text('Light Mode')),
            DropdownMenuItem(value: 'dark', child: Text('Dark Mode')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updateGeneralSettings(s.general.copyWith(theme: val)));
            }
          },
        ),
        SettingsDropdownTile<String>(
          title: 'Language',
          subtitle: 'Select application display language',
          icon: Icons.language_rounded,
          value: s.general.language,
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English (US)')),
            DropdownMenuItem(value: 'es', child: Text('Español')),
            DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            DropdownMenuItem(value: 'fr', child: Text('Français')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updateGeneralSettings(s.general.copyWith(language: val)));
            }
          },
        ),
        SettingsSwitchTile(
          title: 'Auto Save Settings',
          subtitle: 'Automatically commit changes to database immediately',
          icon: Icons.save_rounded,
          value: s.general.autoSaveSettings,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateGeneralSettings(s.general.copyWith(autoSaveSettings: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Check for Updates',
          subtitle: 'Notify when new app updates are available (future-ready)',
          icon: Icons.update_rounded,
          value: s.general.checkForUpdates,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateGeneralSettings(s.general.copyWith(checkForUpdates: val)));
          },
        ),
      ],
    );
  }

  Widget _buildStartupCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    final startupState = ref.watch(startupStateProvider);
    final backgroundState = ref.watch(backgroundStateProvider);
    final services = ref.watch(runningServicesStateProvider);
    final bgController = ref.read(backgroundModuleProvider.notifier);

    // Calculate if all monitored services are running
    final allServicesRunning = services.backupEngine &&
        services.restoreEngine &&
        services.folderWatcher &&
        services.notificationService &&
        services.database &&
        services.queue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Background Health & Status Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
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
                          Icon(
                            allServicesRunning ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                            color: allServicesRunning ? Colors.green : Colors.amber,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            allServicesRunning ? 'All background services healthy' : 'Some background services inactive',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: backgroundState.isRunning
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          backgroundState.isRunning ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: backgroundState.isRunning ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Monitored Services:',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Grid of Monitored Services
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildServiceBadge('Backup Engine', services.backupEngine, theme),
                      _buildServiceBadge('Restore Engine', services.restoreEngine, theme),
                      _buildServiceBadge('Folder Watcher', services.folderWatcher, theme),
                      _buildServiceBadge('Notification Svc', services.notificationService, theme),
                      _buildServiceBadge('Database', services.database, theme),
                      _buildServiceBadge('Job Queue', services.queue, theme),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Performance Metrics:',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem(
                        Icons.developer_board_rounded,
                        'CPU Usage',
                        '${backgroundState.cpuUsagePercent.toStringAsFixed(1)}%',
                        theme,
                      ),
                      _buildMetricItem(
                        Icons.memory_rounded,
                        'RAM Usage',
                        '${backgroundState.ramUsageMb.toStringAsFixed(1)} MB',
                        theme,
                      ),
                      _buildMetricItem(
                        backgroundState.isRunningOnBattery ? Icons.battery_alert_rounded : Icons.power_rounded,
                        'Power Source',
                        backgroundState.isRunningOnBattery ? 'Battery' : 'AC Power',
                        theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (backgroundState.isRunning) {
                              bgController.stopService();
                            } else {
                              bgController.startService();
                            }
                          },
                          icon: Icon(backgroundState.isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
                          label: Text(backgroundState.isRunning ? 'Stop Monitor' : 'Start Monitor'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: backgroundState.isRunning ? theme.colorScheme.error : theme.colorScheme.primary,
                            side: BorderSide(
                              color: backgroundState.isRunning ? theme.colorScheme.error : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: backgroundState.isRunning
                              ? () {
                                  if (backgroundState.isPaused) {
                                    bgController.resumeBackup();
                                  } else {
                                    bgController.pauseBackup();
                                  }
                                }
                              : null,
                          icon: Icon(backgroundState.isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline),
                          label: Text(backgroundState.isPaused ? 'Resume Queue' : 'Pause Queue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 2. Windows Startup & Tray Settings Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.power_settings_new_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Startup & System Tray Settings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Start with Windows'),
                    subtitle: const Text('Automatically launch BackupVault when logging into Windows'),
                    value: startupState.isEnabled,
                    onChanged: (val) {
                      bgController.updateStartupSettings(
                        enabled: val,
                        startMinimized: startupState.startMinimized,
                        startInSystemTray: startupState.startInSystemTray,
                        restorePreviousSession: startupState.restorePreviousSession,
                        startupDelaySeconds: startupState.startupDelaySeconds,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Start Minimized'),
                    subtitle: const Text('Launch application minimized on startup'),
                    value: startupState.startMinimized,
                    onChanged: (val) {
                      bgController.updateStartupSettings(
                        enabled: startupState.isEnabled,
                        startMinimized: val,
                        startInSystemTray: startupState.startInSystemTray,
                        restorePreviousSession: startupState.restorePreviousSession,
                        startupDelaySeconds: startupState.startupDelaySeconds,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Start directly to System Tray'),
                    subtitle: const Text('Hide main window and run only in the tray on boot'),
                    value: startupState.startInSystemTray,
                    onChanged: (val) {
                      bgController.updateStartupSettings(
                        enabled: startupState.isEnabled,
                        startMinimized: startupState.startMinimized,
                        startInSystemTray: val,
                        restorePreviousSession: startupState.restorePreviousSession,
                        startupDelaySeconds: startupState.startupDelaySeconds,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Restore Previous Session'),
                    subtitle: const Text('Automatically scan, reconnect, and run pending backup queues on launch'),
                    value: startupState.restorePreviousSession,
                    onChanged: (val) {
                      bgController.updateStartupSettings(
                        enabled: startupState.isEnabled,
                        startMinimized: startupState.startMinimized,
                        startInSystemTray: startupState.startInSystemTray,
                        restorePreviousSession: val,
                        startupDelaySeconds: startupState.startupDelaySeconds,
                      );
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Startup Delay Option',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              startupState.startupDelaySeconds == 0
                                  ? 'No Delay'
                                  : '${startupState.startupDelaySeconds} seconds',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Delays initialization of watchers and disk activities to prevent system lag on boot.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Slider(
                          value: startupState.startupDelaySeconds.toDouble(),
                          min: 0,
                          max: 60,
                          divisions: 12,
                          label: '${startupState.startupDelaySeconds}s',
                          onChanged: (val) {
                            bgController.updateStartupSettings(
                              enabled: startupState.isEnabled,
                              startMinimized: startupState.startMinimized,
                              startInSystemTray: startupState.startInSystemTray,
                              restorePreviousSession: startupState.restorePreviousSession,
                              startupDelaySeconds: val.toInt(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBadge(String name, bool isActive, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isActive ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 24),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }


  Widget _buildBackupCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Backup Defaults',
      icon: Icons.backup_rounded,
      children: [
        SettingsPathPickerTile(
          title: 'Default Backup Destination',
          subtitle: 'Primary folder to store backups if not specified',
          icon: Icons.folder_shared_rounded,
          path: s.backup.defaultBackupDestination,
          dialogTitle: 'Select Default Destination',
          onSelected: (val) {
            _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(defaultBackupDestination: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Enable Versioning',
          subtitle: 'Maintain historical copies of modified files',
          icon: Icons.history_toggle_off_rounded,
          value: s.backup.enableVersioning,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(enableVersioning: val)));
          },
        ),
        if (s.backup.enableVersioning) ...[
          SettingsTextFieldTile(
            title: 'Maximum Versions',
            subtitle: 'Limit amount of historical versions per file',
            icon: Icons.format_list_numbered_rounded,
            value: s.backup.maxVersions.toString(),
            isNumeric: true,
            onSubmitted: (val) {
              final parsed = int.tryParse(val) ?? 5;
              _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(maxVersions: parsed)));
            },
          ),
          SettingsSwitchTile(
            title: 'Keep Forever',
            subtitle: 'Retain historical versions indefinitely',
            icon: Icons.all_inclusive_rounded,
            value: s.backup.keepForever,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(keepForever: val)));
            },
          ),
        ],
        SettingsSwitchTile(
          title: 'Verify SHA-256 Hash',
          subtitle: 'Calculate integrity signatures for backed up files',
          icon: Icons.fingerprint_rounded,
          value: s.backup.verifySha256,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(verifySha256: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Retry Failed Backups',
          subtitle: 'Attempt re-running a job if failure occurs',
          icon: Icons.refresh_rounded,
          value: s.backup.retryFailedBackup,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(retryFailedBackup: val)));
          },
        ),
        if (s.backup.retryFailedBackup)
          SettingsTextFieldTile(
            title: 'Maximum Retry Count',
            subtitle: 'Number of automatic retries on failure',
            icon: Icons.replay_circle_filled_rounded,
            value: s.backup.maxRetryCount.toString(),
            isNumeric: true,
            onSubmitted: (val) {
              final parsed = int.tryParse(val) ?? 3;
              _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(maxRetryCount: parsed)));
            },
          ),
        SettingsDropdownTile<String>(
          title: 'Overwrite Policy',
          subtitle: 'Rule for resolving existing target files',
          icon: Icons.file_copy_rounded,
          value: s.backup.overwritePolicy,
          items: const [
            DropdownMenuItem(value: 'overwrite', child: Text('Overwrite Existing')),
            DropdownMenuItem(value: 'skip', child: Text('Skip/Ignore')),
            DropdownMenuItem(value: 'rename', child: Text('Rename New File')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(overwritePolicy: val)));
            }
          },
        ),
        SettingsDropdownTile<String>(
          title: 'Duplicate Policy',
          subtitle: 'Rule when duplicate hash file is found',
          icon: Icons.control_point_duplicate_rounded,
          value: s.backup.duplicatePolicy,
          items: const [
            DropdownMenuItem(value: 'keep_both', child: Text('Keep Both')),
            DropdownMenuItem(value: 'replace', child: Text('Replace Old')),
            DropdownMenuItem(value: 'ask', child: Text('Ask User')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(duplicatePolicy: val)));
            }
          },
        ),
        SettingsDropdownTile<String>(
          title: 'Date Folder Format',
          subtitle: 'Directory structure layout date format',
          icon: Icons.calendar_today_rounded,
          value: s.backup.dateFolderFormat,
          items: const [
            DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('YYYY-MM-DD (e.g. 2026-07-04)')),
            DropdownMenuItem(value: 'yyyyMMdd', child: Text('YYYYMMDD (e.g. 20260704)')),
            DropdownMenuItem(value: 'dd-MM-yyyy', child: Text('DD-MM-YYYY (e.g. 04-07-2026)')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(dateFolderFormat: val)));
            }
          },
        ),
        SettingsDropdownTile<String>(
          title: 'Backup Naming Format',
          subtitle: 'Rule for generating output backup file names',
          icon: Icons.title_rounded,
          value: s.backup.backupNamingFormat,
          items: const [
            DropdownMenuItem(value: 'original_date', child: Text('Filename_Date.ext')),
            DropdownMenuItem(value: 'date_original', child: Text('Date_Filename.ext')),
            DropdownMenuItem(value: 'original', child: Text('Filename.ext')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(backupNamingFormat: val)));
            }
          },
        ),
      ],
    );
  }

  Widget _buildMonitoringCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Monitoring Settings',
      icon: Icons.monitor_heart_rounded,
      children: [
        SettingsSwitchTile(
          title: 'Enable Real-time Monitoring',
          subtitle: 'Scan and backup modified files immediately',
          icon: Icons.wifi_tethering_rounded,
          value: s.monitoring.enableRealtimeMonitoring,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateMonitoringSettings(s.monitoring.copyWith(enableRealtimeMonitoring: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Pause Monitoring',
          subtitle: 'Temporarily stop all filesystem watches',
          icon: Icons.pause_circle_rounded,
          value: s.monitoring.pauseMonitoring,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateMonitoringSettings(s.monitoring.copyWith(pauseMonitoring: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Background Monitoring',
          subtitle: 'Keep filesystem watchers active when app is closed',
          icon: Icons.settings_system_daydream_rounded,
          value: s.monitoring.backgroundMonitoring,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateMonitoringSettings(s.monitoring.copyWith(backgroundMonitoring: val)));
          },
        ),
        SettingsSliderTile(
          title: 'Maximum Worker Threads',
          subtitle: 'File system scanner threads allocation',
          icon: Icons.grid_view_rounded,
          value: s.monitoring.maxWorkerThreads.toDouble(),
          min: 1,
          max: 16,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateMonitoringSettings(s.monitoring.copyWith(maxWorkerThreads: val.toInt())));
          },
        ),
        SettingsTextFieldTile(
          title: 'Scan Delay',
          subtitle: 'Pause interval between file scans (ms)',
          icon: Icons.timer_3_rounded,
          value: s.monitoring.scanDelayMs.toString(),
          isNumeric: true,
          onSubmitted: (val) {
            final parsed = int.tryParse(val) ?? 100;
            _safeAction(context, () => notifier.updateMonitoringSettings(s.monitoring.copyWith(scanDelayMs: parsed)));
          },
        ),
        SettingsTextFieldTile(
          title: 'Event Queue Size',
          subtitle: 'Filesystem event buffer queue size limit',
          icon: Icons.playlist_play_rounded,
          value: s.monitoring.eventQueueSize.toString(),
          isNumeric: true,
          onSubmitted: (val) {
            final parsed = int.tryParse(val) ?? 1000;
            _safeAction(context, () => notifier.updateMonitoringSettings(s.monitoring.copyWith(eventQueueSize: parsed)));
          },
        ),
        SettingsTextFieldTile(
          title: 'Folder Scan Interval',
          subtitle: 'Full scan interval for folder health verification (seconds)',
          icon: Icons.loop_rounded,
          value: s.monitoring.folderScanIntervalSecs.toString(),
          isNumeric: true,
          onSubmitted: (val) {
            final parsed = int.tryParse(val) ?? 300;
            _safeAction(context, () => notifier.updateMonitoringSettings(s.monitoring.copyWith(folderScanIntervalSecs: parsed)));
          },
        ),
      ],
    );
  }

  Widget _buildRestoreCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Restore Defaults',
      icon: Icons.restore_rounded,
      children: [
        SettingsPathPickerTile(
          title: 'Default Restore Folder',
          subtitle: 'Target directory for downloaded files',
          icon: Icons.folder_zip_rounded,
          path: s.restore.defaultRestoreFolder,
          dialogTitle: 'Select Restore Folder',
          onSelected: (val) {
            _safeAction(context, () => notifier.updateRestoreSettings(s.restore.copyWith(defaultRestoreFolder: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Restore to Original Location',
          subtitle: 'Attempt placing file back in its source directory',
          icon: Icons.my_location_rounded,
          value: s.restore.restoreToOriginalLocation,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateRestoreSettings(s.restore.copyWith(restoreToOriginalLocation: val)));
          },
        ),
        SettingsDropdownTile<String>(
          title: 'Conflict Policy',
          subtitle: 'Rule for resolving pre-existing destination files',
          icon: Icons.warning_amber_rounded,
          value: s.restore.conflictPolicy,
          items: const [
            DropdownMenuItem(value: 'overwrite', child: Text('Overwrite Target')),
            DropdownMenuItem(value: 'skip', child: Text('Skip Restore')),
            DropdownMenuItem(value: 'rename', child: Text('Rename Restored File')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updateRestoreSettings(s.restore.copyWith(conflictPolicy: val)));
            }
          },
        ),
        SettingsSwitchTile(
          title: 'Verify Restored Files',
          subtitle: 'Perform SHA-256 hash comparison after restore',
          icon: Icons.check_circle_outline_rounded,
          value: s.restore.verifyRestoredFiles,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateRestoreSettings(s.restore.copyWith(verifyRestoredFiles: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Maintain Restore History',
          subtitle: 'Log all file restoration sessions in database',
          icon: Icons.history_rounded,
          value: s.restore.restoreHistory,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateRestoreSettings(s.restore.copyWith(restoreHistory: val)));
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Notifications Settings',
      icon: Icons.notifications_active_rounded,
      children: [
        SettingsSwitchTile(
          title: 'Enable Notifications',
          subtitle: 'Show system tray and overlay popups',
          icon: Icons.notifications_rounded,
          value: s.notifications.enableNotifications,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(enableNotifications: val)));
          },
        ),
        if (s.notifications.enableNotifications) ...[
          SettingsSwitchTile(
            title: 'Notify on Backup Complete',
            icon: Icons.check_circle_rounded,
            value: s.notifications.notifyBackupComplete,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(notifyBackupComplete: val)));
            },
          ),
          SettingsSwitchTile(
            title: 'Notify on Backup Failed',
            icon: Icons.error_rounded,
            value: s.notifications.notifyBackupFailed,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(notifyBackupFailed: val)));
            },
          ),
          SettingsSwitchTile(
            title: 'Notify on Restore Complete',
            icon: Icons.check_rounded,
            value: s.notifications.notifyRestoreComplete,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(notifyRestoreComplete: val)));
            },
          ),
          SettingsSwitchTile(
            title: 'Notify on Low Storage',
            icon: Icons.storage_rounded,
            value: s.notifications.notifyLowStorage,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(notifyLowStorage: val)));
            },
          ),
          SettingsSwitchTile(
            title: 'Notify on Folder Offline',
            icon: Icons.folder_off_rounded,
            value: s.notifications.notifyFolderOffline,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(notifyFolderOffline: val)));
            },
          ),
          SettingsSwitchTile(
            title: 'Notify on Background Errors',
            icon: Icons.bug_report_rounded,
            value: s.notifications.notifyBackgroundErrors,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(notifyBackgroundErrors: val)));
            },
          ),
          SettingsSwitchTile(
            title: 'Notify on Warning Messages',
            icon: Icons.warning_amber_rounded,
            value: s.notifications.notifyWarningMessages,
            onChanged: (val) {
              _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(notifyWarningMessages: val)));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLoggingCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Logging Settings',
      icon: Icons.notes_rounded,
      children: [
        SettingsSwitchTile(
          title: 'Enable Logging',
          subtitle: 'Log application activities to SQLite',
          icon: Icons.history_edu_rounded,
          value: s.logging.enableLogging,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateLoggingSettings(s.logging.copyWith(enableLogging: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Debug Logging',
          subtitle: 'Capture full debug trace details (warning: increases DB size)',
          icon: Icons.bug_report_rounded,
          value: s.logging.debugLogging,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateLoggingSettings(s.logging.copyWith(debugLogging: val)));
          },
        ),
        SettingsTextFieldTile(
          title: 'Maximum Log Size',
          subtitle: 'Rotate and trim logs after limit (MB)',
          icon: Icons.photo_size_select_small_rounded,
          value: s.logging.maxLogSizeMb.toString(),
          isNumeric: true,
          onSubmitted: (val) {
            final parsed = int.tryParse(val) ?? 10;
            _safeAction(context, () => notifier.updateLoggingSettings(s.logging.copyWith(maxLogSizeMb: parsed)));
          },
        ),
        SettingsTextFieldTile(
          title: 'Log Retention Interval',
          subtitle: 'Days to keep historical logs before clearing',
          icon: Icons.date_range_rounded,
          value: s.logging.logRetentionDays.toString(),
          isNumeric: true,
          onSubmitted: (val) {
            final parsed = int.tryParse(val) ?? 30;
            _safeAction(context, () => notifier.updateLoggingSettings(s.logging.copyWith(logRetentionDays: parsed)));
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _handleExportLogs(context),
              icon: const Icon(Icons.file_upload_rounded),
              label: const Text('Export Logs'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _handleClearLogs(context),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Clear Logs'),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Performance Settings',
      icon: Icons.speed_rounded,
      children: [
        SettingsSliderTile(
          title: 'CPU Limit',
          subtitle: 'Throttling percentage limit of backup engine',
          icon: Icons.developer_board_rounded,
          value: s.performance.cpuLimitPercent.toDouble(),
          min: 10,
          max: 100,
          formatLabel: (val) => '${val.toInt()}%',
          onChanged: (val) {
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(cpuLimitPercent: val.toInt())));
          },
        ),
        SettingsTextFieldTile(
          title: 'RAM Limit',
          subtitle: 'Maximum heap size allocated to copying engine (MB)',
          icon: Icons.memory_rounded,
          value: s.performance.ramLimitMb.toString(),
          isNumeric: true,
          onSubmitted: (val) {
            final parsed = int.tryParse(val) ?? 512;
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(ramLimitMb: parsed)));
          },
        ),
        SettingsSliderTile(
          title: 'Thread Limit',
          subtitle: 'Concurrent CPU worker threads allocation',
          icon: Icons.linear_scale_rounded,
          value: s.performance.threadLimit.toDouble(),
          min: 1,
          max: 16,
          onChanged: (val) {
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(threadLimit: val.toInt())));
          },
        ),
        SettingsSliderTile(
          title: 'Maximum Parallel Jobs',
          subtitle: 'Number of folders backed up simultaneously',
          icon: Icons.splitscreen_rounded,
          value: s.performance.maxParallelJobs.toDouble(),
          min: 1,
          max: 8,
          onChanged: (val) {
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(maxParallelJobs: val.toInt())));
          },
        ),
        SettingsDropdownTile<int>(
          title: 'File Buffer Size',
          subtitle: 'Read/write stream chunk sizes',
          icon: Icons.dns_rounded,
          value: s.performance.fileBufferSizeKb,
          items: const [
            DropdownMenuItem(value: 64, child: Text('64 KB (Default)')),
            DropdownMenuItem(value: 128, child: Text('128 KB')),
            DropdownMenuItem(value: 256, child: Text('256 KB')),
            DropdownMenuItem(value: 512, child: Text('512 KB')),
            DropdownMenuItem(value: 1024, child: Text('1024 KB')),
          ],
          onChanged: (val) {
            if (val != null) {
              _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(fileBufferSizeKb: val)));
            }
          },
        ),
        SettingsSwitchTile(
          title: 'Large File Mode',
          subtitle: 'Use unbuffered direct disk I/O streams for gigabyte files',
          icon: Icons.insert_drive_file_rounded,
          value: s.performance.largeFileMode,
          onChanged: (val) {
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(largeFileMode: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Power Saving Mode',
          subtitle: 'Suspend jobs and background monitoring on battery power',
          icon: Icons.battery_saver_rounded,
          value: s.performance.powerSavingMode,
          onChanged: (val) {
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(powerSavingMode: val)));
          },
        ),
      ],
    );
  }

  Widget _buildSecurityCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Security Settings',
      icon: Icons.security_rounded,
      children: [
        SettingsSwitchTile(
          title: 'Verify File Integrity',
          subtitle: 'Assert checksum validity during scheduled intervals',
          icon: Icons.verified_user_rounded,
          value: s.security.verifyIntegrity,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateSecuritySettings(s.security.copyWith(verifyIntegrity: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Enable Future Encryption Support',
          subtitle: 'Prepare local AES-256 database key bindings (future-ready)',
          icon: Icons.enhanced_encryption_rounded,
          value: s.security.enableFutureEncryption,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateSecuritySettings(s.security.copyWith(enableFutureEncryption: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Require Confirmation Before Delete',
          subtitle: 'Ask user consent before executing destructive deletion rules',
          icon: Icons.question_mark_rounded,
          value: s.security.requireConfirmationBeforeDelete,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateSecuritySettings(s.security.copyWith(requireConfirmationBeforeDelete: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Protect Backup Database',
          subtitle: 'Restricts external writing to DB file',
          icon: Icons.lock_outline_rounded,
          value: s.security.protectBackupDatabase,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateSecuritySettings(s.security.copyWith(protectBackupDatabase: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Lock Settings Access',
          subtitle: 'Require admin code to unlock dashboard changes (future-ready)',
          icon: Icons.app_blocking_rounded,
          value: s.security.lockSettings,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateSecuritySettings(s.security.copyWith(lockSettings: val)));
          },
        ),
      ],
    );
  }

  Widget _buildStorageCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Storage Settings',
      icon: Icons.storage_rounded,
      children: [
        SettingsSwitchTile(
          title: 'Show Available Space',
          subtitle: 'Display metrics for source/destination disk capacity',
          icon: Icons.pie_chart_rounded,
          value: s.storage.showAvailableSpace,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateStorageSettings(s.storage.copyWith(showAvailableSpace: val)));
          },
        ),
        SettingsSwitchTile(
          title: 'Low Storage Warning',
          subtitle: 'Alert when remaining disk space is lower than threshold',
          icon: Icons.notification_important_rounded,
          value: s.storage.lowStorageWarning,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateStorageSettings(s.storage.copyWith(lowStorageWarning: val)));
          },
        ),
        if (s.storage.lowStorageWarning)
          SettingsTextFieldTile(
            title: 'Minimum Free Space',
            subtitle: 'Trigger boundary limit size (GB)',
            icon: Icons.space_bar_rounded,
            value: s.storage.minimumFreeSpaceGb.toString(),
            isNumeric: true,
            onSubmitted: (val) {
              final parsed = int.tryParse(val) ?? 5;
              _safeAction(context, () => notifier.updateStorageSettings(s.storage.copyWith(minimumFreeSpaceGb: parsed)));
            },
          ),
        SettingsSwitchTile(
          title: 'Automatically Pause When Full',
          subtitle: 'Pause monitor queues if free disk space is depleted',
          icon: Icons.pause_circle_filled_rounded,
          value: s.storage.autoPauseWhenFull,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateStorageSettings(s.storage.copyWith(autoPauseWhenFull: val)));
          },
        ),
      ],
    );
  }

  Widget _buildImportExportCategory(
    SettingsState s,
    SettingsController notifier,
    ThemeData theme,
  ) {
    return SettingsCategoryCard(
      title: 'Configuration Import / Export',
      icon: Icons.swap_vertical_circle_rounded,
      children: [
        const SizedBox(height: 8),
        Text(
          'Manage application configurations. Export/Import settings JSON, or backup/restore the SQLite configuration database file.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        const Text('ADVANCED MIGRATION & WIZARDS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome_motion_rounded),
            label: const Text('Open Migration & Backup Wizard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
            onPressed: () {
              context.push('/configuration');
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text('JSON CONFIGURATION (Settings)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_download_rounded),
                label: const Text('Export JSON'),
                onPressed: () => _showPathDialog(
                  context,
                  title: 'Export Settings JSON',
                  hint: Platform.isWindows ? 'C:\\Backups\\settings.json' : '/home/user/settings.json',
                  actionText: 'Export',
                  onConfirm: (path) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.exportSettings(path);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Settings exported successfully to $path')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_upload_rounded),
                label: const Text('Import JSON'),
                onPressed: () => _showPathDialog(
                  context,
                  title: 'Import Settings JSON',
                  hint: Platform.isWindows ? 'C:\\Backups\\settings.json' : '/home/user/settings.json',
                  actionText: 'Import',
                  onConfirm: (path) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.importSettings(path);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Settings imported successfully!')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('SQLITE DATABASE (Configuration)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.backup_table_rounded),
                label: const Text('Backup DB'),
                onPressed: () => _showPathDialog(
                  context,
                  title: 'Backup Settings DB',
                  hint: Platform.isWindows ? 'C:\\Backups\\settings.db' : '/home/user/settings.db',
                  actionText: 'Backup',
                  onConfirm: (path) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.backupConfig(path);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Database backed up to $path')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: const Text('Restore DB'),
                onPressed: () => _showPathDialog(
                  context,
                  title: 'Restore Settings DB',
                  hint: Platform.isWindows ? 'C:\\Backups\\settings.db' : '/home/user/settings.db',
                  actionText: 'Restore',
                  onConfirm: (path) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.restoreConfig(path);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Database restored successfully!')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAboutCategory(SettingsState s, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'About BackupVault',
      icon: Icons.info_outline_rounded,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Icon(Icons.shield_rounded, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'BackupVault',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Version ${s.general.appVersion}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Developer Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text('Lead Architect & Developer: ManiKaran'),
        const SizedBox(height: 16),
        const Text(
          'License & Open Source Notice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Licensed under the MIT License.\nPermissions are granted free of charge to any person obtaining a copy of this software and associated documentation files to deal in the Software without restriction.',
        ),
        const SizedBox(height: 16),
        const Text(
          'GitHub Repository (future)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const SelectionArea(
          child: Text(
            'https://github.com/manikaran/backupvault',
            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Third-Party Licenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '- Drift Database library (Apache 2.0)\n- Flutter Riverpod framework (MIT)\n- SQLite 3 database engine (Public Domain)\n- Path provider & encryption libraries (BSD)',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Actions Helpers ---
  void _confirmReset(BuildContext context, SettingsController notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text('Are you sure you want to restore all settings to default values? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _safeAction(context, () => notifier.resetToDefault());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Reset Defaults'),
            ),
          ],
        );
      },
    );
  }

  void _showPathDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required String actionText,
    required Future<void> Function(String) onConfirm,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              labelText: 'Target File Path',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final path = controller.text.trim();
                if (path.isEmpty) return;
                Navigator.pop(context);
                _safeAction(context, () => onConfirm(path));
              },
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }

  void _safeAction(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Validation / Execution Error'),
              content: SingleChildScrollView(child: Text(e.toString().replaceAll('Exception: ', ''))),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _handleExportLogs(BuildContext context) {
    _showPathDialog(
      context,
      title: 'Export Application Logs',
      hint: Platform.isWindows ? 'C:\\Backups\\logs.txt' : '/home/user/logs.txt',
      actionText: 'Export',
      onConfirm: (path) async {
        final logsRepo = ref.read(settingsRepositoryProvider);
        // Copy logs
        final dbFile = File(logsRepo.dbPath!.replaceAll('settings.db', 'backup_vault.db'));
        if (await dbFile.exists()) {
          final target = File(path);
          final parent = target.parent;
          if (!await parent.exists()) {
            await parent.create(recursive: true);
          }
          // We can read logs from the database or copy the logs db. For simple text logs, let's copy log database/file or save simple text logs
          // Since they want 'Export Logs', let's write log content or copy logs db.
          // Let's read from logs database accessor and write it!
          final logs = await ref.read(loggingServiceProvider).getLogs(limit: 1000);
          final sb = StringBuffer();
          for (final log in logs) {
            sb.writeln('[${log.createdAt}] [${log.logType.toUpperCase()}] [${log.tag}] ${log.message}');
            if (log.stackTrace != null) {
              sb.writeln(log.stackTrace);
            }
          }
          await target.writeAsString(sb.toString());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logs exported successfully to $path')),
            );
          }
        } else {
          throw Exception('Logs file not found');
        }
      },
    );
  }

  void _handleClearLogs(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to delete all historical logs from the database?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(loggingServiceProvider).clearLogs();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared successfully')),
        );
      }
    }
  }
}
