import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import 'backup_folder_repository.dart';
import 'backup_file_repository.dart';
import 'file_version_repository.dart';
import 'backup_log_repository.dart';
import 'impl/backup_folder_repository_impl.dart';
import 'impl/backup_file_repository_impl.dart';
import 'impl/file_version_repository_impl.dart';
import 'impl/backup_log_repository_impl.dart';

final backupFolderRepositoryProvider = Provider<BackupFolderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupFolderRepositoryImpl(db.backupFoldersDao);
});

final backupFileRepositoryProvider = Provider<BackupFileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupFileRepositoryImpl(db.backupFilesDao);
});

final fileVersionRepositoryProvider = Provider<FileVersionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FileVersionRepositoryImpl(db.fileVersionsDao);
});

final backupLogRepositoryProvider = Provider<BackupLogRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupLogRepositoryImpl(db.backupLogsDao);
});
