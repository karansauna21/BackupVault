import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/core/database/database_provider.dart';
import 'package:backup_vault/features/backup/presentation/view_models/backup_view_model.dart';
import 'package:backup_vault/features/settings/settings_provider.dart';
import 'package:backup_vault/features/settings/settings_database.dart';
import 'package:backup_vault/core/services/backup_migration_service.dart';

void main() {
  group('Backup Organization and Migration Integration Tests', () {
    late Directory tempSourceDir;
    late Directory tempDestDir;
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempSourceDir = await Directory.systemTemp.createTemp('backup_org_source');
      tempDestDir = await Directory.systemTemp.createTemp('backup_org_dest');

      // Create test files with different extensions
      await File(p.join(tempSourceDir.path, 'photo.png')).writeAsString('image-data');
      await File(p.join(tempSourceDir.path, 'video.mp4')).writeAsString('video-data');
      await File(p.join(tempSourceDir.path, 'doc.pdf')).writeAsString('pdf-data');
      await File(p.join(tempSourceDir.path, 'archive.zip')).writeAsString('zip-data');
      await File(p.join(tempSourceDir.path, 'song.mp3')).writeAsString('mp3-data');
      await File(p.join(tempSourceDir.path, 'app.exe')).writeAsString('exe-data');
      await File(p.join(tempSourceDir.path, 'readme.txt')).writeAsString('txt-data');
      await File(p.join(tempSourceDir.path, 'config.json')).writeAsString('json-data'); // Others

      final settingsDb = SettingsDatabase(isInMemory: true);
      await settingsDb.init();

      db = AppDatabase(executor: NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsDatabaseProvider.overrideWithValue(settingsDb),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      try {
        await tempSourceDir.delete(recursive: true);
      } catch (_) {}
      try {
        await tempDestDir.delete(recursive: true);
      } catch (_) {}
    });

    test('Verify Smart Mode, Hybrid Mode, and Migration', () async {
      // Set to Smart Mode
      final settingsNotifier = container.read(settingsProvider.notifier);
      final currentBackupSettings = container.read(settingsProvider).backup;
      await settingsNotifier.updateBackupSettings(
        currentBackupSettings.copyWith(backupOrganizationMode: 'smart'),
      );

      final folderCompanion = BackupFoldersCompanion.insert(
        name: 'Workspace',
        sourcePath: tempSourceDir.path,
        destinationPath: tempDestDir.path,
        enabled: const Value(true),
      );
      await db.into(db.backupFolders).insert(folderCompanion);
      final folder = (await db.select(db.backupFolders).get()).first;

      final backupNotifier = container.read(backupProvider.notifier);
      await backupNotifier.runBackup(folder);

      // Verify files are organized inside correct type folders on disk
      expect(await File(p.join(tempDestDir.path, 'Images', 'photo.png')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Videos', 'video.mp4')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Documents', 'doc.pdf')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Archives', 'archive.zip')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Audio', 'song.mp3')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Applications', 'app.exe')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Documents', 'readme.txt')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Others', 'config.json')).exists(), isTrue);

      // Verify original flat structure does NOT exist
      expect(await File(p.join(tempDestDir.path, 'photo.png')).exists(), isFalse);

      // Verify database contains the categorized paths
      var files = await db.select(db.backupFiles).get();
      expect(files.length, equals(8));
      var photoFile = files.firstWhere((f) => f.fileName == 'photo.png');
      expect(photoFile.backupPath, contains('Images'));

      // Migrate Smart -> Mirror
      final migration = container.read(backupMigrationServiceProvider);
      await migration.migrateAllFolders('smart', 'mirror');

      // Verify files moved back to mirror locations
      expect(await File(p.join(tempDestDir.path, 'Images', 'photo.png')).exists(), isFalse);
      expect(await File(p.join(tempDestDir.path, 'photo.png')).exists(), isTrue);

      // Verify SQLite updated
      files = await db.select(db.backupFiles).get();
      photoFile = files.firstWhere((f) => f.fileName == 'photo.png');
      expect(photoFile.backupPath, equals(p.join(tempDestDir.path, 'photo.png')));

      // Migrate Mirror -> Hybrid
      await migration.migrateAllFolders('mirror', 'hybrid');

      // Verify files exist in original location (Mirror) AND categorized location (Smart)
      expect(await File(p.join(tempDestDir.path, 'photo.png')).exists(), isTrue);
      expect(await File(p.join(tempDestDir.path, 'Images', 'photo.png')).exists(), isTrue);

      // Verify database points to the mirror/original path (primary)
      files = await db.select(db.backupFiles).get();
      photoFile = files.firstWhere((f) => f.fileName == 'photo.png');
      expect(photoFile.backupPath, equals(p.join(tempDestDir.path, 'photo.png')));
    });
  });
}
