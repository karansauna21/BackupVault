import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class BackupFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get sourcePath => text()();
  TextColumn get destinationPath => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // For compatibility with the existing UI and view models
  TextColumn get backupInterval => text().withDefault(const Constant('manual'))();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  DateTimeColumn get nextBackupAt => dateTime().nullable()();
}

@TableIndex(name: 'idx_backup_files_name', columns: {#fileName})
@TableIndex(name: 'idx_backup_files_sha', columns: {#sha256})
class BackupFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get folderId => integer().references(BackupFolders, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text().withLength(min: 1, max: 255)();
  TextColumn get extension => text()();
  TextColumn get originalPath => text()();
  TextColumn get backupPath => text()();
  IntColumn get fileSize => integer()();
  TextColumn get sha256 => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get backupStatus => text()(); // success, failed, pending
}

class FileVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fileId => integer().references(BackupFiles, #id, onDelete: KeyAction.cascade)();
  IntColumn get versionNumber => integer()();
  TextColumn get backupPath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class BackupLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get logType => text()(); // info, warning, error
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // For compatibility with logs view model and logging service
  TextColumn get tag => text().nullable()();
  TextColumn get stackTrace => text().nullable()();
}

class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get autoStart => boolean().withDefault(const Constant(false))();
  BoolColumn get darkMode => boolean().withDefault(const Constant(false))();
  BoolColumn get notifications => boolean().withDefault(const Constant(true))();
  BoolColumn get verifyHash => boolean().withDefault(const Constant(true))();
  BoolColumn get versioningEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get backupMode => text().withDefault(const Constant('incremental'))(); // full, incremental
  TextColumn get language => text().withDefault(const Constant('en'))();

  // Extra columns for seamless app integration & compatibility
  TextColumn get defaultDestinationPath => text().withDefault(const Constant(''))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  BoolColumn get autoBackupEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get backupInterval => text().withDefault(const Constant('manual'))();
  BoolColumn get notifyOnSuccess => boolean().withDefault(const Constant(true))();
  BoolColumn get notifyOnFailure => boolean().withDefault(const Constant(true))();
}

// Keep BackupHistory for dashboard stats and history compatibility
class BackupHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get folderId => integer().nullable().references(BackupFolders, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()(); // success, failed, in_progress
  TextColumn get message => text()();
  IntColumn get filesCount => integer().withDefault(const Constant(0))();
  IntColumn get totalSize => integer().withDefault(const Constant(0))(); // in bytes
  TextColumn get backupType => text().withDefault(const Constant('full'))(); // full, incremental
}

class SearchHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text().withLength(min: 1, max: 255)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
}

class PairedDevices extends Table {
  TextColumn get deviceUuid => text().withLength(min: 1, max: 255)();
  TextColumn get deviceName => text().withLength(min: 1, max: 255)();
  TextColumn get platform => text()();
  TextColumn get osVersion => text()();
  TextColumn get appVersion => text()();
  TextColumn get deviceModel => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSeen => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {deviceUuid};
}

@DriftDatabase(
  tables: [BackupFolders, BackupFiles, FileVersions, BackupLogs, Settings, BackupHistory, SearchHistories, PairedDevices],
  daos: [BackupFoldersDao, BackupFilesDao, FileVersionsDao, BackupLogsDao, SettingsDao, SearchHistoriesDao, PairedDevicesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 5) {
          // Drop all and recreate to start fresh with schema version 5
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await m.createAll();
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'backup_vault', 'backup_vault.db'));
    
    // Ensure parent directory exists
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    
    return NativeDatabase.createInBackground(file);
  });
}

@DriftAccessor(tables: [BackupFolders])
class BackupFoldersDao extends DatabaseAccessor<AppDatabase> with _$BackupFoldersDaoMixin {
  BackupFoldersDao(super.db);

  Future<List<BackupFolder>> getAllFolders() => select(backupFolders).get();
  Stream<List<BackupFolder>> watchAllFolders() => select(backupFolders).watch();
  Future<BackupFolder?> getFolderById(int id) => (select(backupFolders)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertFolder(BackupFoldersCompanion folder) => into(backupFolders).insert(folder);
  Future<bool> updateFolder(BackupFolder folder) => update(backupFolders).replace(folder);
  Future<int> deleteFolderById(int id) => (delete(backupFolders)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [BackupFiles])
class BackupFilesDao extends DatabaseAccessor<AppDatabase> with _$BackupFilesDaoMixin {
  BackupFilesDao(super.db);

  Future<List<BackupFile>> getAllFiles() => select(backupFiles).get();
  Future<List<BackupFile>> getFilesByFolderId(int folderId) => (select(backupFiles)..where((t) => t.folderId.equals(folderId))).get();
  Future<BackupFile?> getFileById(int id) => (select(backupFiles)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertFile(BackupFilesCompanion file) => into(backupFiles).insert(file);
  Future<bool> updateFile(BackupFile file) => update(backupFiles).replace(file);
  Future<int> deleteFileById(int id) => (delete(backupFiles)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [FileVersions])
class FileVersionsDao extends DatabaseAccessor<AppDatabase> with _$FileVersionsDaoMixin {
  FileVersionsDao(super.db);

  Future<List<FileVersion>> getAllVersions() => select(fileVersions).get();
  Future<List<FileVersion>> getVersionsByFileId(int fileId) => (select(fileVersions)..where((t) => t.fileId.equals(fileId))).get();
  Future<int> insertVersion(FileVersionsCompanion version) => into(fileVersions).insert(version);
  Future<bool> updateVersion(FileVersion version) => update(fileVersions).replace(version);
  Future<int> deleteVersionById(int id) => (delete(fileVersions)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [BackupLogs])
class BackupLogsDao extends DatabaseAccessor<AppDatabase> with _$BackupLogsDaoMixin {
  BackupLogsDao(super.db);

  Future<List<BackupLog>> getAllLogs({String? logType, int limit = 200}) {
    final query = select(backupLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    if (logType != null) {
      query.where((t) => t.logType.equals(logType));
    }
    return query.get();
  }
  Future<int> insertLog(BackupLogsCompanion log) => into(backupLogs).insert(log);
  Future<int> clearAllLogs() => delete(backupLogs).go();
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<Setting?> getSettings() => select(settings).getSingleOrNull();
  Future<int> insertSettings(SettingsCompanion settingsCompanion) => into(settings).insert(settingsCompanion);
  Future<bool> updateSettings(Setting setting) => update(settings).replace(setting);
}

@DriftAccessor(tables: [SearchHistories])
class SearchHistoriesDao extends DatabaseAccessor<AppDatabase> with _$SearchHistoriesDaoMixin {
  SearchHistoriesDao(super.db);

  Future<List<SearchHistory>> getRecentSearchHistory({int limit = 50}) {
    return (select(searchHistories)
      ..orderBy([
        (t) => OrderingTerm.desc(t.pinned),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit))
      .get();
  }

  Future<int> insertSearchHistory(SearchHistoriesCompanion history) => into(searchHistories).insert(history);
  Future<bool> updateSearchHistory(SearchHistory history) => update(searchHistories).replace(history);
  Future<int> deleteSearchHistoryById(int id) => (delete(searchHistories)..where((t) => t.id.equals(id))).go();
  Future<int> clearSearchHistory() => delete(searchHistories).go();
}

@DriftAccessor(tables: [PairedDevices])
class PairedDevicesDao extends DatabaseAccessor<AppDatabase> with _$PairedDevicesDaoMixin {
  PairedDevicesDao(super.db);

  Future<List<PairedDevice>> getAllDevices() => select(pairedDevices).get();
  Future<PairedDevice?> getDeviceByUuid(String uuid) => (select(pairedDevices)..where((t) => t.deviceUuid.equals(uuid))).getSingleOrNull();
  Future<int> insertDevice(PairedDevicesCompanion device) => into(pairedDevices).insert(device);
  Future<bool> updateDevice(PairedDevice device) => update(pairedDevices).replace(device);
  Future<int> deleteDeviceByUuid(String uuid) => (delete(pairedDevices)..where((t) => t.deviceUuid.equals(uuid))).go();
}
