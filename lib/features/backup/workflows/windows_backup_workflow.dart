import '../../../../core/database/app_database.dart';
import '../../../../core/copy_engine/copy_job.dart';
import '../../../../core/services/backup_engine.dart';
import 'backup_workflow.dart';

class WindowsBackupWorkflow implements BackupWorkflow {
  final BackupEngine _backupEngine;

  WindowsBackupWorkflow(this._backupEngine);

  @override
  Future<List<CopyJob>> run(BackupFolder folder) async {
    return await _backupEngine.backupFolder(folder);
  }
}
