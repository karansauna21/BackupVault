import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/repositories/repository_providers.dart';
import '../settings/settings_provider.dart';
import '../scheduler/scheduler_provider.dart';
import 'configuration_models.dart';
import 'configuration_repository.dart';
import 'configuration_exporter.dart';
import 'configuration_importer.dart';
import 'backup_validator.dart';
import 'migration_manager.dart';
import 'import_export_manager.dart';

// Repository Provider
final configurationRepositoryProvider = Provider<ConfigurationRepository>((ref) {
  final repo = ConfigurationRepository();
  return repo;
});

// Exporter Provider
final configurationExporterProvider = Provider<ConfigurationExporter>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final folderRepo = ref.watch(backupFolderRepositoryProvider);
  final schedulerRepo = ref.watch(schedulerRepositoryProvider);
  final db = ref.watch(databaseProvider);

  return ConfigurationExporter(
    settingsRepo: settingsRepo,
    folderRepo: folderRepo,
    schedulerRepo: schedulerRepo,
    database: db,
  );
});

// Importer Provider
final configurationImporterProvider = Provider<ConfigurationImporter>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final folderRepo = ref.watch(backupFolderRepositoryProvider);
  final schedulerRepo = ref.watch(schedulerRepositoryProvider);
  final db = ref.watch(databaseProvider);

  return ConfigurationImporter(
    settingsRepo: settingsRepo,
    folderRepo: folderRepo,
    schedulerRepo: schedulerRepo,
    database: db,
  );
});

// Validator Provider
final backupValidatorProvider = Provider<BackupValidator>((ref) {
  return BackupValidator();
});

// Migration Provider
final migrationManagerProvider = Provider<MigrationManager>((ref) {
  return MigrationManager();
});

// Orchestrator Manager Provider
final importExportManagerProvider = Provider<ImportExportManager>((ref) {
  final exporter = ref.watch(configurationExporterProvider);
  final importer = ref.watch(configurationImporterProvider);
  final validator = ref.watch(backupValidatorProvider);
  final migration = ref.watch(migrationManagerProvider);
  final historyRepo = ref.watch(configurationRepositoryProvider);

  return ImportExportManager(
    exporter: exporter,
    importer: importer,
    validator: validator,
    migrationManager: migration,
    historyRepo: historyRepo,
  );
});

// History Notifier
class ConfigurationHistoryNotifier extends Notifier<List<HistoryRecord>> {
  late final ConfigurationRepository _repo;

  @override
  List<HistoryRecord> build() {
    _repo = ref.watch(configurationRepositoryProvider);
    _repo.init().then((_) {
      state = List<HistoryRecord>.from(_repo.history);
    });
    return [];
  }

  Future<void> addRecord(HistoryRecord record) async {
    await _repo.addHistoryRecord(record);
    state = List<HistoryRecord>.from(_repo.history);
  }

  Future<void> clearHistory() async {
    await _repo.clearHistory();
    state = List<HistoryRecord>.from(_repo.history);
  }

  void refresh() {
    state = List<HistoryRecord>.from(_repo.history);
  }
}

final configurationHistoryProvider = NotifierProvider<ConfigurationHistoryNotifier, List<HistoryRecord>>(() {
  return ConfigurationHistoryNotifier();
});

// Status States
enum ConfigActionStatus { idle, loading, success, error }

class ConfigActionState {
  final ConfigActionStatus status;
  final String? message;
  final String? filePath;
  final ValidationResult? validationResult;

  const ConfigActionState({
    this.status = ConfigActionStatus.idle,
    this.message,
    this.filePath,
    this.validationResult,
  });

  ConfigActionState copyWith({
    ConfigActionStatus? status,
    String? message,
    String? filePath,
    ValidationResult? validationResult,
  }) {
    return ConfigActionState(
      status: status ?? this.status,
      message: message ?? this.message,
      filePath: filePath ?? this.filePath,
      validationResult: validationResult ?? this.validationResult,
    );
  }
}

class ExportStateNotifier extends Notifier<ConfigActionState> {
  @override
  ConfigActionState build() => const ConfigActionState();

  Future<void> exportConfig({
    required String destinationPath,
    required bool includeLogs,
    required String appVersion,
    required String platformName,
  }) async {
    state = const ConfigActionState(status: ConfigActionStatus.loading);
    try {
      final manager = ref.read(importExportManagerProvider);
      final file = await manager.exportConfig(
        destinationPath: destinationPath,
        includeLogs: includeLogs,
        appVersion: appVersion,
        platformName: platformName,
      );
      ref.read(configurationHistoryProvider.notifier).refresh();
      state = ConfigActionState(
        status: ConfigActionStatus.success,
        filePath: file.path,
        message: 'Configurations exported successfully!',
      );
    } catch (e) {
      state = ConfigActionState(
        status: ConfigActionStatus.error,
        message: e.toString(),
      );
    }
  }
}

final exportStateProvider = NotifierProvider<ExportStateNotifier, ConfigActionState>(() {
  return ExportStateNotifier();
});

class ImportStateNotifier extends Notifier<ConfigActionState> {
  @override
  ConfigActionState build() => const ConfigActionState();

  Future<void> importConfig({
    required String zipPath,
    required bool restoreSettings,
    required bool restoreFolders,
    required bool restoreSchedules,
    required bool restoreLogs,
    required String appVersion,
    required String platformName,
  }) async {
    state = const ConfigActionState(status: ConfigActionStatus.loading);
    try {
      final manager = ref.read(importExportManagerProvider);
      await manager.importConfig(
        zipPath: zipPath,
        restoreSettings: restoreSettings,
        restoreFolders: restoreFolders,
        restoreSchedules: restoreSchedules,
        restoreLogs: restoreLogs,
        appVersion: appVersion,
        platformName: platformName,
      );
      ref.read(configurationHistoryProvider.notifier).refresh();
      state = const ConfigActionState(
        status: ConfigActionStatus.success,
        message: 'Configurations imported successfully! Restoring database...',
      );
    } catch (e) {
      state = ConfigActionState(
        status: ConfigActionStatus.error,
        message: e.toString(),
      );
    }
  }
}

final importStateProvider = NotifierProvider<ImportStateNotifier, ConfigActionState>(() {
  return ImportStateNotifier();
});

class ValidationStateNotifier extends Notifier<ConfigActionState> {
  @override
  ConfigActionState build() => const ConfigActionState();

  Future<ValidationResult> validatePackage(String zipPath) async {
    state = const ConfigActionState(status: ConfigActionStatus.loading);
    try {
      final manager = ref.read(importExportManagerProvider);
      final result = await manager.validateBackupFile(zipPath);
      ref.read(configurationHistoryProvider.notifier).refresh();
      
      state = ConfigActionState(
        status: ConfigActionStatus.success,
        validationResult: result,
      );
      return result;
    } catch (e) {
      state = ConfigActionState(
        status: ConfigActionStatus.error,
        message: e.toString(),
      );
      rethrow;
    }
  }
}

final validationStateProvider = NotifierProvider<ValidationStateNotifier, ConfigActionState>(() {
  return ValidationStateNotifier();
});
