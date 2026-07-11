import '../../../../core/database/app_database.dart';
import '../../../../core/copy_engine/copy_job.dart';
import '../../../../core/services/backup_engine.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/android_storage.dart';
import 'backup_workflow.dart';

class AndroidBackupWorkflow implements BackupWorkflow {
  final BackupEngine _backupEngine;
  final LoggingService _logger;

  AndroidBackupWorkflow(this._backupEngine, this._logger);

  @override
  Future<List<CopyJob>> run(BackupFolder folder) async {
    String resolvedSource = folder.sourcePath;
    String resolvedDest = folder.destinationPath;

    // Resolve SAF Tree URIs to raw filesystem paths on Android
    if (folder.sourcePath.startsWith('content://')) {
      final resolved = await AndroidStorage.resolvePath(folder.sourcePath);
      if (resolved == null || resolved.isEmpty) {
        await _logger.error(
          'AndroidBackupWorkflow',
          'Failed to resolve Android source Tree URI: ${folder.sourcePath}',
        );
        return [];
      }
      resolvedSource = resolved;
    }

    if (folder.destinationPath.startsWith('content://')) {
      final resolved = await AndroidStorage.resolvePath(folder.destinationPath);
      if (resolved == null || resolved.isEmpty) {
        await _logger.error(
          'AndroidBackupWorkflow',
          'Failed to resolve Android destination Tree URI: ${folder.destinationPath}',
        );
        return [];
      }
      resolvedDest = resolved;
    }

    await _logger.info(
      'AndroidBackupWorkflow',
      'Executing backup with resolved paths. Source: $resolvedSource, Destination: $resolvedDest',
    );

    // Create a temporary folder copy with raw paths for the shared BackupEngine
    final resolvedFolder = folder.copyWith(
      sourcePath: resolvedSource,
      destinationPath: resolvedDest,
    );

    return await _backupEngine.backupFolder(resolvedFolder);
  }
}
