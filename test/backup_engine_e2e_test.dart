// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/core/database/database_provider.dart';
import 'package:backup_vault/features/backup/presentation/view_models/backup_view_model.dart';

void main() {
  group('Backup Engine End-to-End Integration Test', () {
    late Directory tempSourceDir;
    late Directory tempDestDir;
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      // 1. Create temporary source and destination directories
      tempSourceDir = await Directory.systemTemp.createTemp('backup_e2e_source');
      tempDestDir = await Directory.systemTemp.createTemp('backup_e2e_dest');

      // 2. Write test files representing realistic project structures
      await File(p.join(tempSourceDir.path, 'root_file.txt')).writeAsString('Root file contents');
      
      final subDir = Directory(p.join(tempSourceDir.path, 'documents'));
      await subDir.create();
      await File(p.join(subDir.path, 'notes.md')).writeAsString('# Notes\nThis is a markdown note.');

      final nestedDir = Directory(p.join(subDir.path, 'project', 'src'));
      await nestedDir.create(recursive: true);
      await File(p.join(nestedDir.path, 'main.dart')).writeAsString('void main() { print("E2E Test"); }');

      // 3. Set up in-memory SQLite database
      db = AppDatabase(executor: NativeDatabase.memory());

      // 4. Set up Riverpod container with database override
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      
      // Clean up physical directories
      try {
        await tempSourceDir.delete(recursive: true);
      } catch (_) {}
      try {
        await tempDestDir.delete(recursive: true);
      } catch (_) {}
    });

    test('Run backup e2e and generate report', () async {
      final startTime = DateTime.now();

      // 1. Register the folder in SQLite database
      final folderCompanion = BackupFoldersCompanion.insert(
        name: 'My Workspace',
        sourcePath: tempSourceDir.path,
        destinationPath: tempDestDir.path,
        enabled: const Value(true),
      );
      final folderId = await db.into(db.backupFolders).insert(folderCompanion);
      
      final folderList = await db.select(db.backupFolders).get();
      expect(folderList.length, equals(1));
      final folder = folderList.first;

      // 2. Perform the backup via BackupNotifier (starts full scanning and real-time execution)
      final notifier = container.read(backupProvider.notifier);
      await notifier.runBackup(folder);

      // 3. Measure duration
      final duration = DateTime.now().difference(startTime);

      // 4. Verify physical file copy and hierarchy preservation
      final rootCopied = File(p.join(tempDestDir.path, 'root_file.txt'));
      final notesCopied = File(p.join(tempDestDir.path, 'documents', 'notes.md'));
      final mainCopied = File(p.join(tempDestDir.path, 'documents', 'project', 'src', 'main.dart'));

      expect(await rootCopied.exists(), isTrue);
      expect(await notesCopied.exists(), isTrue);
      expect(await mainCopied.exists(), isTrue);

      expect(await rootCopied.readAsString(), equals('Root file contents'));
      expect(await notesCopied.readAsString(), equals('# Notes\nThis is a markdown note.'));
      expect(await mainCopied.readAsString(), equals('void main() { print("E2E Test"); }'));

      // 5. Verify database records
      final files = await db.select(db.backupFiles).get();
      expect(files.length, equals(3));

      for (final f in files) {
        expect(f.backupStatus, equals('success'));
        expect(f.folderId, equals(folderId));
        expect(File(f.backupPath).existsSync(), isTrue);
      }

      final history = await db.select(db.backupHistory).get();
      expect(history.length, equals(1));
      expect(history.first.status, equals('success'));
      expect(history.first.filesCount, equals(3));
      
      final totalBackupSize = history.first.totalSize;

      // 6. Generate the structured E2E performance report
      print('\n=========================================');
      print('     BACKUP VAULT END-TO-END REPORT      ');
      print('=========================================');
      print('- Files Found      : 3');
      print('- Files Copied     : ${history.first.filesCount}');
      print('- Files Failed     : 0');
      print('- Backup Size      : $totalBackupSize bytes (${(totalBackupSize / 1024).toStringAsFixed(2)} KB)');
      print('- Destination Path : ${folder.destinationPath}');
      print('- Execution Time   : ${duration.inMilliseconds} ms');
      print('=========================================\n');
    });
  });
}
