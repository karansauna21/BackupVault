import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final pathController = TextEditingController(text: settings.defaultDestinationPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Section
            _buildSectionHeader(context, 'Appearance'),
            ListTile(
              leading: const Icon(Icons.palette_rounded),
              title: const Text('Theme Mode'),
              subtitle: Text(settings.themeMode.toUpperCase()),
              trailing: DropdownButton<String>(
                value: settings.themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('System')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    notifier.updateThemeMode(val);
                  }
                },
              ),
            ),
            const Divider(),

            // Backup Settings Section
            _buildSectionHeader(context, 'Backup System Defaults'),
            ListTile(
              leading: const Icon(Icons.drive_folder_upload_rounded),
              title: const Text('Default Destination Path'),
              subtitle: Text(
                settings.defaultDestinationPath.isEmpty
                    ? 'No default destination set'
                    : settings.defaultDestinationPath,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {
                  _showDestinationPathDialog(context, ref, pathController, notifier);
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.schedule_rounded),
              title: const Text('Auto-Backup in Background'),
              subtitle: const Text('Runs backups periodically according to folder schedules'),
              value: settings.autoBackupEnabled,
              onChanged: (val) {
                notifier.updateAutoBackupEnabled(val);
              },
            ),
            if (settings.autoBackupEnabled)
              ListTile(
                leading: const Icon(Icons.av_timer_rounded),
                title: const Text('Check Interval'),
                subtitle: Text('Checks every: ${settings.backupInterval.toUpperCase()}'),
                trailing: DropdownButton<String>(
                  value: settings.backupInterval,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'manual', child: Text('Manual Only')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateBackupInterval(val);
                    }
                  },
                ),
              ),
            const Divider(),

            // Notifications
            _buildSectionHeader(context, 'Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_rounded),
              title: const Text('Notify on Success'),
              subtitle: const Text('Send a system alert when a backup completes successfully'),
              value: settings.notifyOnSuccess,
              onChanged: (val) {
                notifier.updateNotifyOnSuccess(val);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_paused_rounded),
              title: const Text('Notify on Failure'),
              subtitle: const Text('Alert when a scheduled/manual backup execution fails'),
              value: settings.notifyOnFailure,
              onChanged: (val) {
                notifier.updateNotifyOnFailure(val);
              },
            ),
            const Divider(),

            // About Screen Navigation
            _buildSectionHeader(context, 'About'),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About BackupVault'),
              subtitle: const Text('App version, open-source contributors, and license details'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                context.go('/about');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDestinationPathDialog(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
    SettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Destination'),
          content: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Directory Path',
              hintText: 'e.g. D:\\Backups',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                notifier.updateDefaultDestinationPath(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
