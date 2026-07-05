import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/file_watcher/watcher_manager.dart';
import '../../core/copy_engine/copy_queue.dart';

class DashboardController {
  final Ref _ref;

  DashboardController(this._ref);

  void startBackup() {
    _ref.read(copyQueueProvider.notifier).resumeQueue();
    _ref.read(watcherStateProvider.notifier).resumeAll();
  }

  void pauseBackup() {
    _ref.read(copyQueueProvider.notifier).pauseQueue();
    _ref.read(watcherStateProvider.notifier).pauseAll();
  }

  void resumeBackup() {
    _ref.read(copyQueueProvider.notifier).resumeQueue();
    _ref.read(watcherStateProvider.notifier).resumeAll();
  }

  Future<void> openBackupFolder(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [path]);
    }
  }

  void navigateToLogs(BuildContext context) {
    context.go('/logs');
  }

  void navigateToSettings(BuildContext context) {
    context.go('/settings');
  }

  void navigateToRestore(BuildContext context) {
    context.go('/restore');
  }

  void navigateToFolders(BuildContext context) {
    context.go('/folders');
  }
}

final dashboardControllerProvider = Provider<DashboardController>((ref) {
  return DashboardController(ref);
});
