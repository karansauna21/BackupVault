import '../../../../core/database/app_database.dart';
import '../../../../core/copy_engine/copy_job.dart';

abstract class BackupWorkflow {
  Future<List<CopyJob>> run(BackupFolder folder);
}
