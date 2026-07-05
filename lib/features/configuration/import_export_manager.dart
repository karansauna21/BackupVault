import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'configuration_models.dart';
import 'configuration_exporter.dart';
import 'configuration_importer.dart';
import 'backup_validator.dart';
import 'migration_manager.dart';
import 'configuration_repository.dart';

class ImportExportManager {
  final ConfigurationExporter exporter;
  final ConfigurationImporter importer;
  final BackupValidator validator;
  final MigrationManager migrationManager;
  final ConfigurationRepository historyRepo;

  ImportExportManager({
    required this.exporter,
    required this.importer,
    required this.validator,
    required this.migrationManager,
    required this.historyRepo,
  });

  /// Export configuration to a specific path
  Future<File> exportConfig({
    required String destinationPath,
    required bool includeLogs,
    required String appVersion,
    required String platformName,
  }) async {
    final uuid = const Uuid().v4();
    try {
      final file = await exporter.exportToZip(
        destinationPath: destinationPath,
        includeLogs: includeLogs,
        appVersion: appVersion,
        platformName: platformName,
      );

      final record = HistoryRecord(
        id: uuid,
        actionType: 'export',
        timestamp: DateTime.now(),
        status: 'success',
        details: 'Configuration successfully exported to ${p.basename(destinationPath)}',
        filePath: destinationPath,
      );
      await historyRepo.addHistoryRecord(record);
      return file;
    } catch (e) {
      final record = HistoryRecord(
        id: uuid,
        actionType: 'export',
        timestamp: DateTime.now(),
        status: 'failed',
        details: 'Failed to export configuration.',
        filePath: destinationPath,
        errorMessage: e.toString(),
      );
      await historyRepo.addHistoryRecord(record);
      rethrow;
    }
  }

  /// Perform validation on a backup file
  Future<ValidationResult> validateBackupFile(String zipPath) async {
    final uuid = const Uuid().v4();
    try {
      final package = await importer.readPackage(zipPath);
      final validation = validator.validatePackage(package);

      final record = HistoryRecord(
        id: uuid,
        actionType: 'validation',
        timestamp: DateTime.now(),
        status: validation.isValid ? 'success' : 'failed',
        details: 'Validation completed for ${p.basename(zipPath)}',
        filePath: zipPath,
        validationResults: validation.toJson(),
      );
      await historyRepo.addHistoryRecord(record);
      return validation;
    } catch (e) {
      final validation = ValidationResult(
        isValid: false,
        errors: [e.toString()],
        warnings: [],
        appVersion: 'unknown',
        databaseVersion: 0,
      );
      final record = HistoryRecord(
        id: uuid,
        actionType: 'validation',
        timestamp: DateTime.now(),
        status: 'failed',
        details: 'Error parsing validation package.',
        filePath: zipPath,
        errorMessage: e.toString(),
      );
      await historyRepo.addHistoryRecord(record);
      return validation;
    }
  }

  /// Import configuration with automatic backup for rollback support
  Future<void> importConfig({
    required String zipPath,
    required bool restoreSettings,
    required bool restoreFolders,
    required bool restoreSchedules,
    required bool restoreLogs,
    required String appVersion,
    required String platformName,
  }) async {
    final uuid = const Uuid().v4();
    ConfigurationPackage? rollbackPackage;
    
    // 1. Create a backup of the current configuration for rollback
    try {
      final tempDir = await getTemporaryDirectory();
      final rollbackPath = p.join(tempDir.path, 'rollback_$uuid.zip');
      
      // Export current state to temporary zip
      await exporter.exportToZip(
        destinationPath: rollbackPath,
        includeLogs: restoreLogs,
        appVersion: appVersion,
        platformName: platformName,
      );
      
      rollbackPackage = await importer.readPackage(rollbackPath);
      
      // Delete temporary backup file
      final tempFile = File(rollbackPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {
      // Rollback backup creation failed, proceed with warning
    }

    // 2. Perform the import and migration
    try {
      var package = await importer.readPackage(zipPath);
      
      // Validate
      final validation = validator.validatePackage(package);
      if (!validation.isValid) {
        throw Exception('Package validation failed: ${validation.errors.join(", ")}');
      }

      // Migrate if older dbVersion
      if (package.metadata.databaseVersion < 4) {
        package = migrationManager.migrate(package);
        final migrationUuid = const Uuid().v4();
        await historyRepo.addHistoryRecord(HistoryRecord(
          id: migrationUuid,
          actionType: 'migration',
          timestamp: DateTime.now(),
          status: 'success',
          details: 'Schema automatically upgraded from version ${package.metadata.databaseVersion} to 4',
        ));
      }

      // Execute Restore
      await importer.restore(
        package: package,
        restoreSettings: restoreSettings,
        restoreFolders: restoreFolders,
        restoreSchedules: restoreSchedules,
        restoreLogs: restoreLogs,
      );

      final record = HistoryRecord(
        id: uuid,
        actionType: 'import',
        timestamp: DateTime.now(),
        status: 'success',
        details: 'Configuration successfully imported from ${p.basename(zipPath)}',
        filePath: zipPath,
      );
      await historyRepo.addHistoryRecord(record);
    } catch (e) {
      // 3. Rollback on Failure
      if (rollbackPackage != null) {
        try {
          await importer.restore(
            package: rollbackPackage,
            restoreSettings: restoreSettings,
            restoreFolders: restoreFolders,
            restoreSchedules: restoreSchedules,
            restoreLogs: restoreLogs,
          );
        } catch (_) {
          // Double fault (rollback failed)
        }
      }

      final record = HistoryRecord(
        id: uuid,
        actionType: 'import',
        timestamp: DateTime.now(),
        status: 'failed',
        details: 'Import failed. Automatic rollback was performed.',
        filePath: zipPath,
        errorMessage: e.toString(),
      );
      await historyRepo.addHistoryRecord(record);
      rethrow;
    }
  }
}
