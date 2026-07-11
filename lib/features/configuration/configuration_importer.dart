import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'configuration_models.dart';
import '../settings/settings_repository.dart';
import '../../core/repositories/backup_folder_repository.dart';
import '../../core/models/scheduler_models.dart';
import '../../core/repositories/scheduler_repository.dart';
import '../../core/database/app_database.dart';
import '../settings/settings_models.dart';

class ConfigurationImporter {
  final SettingsRepository settingsRepo;
  final BackupFolderRepository folderRepo;
  final SchedulerRepository schedulerRepo;
  final AppDatabase database;

  ConfigurationImporter({
    required this.settingsRepo,
    required this.folderRepo,
    required this.schedulerRepo,
    required this.database,
  });

  /// Read and extract the ConfigurationPackage from a ZIP file path
  Future<ConfigurationPackage> readPackage(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw Exception('Backup package file does not exist.');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final metadataFile = archive.findFile('metadata.json');
    final configFile = archive.findFile('config.json');

    if (metadataFile == null || configFile == null) {
      throw Exception('Invalid configuration package structure.');
    }

    final metadataString = utf8.decode(metadataFile.content as List<int>);
    final configString = utf8.decode(configFile.content as List<int>);

    final metadataJson = json.decode(metadataString) as Map<String, dynamic>;
    final configJson = json.decode(configString) as Map<String, dynamic>;

    return ConfigurationPackage(
      metadata: ConfigMetadata.fromJson(metadataJson),
      content: configJson,
    );
  }

  /// Perform the restore of selected sections
  Future<void> restore({
    required ConfigurationPackage package,
    required bool restoreSettings,
    required bool restoreFolders,
    required bool restoreSchedules,
    required bool restoreLogs,
  }) async {
    final content = package.content;

    // 1. Settings
    if (restoreSettings && content.containsKey('settings')) {
      final settingsJson = content['settings'] as Map<String, dynamic>;
      final settings = SettingsState.fromJson(settingsJson);
      await settingsRepo.saveSettings(settings);
    }

    // 2. Folders
    if (restoreFolders && content.containsKey('folders')) {
      // Clear existing folders
      final existingFolders = await folderRepo.getAllFolders();
      for (final f in existingFolders) {
        await folderRepo.deleteFolder(f.id);
      }

      final List foldersList = content['folders'] as List;
      for (final f in foldersList) {
        if (f is! Map) continue;
        final fMap = Map<String, dynamic>.from(f);
        final companion = BackupFoldersCompanion(
          name: Value(fMap['name'] as String),
          sourcePath: Value(fMap['sourcePath'] as String),
          destinationPath: Value(fMap['destinationPath'] as String),
          enabled: Value(fMap['enabled'] as bool? ?? true),
          createdAt: Value(fMap['createdAt'] != null
              ? DateTime.parse(fMap['createdAt'] as String)
              : DateTime.now()),
          backupInterval: Value(fMap['backupInterval'] as String? ?? 'manual'),
          lastBackupAt: Value(fMap['lastBackupAt'] != null
              ? DateTime.parse(fMap['lastBackupAt'] as String)
              : null),
          nextBackupAt: Value(fMap['nextBackupAt'] != null
              ? DateTime.parse(fMap['nextBackupAt'] as String)
              : null),
        );
        await database.backupFoldersDao.insertFolder(companion);
      }
    }

    // 3. Schedules
    if (restoreSchedules && content.containsKey('schedules')) {
      // Clear existing schedules
      final schedules = List<ScheduleConfig>.from(schedulerRepo.schedules);
      for (final s in schedules) {
        await schedulerRepo.deleteSchedule(s.id);
      }

      final List schedulesList = content['schedules'] as List;
      for (final s in schedulesList) {
        if (s is! Map) continue;
        final schedule = ScheduleConfig.fromJson(Map<String, dynamic>.from(s));
        await schedulerRepo.addSchedule(schedule);
      }
    }

    // 4. Logs
    if (restoreLogs && content.containsKey('logs')) {
      await database.backupLogsDao.clearAllLogs();
      final List logsList = content['logs'] as List;
      for (final l in logsList) {
        if (l is! Map) continue;
        final lMap = Map<String, dynamic>.from(l);
        final companion = BackupLogsCompanion(
          logType: Value(lMap['logType'] as String? ?? 'info'),
          message: Value(lMap['message'] as String? ?? ''),
          createdAt: Value(lMap['createdAt'] != null
              ? DateTime.parse(lMap['createdAt'] as String)
              : DateTime.now()),
          tag: Value(lMap['tag'] as String?),
          stackTrace: Value(lMap['stackTrace'] as String?),
        );
        await database.backupLogsDao.insertLog(companion);
      }
    }
  }
}
