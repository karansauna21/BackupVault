import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../settings_controller.dart';
import '../settings_models.dart';
import '../settings_provider.dart';
import '../settings_widgets.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/android_storage.dart';
import '../../folder_manager/widgets/android_folder_picker.dart';

// Android settings state model
class AndroidSettingsState {
  final bool batteryOptimizationDisabled;
  final bool backgroundBackup;
  final bool foregroundService;
  final bool autoBackupOnCharging;
  final bool backupOnWifiOnly;

  const AndroidSettingsState({
    this.batteryOptimizationDisabled = false,
    this.backgroundBackup = true,
    this.foregroundService = true,
    this.autoBackupOnCharging = false,
    this.backupOnWifiOnly = true,
  });

  AndroidSettingsState copyWith({
    bool? batteryOptimizationDisabled,
    bool? backgroundBackup,
    bool? foregroundService,
    bool? autoBackupOnCharging,
    bool? backupOnWifiOnly,
  }) {
    return AndroidSettingsState(
      batteryOptimizationDisabled: batteryOptimizationDisabled ?? this.batteryOptimizationDisabled,
      backgroundBackup: backgroundBackup ?? this.backgroundBackup,
      foregroundService: foregroundService ?? this.foregroundService,
      autoBackupOnCharging: autoBackupOnCharging ?? this.autoBackupOnCharging,
      backupOnWifiOnly: backupOnWifiOnly ?? this.backupOnWifiOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'batteryOptimizationDisabled': batteryOptimizationDisabled,
        'backgroundBackup': backgroundBackup,
        'foregroundService': foregroundService,
        'autoBackupOnCharging': autoBackupOnCharging,
        'backupOnWifiOnly': backupOnWifiOnly,
      };

  factory AndroidSettingsState.fromJson(Map<String, dynamic> json) {
    return AndroidSettingsState(
      batteryOptimizationDisabled: json['batteryOptimizationDisabled'] ?? false,
      backgroundBackup: json['backgroundBackup'] ?? true,
      foregroundService: json['foregroundService'] ?? true,
      autoBackupOnCharging: json['autoBackupOnCharging'] ?? false,
      backupOnWifiOnly: json['backupOnWifiOnly'] ?? true,
    );
  }
}

class AndroidSettingsNotifier extends Notifier<AndroidSettingsState> {
  @override
  AndroidSettingsState build() {
    try {
      final db = ref.read(settingsDatabaseProvider);
      final jsonStr = db.getValue('android_settings_state');
      if (jsonStr != null) {
        final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
        return AndroidSettingsState.fromJson(jsonMap);
      }
    } catch (_) {}
    return const AndroidSettingsState();
  }

  Future<void> updateSettings(AndroidSettingsState newState) async {
    state = newState;
    try {
      final db = ref.read(settingsDatabaseProvider);
      db.setValue('android_settings_state', json.encode(newState.toJson()));
      ref.read(loggingServiceProvider).info('Settings', 'Updated Android system settings');
    } catch (_) {}
  }
}

final androidSettingsProvider = NotifierProvider<AndroidSettingsNotifier, AndroidSettingsState>(() {
  return AndroidSettingsNotifier();
});

class AndroidSettingsPage extends ConsumerStatefulWidget {
  const AndroidSettingsPage({super.key});

  @override
  ConsumerState<AndroidSettingsPage> createState() => _AndroidSettingsPageState();
}

class _AndroidSettingsPageState extends ConsumerState<AndroidSettingsPage> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  bool _hasStoragePermission = false;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'General', 'icon': Icons.settings_rounded},
    {'title': 'Android Background', 'icon': Icons.android_rounded},
    {'title': 'Backup Defaults', 'icon': Icons.backup_rounded},
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
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPerm = await AndroidStorage.hasStoragePermission();
    if (mounted) {
      setState(() {
        _hasStoragePermission = hasPerm;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final androidSettings = ref.watch(androidSettingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final androidNotifier = ref.read(androidSettingsProvider.notifier);
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Android App Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_page_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () => _confirmReset(context, notifier, androidNotifier),
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
                ? _buildDesktopLayout(settings, androidSettings, notifier, androidNotifier, theme)
                : _buildMobileLayout(settings, androidSettings, notifier, androidNotifier, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    SettingsState settings,
    AndroidSettingsState androidSettings,
    SettingsController notifier,
    AndroidSettingsNotifier androidNotifier,
    ThemeData theme,
  ) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResultsView(settings, androidSettings, notifier, androidNotifier, theme);
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: _buildCategoryView(_selectedCategoryIndex, settings, androidSettings, notifier, androidNotifier, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    SettingsState settings,
    AndroidSettingsState androidSettings,
    SettingsController notifier,
    AndroidSettingsNotifier androidNotifier,
    ThemeData theme,
  ) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResultsView(settings, androidSettings, notifier, androidNotifier, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryView(index, settings, androidSettings, notifier, androidNotifier, theme);
      },
    );
  }

  Widget _buildCategoryView(
    int index,
    SettingsState settings,
    AndroidSettingsState androidSettings,
    SettingsController notifier,
    AndroidSettingsNotifier androidNotifier,
    ThemeData theme,
  ) {
    switch (index) {
      case 0:
        return _buildGeneralCategory(settings, notifier, theme);
      case 1:
        return _buildAndroidCategory(androidSettings, androidNotifier, theme);
      case 2:
        return _buildBackupCategory(settings, notifier, theme);
      case 3:
        return _buildRestoreCategory(settings, notifier, theme);
      case 4:
        return _buildNotificationsCategory(settings, notifier, theme);
      case 5:
        return _buildLoggingCategory(settings, notifier, theme);
      case 6:
        return _buildPerformanceCategory(settings, notifier, theme);
      case 7:
        return _buildSecurityCategory(settings, notifier, theme);
      case 8:
        return _buildStorageCategory(settings, notifier, theme);
      case 9:
        return _buildImportExportCategory(settings, notifier, theme);
      case 10:
      default:
        return _buildAboutCategory(settings, theme);
    }
  }

  Widget _buildSearchResultsView(
    SettingsState settings,
    AndroidSettingsState androidSettings,
    SettingsController notifier,
    AndroidSettingsNotifier androidNotifier,
    ThemeData theme,
  ) {
    final query = _searchQuery.toLowerCase();
    final List<Widget> matchingCategories = [];

    if (_matchesGeneral(settings, query)) {
      matchingCategories.add(_buildGeneralCategory(settings, notifier, theme));
    }
    if (_matchesAndroid(androidSettings, query)) {
      matchingCategories.add(_buildAndroidCategory(androidSettings, androidNotifier, theme));
    }
    if (_matchesBackup(settings, query)) {
      matchingCategories.add(_buildBackupCategory(settings, notifier, theme));
    }
    if (_matchesRestore(settings, query)) {
      matchingCategories.add(_buildRestoreCategory(settings, notifier, theme));
    }
    if (_matchesNotifications(settings, query)) {
      matchingCategories.add(_buildNotificationsCategory(settings, notifier, theme));
    }
    if (_matchesLogging(settings, query)) {
      matchingCategories.add(_buildLoggingCategory(settings, notifier, theme));
    }
    if (_matchesPerformance(settings, query)) {
      matchingCategories.add(_buildPerformanceCategory(settings, notifier, theme));
    }
    if (_matchesSecurity(settings, query)) {
      matchingCategories.add(_buildSecurityCategory(settings, notifier, theme));
    }
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

  bool _matchesGeneral(SettingsState s, String q) {
    return 'general theme dark light system language language code autosave save update check'.contains(q);
  }

  bool _matchesAndroid(AndroidSettingsState s, String q) {
    return 'android background backup battery optimization charging wifi permission manage storage document tree'.contains(q);
  }

  bool _matchesBackup(SettingsState s, String q) {
    return 'backup destination path versioning max versions sha256 duplicate overwrite format date naming organization mode'.contains(q);
  }

  bool _matchesRestore(SettingsState s, String q) {
    return 'restore conflicts original location verify history'.contains(q);
  }

  bool _matchesNotifications(SettingsState s, String q) {
    return 'notifications alerts alerts complete fail low storage warning offline background error'.contains(q);
  }

  bool _matchesLogging(SettingsState s, String q) {
    return 'logging logs debug log size retention export clear'.contains(q);
  }

  bool _matchesPerformance(SettingsState s, String q) {
    return 'performance cpu limit ram limit thread limit parallel jobs buffer size power saving'.contains(q);
  }

  bool _matchesSecurity(SettingsState s, String q) {
    return 'security integrity encryption delete confirmation protect lock database'.contains(q);
  }

  bool _matchesStorage(SettingsState s, String q) {
    return 'storage space capacity free space limit warning pause full'.contains(q);
  }

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
          subtitle: 'Automatically commit changes immediately',
          icon: Icons.save_rounded,
          value: s.general.autoSaveSettings,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateGeneralSettings(s.general.copyWith(autoSaveSettings: val)));
          },
        ),
      ],
    );
  }

  Widget _buildAndroidCategory(AndroidSettingsState s, AndroidSettingsNotifier notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Android Background Backup',
      icon: Icons.android_rounded,
      children: [
        SettingsSwitchTile(
          title: 'Background Backup Scheduler',
          subtitle: 'Allow BackupVault to schedule tasks in the background',
          icon: Icons.schedule_rounded,
          value: s.backgroundBackup,
          onChanged: (val) {
            notifier.updateSettings(s.copyWith(backgroundBackup: val));
          },
        ),
        SettingsSwitchTile(
          title: 'Foreground Service',
          subtitle: 'Run backup operations as a foreground service with notification',
          icon: Icons.notification_important_rounded,
          value: s.foregroundService,
          onChanged: (val) {
            notifier.updateSettings(s.copyWith(foregroundService: val));
          },
        ),
        SettingsSwitchTile(
          title: 'Auto Backup on Charging Only',
          subtitle: 'Run backups only when device is connected to a power source',
          icon: Icons.battery_charging_full_rounded,
          value: s.autoBackupOnCharging,
          onChanged: (val) {
            notifier.updateSettings(s.copyWith(autoBackupOnCharging: val));
          },
        ),
        SettingsSwitchTile(
          title: 'Backup on Wi-Fi Only',
          subtitle: 'Restrict backup tasks to Wi-Fi to preserve mobile data plans',
          icon: Icons.wifi_rounded,
          value: s.backupOnWifiOnly,
          onChanged: (val) {
            notifier.updateSettings(s.copyWith(backupOnWifiOnly: val));
          },
        ),
        const Divider(height: 24),
        Text('Android Platform Permissions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(
            _hasStoragePermission ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: _hasStoragePermission ? Colors.green : Colors.amber,
          ),
          title: const Text('Storage Permissions (SAF)'),
          subtitle: Text(_hasStoragePermission ? 'Authorized access to storage folders' : 'Requires authorization to read directories'),
          trailing: ElevatedButton(
            onPressed: () async {
              final granted = await AndroidStorage.requestStoragePermission();
              setState(() {
                _hasStoragePermission = granted;
              });
            },
            child: Text(_hasStoragePermission ? 'Manage' : 'Grant'),
          ),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.battery_alert_rounded, color: Colors.blueGrey),
          title: const Text('Battery Optimization exemption'),
          subtitle: const Text('Prevent Android from killing backup tasks to save power'),
          trailing: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening system battery settings...')),
              );
            },
            child: const Text('Optimize'),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Backup Defaults',
      icon: Icons.backup_rounded,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.folder_shared_rounded, color: Colors.blue),
          title: const Text('Default Backup Destination'),
          subtitle: Text(
            s.backup.defaultBackupDestination.isEmpty
                ? 'No default destination folder selected'
                : 'Selected Android Tree URI',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Select'),
            onPressed: () async {
              final uri = await showDialog<String>(
                context: context,
                builder: (context) => const AndroidFolderPicker(),
              );
              if (uri != null && mounted) {
                _safeAction(context, () => notifier.updateBackupSettings(s.backup.copyWith(defaultBackupDestination: uri)));
              }
            },
          ),
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
      ],
    );
  }

  Widget _buildRestoreCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Restore Defaults',
      icon: Icons.restore_rounded,
      children: [
        SettingsDropdownTile<String>(
          title: 'Conflict Resolution Policy',
          subtitle: 'Action when a file already exists in restore target',
          icon: Icons.file_copy_rounded,
          value: s.restore.conflictPolicy,
          items: const [
            DropdownMenuItem(value: 'overwrite', child: Text('Overwrite Existing File')),
            DropdownMenuItem(value: 'skip', child: Text('Skip/Ignore Conflict')),
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
          subtitle: 'Show Android system notifications',
          icon: Icons.notifications_rounded,
          value: s.notifications.enableNotifications,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateNotificationSettings(s.notifications.copyWith(enableNotifications: val)));
          },
        ),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
          icon: Icons.developer_board_rounded,
          value: s.performance.cpuLimitPercent.toDouble(),
          min: 10,
          max: 100,
          formatLabel: (val) => '${val.toInt()}%',
          onChanged: (val) {
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(cpuLimitPercent: val.toInt())));
          },
        ),
        SettingsSliderTile(
          title: 'Thread Limit',
          icon: Icons.linear_scale_rounded,
          value: s.performance.threadLimit.toDouble(),
          min: 1,
          max: 8,
          onChanged: (val) {
            _safeAction(context, () => notifier.updatePerformanceSettings(s.performance.copyWith(threadLimit: val.toInt())));
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
          icon: Icons.verified_user_rounded,
          value: s.security.verifyIntegrity,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateSecuritySettings(s.security.copyWith(verifyIntegrity: val)));
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
          icon: Icons.pie_chart_rounded,
          value: s.storage.showAvailableSpace,
          onChanged: (val) {
            _safeAction(context, () => notifier.updateStorageSettings(s.storage.copyWith(showAvailableSpace: val)));
          },
        ),
      ],
    );
  }

  Widget _buildImportExportCategory(SettingsState s, SettingsController notifier, ThemeData theme) {
    return SettingsCategoryCard(
      title: 'Configuration Import / Export',
      icon: Icons.swap_vertical_circle_rounded,
      children: [
        const SizedBox(height: 8),
        const Text('Backup and restore your SQLite configuration database file.'),
        const SizedBox(height: 20),
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
                'Version ${s.general.appVersion} (Android)',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('MIT License. Copyright © 2026 ManiKaran.'),
      ],
    );
  }

  void _confirmReset(BuildContext context, SettingsController notifier, AndroidSettingsNotifier androidNotifier) {
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
                androidNotifier.updateSettings(const AndroidSettingsState());
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

  void _safeAction(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Execution Error'),
              content: Text(e.toString()),
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

  void _handleClearLogs(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to delete all historical logs?'),
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

    if (confirmed == true && context.mounted) {
      await ref.read(loggingServiceProvider).clearLogs();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared successfully')),
        );
      }
    }
  }
}
