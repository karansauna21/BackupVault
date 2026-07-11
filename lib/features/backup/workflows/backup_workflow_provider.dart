import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/backup_engine.dart';
import '../../../../core/services/logging_service.dart';
import 'backup_workflow.dart';
import 'windows_backup_workflow.dart';
import 'android_backup_workflow.dart';

final backupWorkflowProvider = Provider<BackupWorkflow>((ref) {
  final backupEngine = ref.watch(backupEngineProvider);
  final logger = ref.watch(loggingServiceProvider);

  if (Platform.isAndroid) {
    return AndroidBackupWorkflow(backupEngine, logger);
  } else {
    return WindowsBackupWorkflow(backupEngine);
  }
});
