import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:backup_vault/core/restore/conflict_resolver.dart';
import 'package:backup_vault/core/restore/integrity_verifier.dart';
import 'package:backup_vault/core/restore/path_resolver.dart';
import 'package:backup_vault/core/restore/restore_job.dart';
import 'package:backup_vault/core/restore/restore_queue.dart';
import 'package:backup_vault/core/restore/restore_validator.dart';
import 'package:backup_vault/core/restore/restore_manager.dart';
import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/core/repositories/backup_file_repository.dart';
import 'package:backup_vault/core/repositories/file_version_repository.dart';

class MockFileRepository implements BackupFileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<BackupFile>> getAllFiles() async {
    return [
      BackupFile(
        id: 1,
        folderId: 101,
        fileName: 'report.pdf',
        extension: '.pdf',
        originalPath: 'C:\\docs\\report.pdf',
        backupPath: 'D:\\backup\\report.pdf',
        fileSize: 2048,
        sha256: 'abcde12345',
        createdAt: DateTime(2026, 7, 4),
        modifiedAt: DateTime(2026, 7, 4),
        backupStatus: 'success',
      )
    ];
  }
}

class MockVersionRepository implements FileVersionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ConflictResolver Tests', () {
    late ConflictResolver resolver;
    late Directory tempDir;

    setUp(() async {
      resolver = ConflictResolver();
      tempDir = await Directory.systemTemp.createTemp('conflict_test');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('Returns original path when file does not exist', () {
      final target = p.join(tempDir.path, 'photo.jpg');
      expect(resolver.resolveConflict(target), equals(target));
    });

    test('Appends unique sequence suffix if file exists', () async {
      final target = p.join(tempDir.path, 'photo.jpg');
      await File(target).writeAsString('original');

      final resolved = resolver.resolveConflict(target);
      expect(resolved, equals(p.join(tempDir.path, 'photo_(restored_1).jpg')));

      await File(resolved).writeAsString('restored_1');
      final resolved2 = resolver.resolveConflict(target);
      expect(resolved2, equals(p.join(tempDir.path, 'photo_(restored_2).jpg')));
    });
  });

  group('IntegrityVerifier Tests', () {
    late IntegrityVerifier verifier;
    late Directory tempDir;

    setUp(() async {
      verifier = IntegrityVerifier();
      tempDir = await Directory.systemTemp.createTemp('integrity_test');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('Calculates and verifies SHA-256 correctly', () async {
      final file = File(p.join(tempDir.path, 'test.txt'));
      await file.writeAsString('hello world');

      final hash = await verifier.calculateSha256(file);
      expect(hash.isNotEmpty, isTrue);

      final isValid = await verifier.verifyFileIntegrity(file, hash);
      expect(isValid, isTrue);

      final isInvalid = await verifier.verifyFileIntegrity(file, 'wronghash');
      expect(isInvalid, isFalse);
    });
  });

  group('RestoreValidator Tests', () {
    late RestoreValidator validator;
    late Directory tempDir;

    setUp(() async {
      validator = RestoreValidator();
      tempDir = await Directory.systemTemp.createTemp('validator_test');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('Validates source existence', () async {
      final path = p.join(tempDir.path, 'missing.txt');
      expect(await validator.validateSource(path), isFalse);

      final file = File(p.join(tempDir.path, 'exists.txt'));
      await file.writeAsString('content');
      expect(await validator.validateSource(file.path), isTrue);
    });

    test('Validates destination write access', () async {
      final path = p.join(tempDir.path, 'target_folder', 'file.txt');
      expect(await validator.validateDestination(path), isTrue);
    });
  });

  group('PathResolver Tests', () {
    late PathResolver pathResolver;

    setUp(() {
      pathResolver = PathResolver();
    });

    test('Resolves correct path for original option', () {
      final res = pathResolver.resolveTargetRestorePath(
        originalPath: 'C:\\data\\file.txt',
        destinationOption: 'original',
      );
      expect(res, equals('C:\\data\\file.txt'));
    });

    test('Resolves correct path for custom option', () {
      final res = pathResolver.resolveTargetRestorePath(
        originalPath: 'C:\\data\\file.txt',
        destinationOption: 'custom',
        customFolderPath: 'D:\\restored_data',
      );
      expect(res, equals('D:\\restored_data\\file.txt'));
    });
  });

  group('RestoreManager Search Tests', () {
    late RestoreManager manager;

    setUp(() {
      manager = RestoreManager(
        fileRepository: MockFileRepository(),
        versionRepository: MockVersionRepository(),
      );
    });

    test('Searches by filename query successfully', () async {
      final results = await manager.searchBackupFiles(filename: 'report');
      expect(results.length, equals(1));
      expect(results.first.fileName, equals('report.pdf'));

      final emptyResults = await manager.searchBackupFiles(filename: 'missing');
      expect(emptyResults, isEmpty);
    });
  });

  group('RestoreQueue Tests', () {
    test('Can queue and control jobs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(restoreQueueProvider.notifier);

      final job = RestoreJob(
        id: '1',
        fileId: 10,
        sourceBackupPath: 'backup/path',
        targetRestorePath: 'restore/path',
        fileSize: 100,
        versionNumber: 1,
        sha256: 'hash',
      );

      notifier.addJob(job);
      expect(container.read(restoreQueueProvider).length, equals(1));
      expect(container.read(restoreQueueProvider).first.status, equals(RestoreStatus.pending));

      notifier.pauseJob('1');
      expect(container.read(restoreQueueProvider).first.status, equals(RestoreStatus.paused));

      notifier.resumeJob('1');
      expect(container.read(restoreQueueProvider).first.status, equals(RestoreStatus.pending));

      notifier.cancelJob('1');
      expect(container.read(restoreQueueProvider).first.status, equals(RestoreStatus.canceled));
    });
  });
}
