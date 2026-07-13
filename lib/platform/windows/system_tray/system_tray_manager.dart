import 'package:system_tray/system_tray.dart';
import '../../../core/models/background_models.dart';

class SystemTrayManager {
  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;

  final void Function() onOpenDashboard;
  final void Function() onPauseBackup;
  final void Function() onResumeBackup;
  final void Function() onStartBackup;
  final void Function() onStopBackup;
  final void Function() onOpenBackupFolder;
  final void Function() onRestore;
  final void Function() onLogs;
  final void Function() onSettings;
  final void Function() onExit;

  SystemTrayManager({
    required this.onOpenDashboard,
    required this.onPauseBackup,
    required this.onResumeBackup,
    required this.onStartBackup,
    required this.onStopBackup,
    required this.onOpenBackupFolder,
    required this.onRestore,
    required this.onLogs,
    required this.onSettings,
    required this.onExit,
  });

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const iconPath = 'assets/app_icon.ico';

      _isInitialized = await _systemTray.initSystemTray(
        title: 'Backup Valut',
        iconPath: iconPath,
        toolTip: 'Backup Valut - Idle',
      );

      if (_isInitialized) {
        await updateMenu(isBackupRunning: false, isPaused: false);

        _systemTray.registerSystemTrayEventHandler((eventName) {
          if (eventName == 'leftMouseUp' || eventName == 'leftMouseDblClk') {
            onOpenDashboard();
          } else if (eventName == 'rightMouseUp') {
            _systemTray.popUpContextMenu();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> updateMenu({required bool isBackupRunning, required bool isPaused}) async {
    if (!_isInitialized) return;

    try {
      final menuItems = [
        MenuItem(
          label: 'Open Dashboard',
          onClicked: onOpenDashboard,
        ),
        MenuSeparator(),
        MenuItem(
          label: 'Start Backup',
          enabled: !isBackupRunning,
          onClicked: onStartBackup,
        ),
        MenuItem(
          label: 'Stop Backup',
          enabled: isBackupRunning,
          onClicked: onStopBackup,
        ),
        MenuItem(
          label: 'Pause Backup',
          enabled: isBackupRunning && !isPaused,
          onClicked: onPauseBackup,
        ),
        MenuItem(
          label: 'Resume Backup',
          enabled: isBackupRunning && isPaused,
          onClicked: onResumeBackup,
        ),
        MenuSeparator(),
        MenuItem(
          label: 'Open Backup Folder',
          onClicked: onOpenBackupFolder,
        ),
        MenuItem(
          label: 'Restore Files',
          onClicked: onRestore,
        ),
        MenuItem(
          label: 'View Logs',
          onClicked: onLogs,
        ),
        MenuItem(
          label: 'Settings',
          onClicked: onSettings,
        ),
        MenuSeparator(),
        MenuItem(
          label: 'Exit',
          onClicked: onExit,
        ),
      ];

      await _systemTray.setContextMenu(menuItems);
    } catch (_) {}
  }

  Future<void> updateTooltip(TrayState state) async {
    if (!_isInitialized) return;

    try {
      final tooltip = 'Backup Valut\n'
          'Status: ${state.currentStatus}\n'
          'Remaining: ${state.filesRemaining} files\n'
          'Speed: ${state.currentSpeed}\n'
          'Storage: ${state.storageUsage}';

      await _systemTray.setToolTip(tooltip);
    } catch (_) {}
  }

  Future<void> destroy() async {
    _isInitialized = false;
  }
}
