import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'configuration_models.dart';
import '../settings/settings_repository.dart';
import '../../core/repositories/backup_folder_repository.dart';
import '../scheduler/scheduler_repository.dart';
import '../../core/database/app_database.dart';

class ConfigurationExporter {
  final SettingsRepository settingsRepo;
  final BackupFolderRepository folderRepo;
  final SchedulerRepository schedulerRepo;
  final AppDatabase database;

  ConfigurationExporter({
    required this.settingsRepo,
    required this.folderRepo,
    required this.schedulerRepo,
    required this.database,
  });

  Future<File> exportToZip({
    required String destinationPath,
    required bool includeLogs,
    required String appVersion,
    required String platformName,
  }) async {
    // 1. Load data
    final settings = await settingsRepo.loadSettings();
    final folders = await folderRepo.getAllFolders();
    final schedules = schedulerRepo.schedules;
    final history = schedulerRepo.history;

    List<Map<String, dynamic>> logsList = [];
    if (includeLogs) {
      final dbLogs = await database.backupLogsDao.getAllLogs(limit: 1000);
      logsList = dbLogs.map((l) => {
        'id': l.id,
        'logType': l.logType,
        'message': l.message,
        'createdAt': l.createdAt.toIso8601String(),
        'tag': l.tag,
        'stackTrace': l.stackTrace,
      }).toList();
    }

    final content = {
      'settings': settings.toJson(),
      'folders': folders.map((f) => {
        'id': f.id,
        'name': f.name,
        'sourcePath': f.sourcePath,
        'destinationPath': f.destinationPath,
        'enabled': f.enabled,
        'createdAt': f.createdAt.toIso8601String(),
        'backupInterval': f.backupInterval,
        'lastBackupAt': f.lastBackupAt?.toIso8601String(),
        'nextBackupAt': f.nextBackupAt?.toIso8601String(),
      }).toList(),
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
      'logs': logsList,
    };

    // 2. Generate Checksum
    final contentString = json.encode(content);
    final bytes = utf8.encode(contentString);
    final checksum = sha256.convert(bytes).toString();

    // 3. Create Metadata
    final metadata = ConfigMetadata(
      appVersion: appVersion,
      databaseVersion: database.schemaVersion,
      exportDate: DateTime.now(),
      exportDevice: Platform.localHostname,
      platform: platformName,
      checksum: checksum,
    );

    final metadataString = json.encode(metadata.toJson());

    // 4. Compress to ZIP
    final encoder = ZipEncoder();
    final archive = Archive();

    archive.addFile(ArchiveFile('metadata.json', metadataString.length, utf8.encode(metadataString)));
    archive.addFile(ArchiveFile('config.json', contentString.length, bytes));

    final zipBytes = encoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to compress configuration package.');
    }

    final file = File(destinationPath);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    await file.writeAsBytes(zipBytes);
    return file;
  }
}
