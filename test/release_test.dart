import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:backup_vault/core/database/app_database.dart';
import 'package:backup_vault/core/database/database_provider.dart';
import 'package:backup_vault/features/release/release_models.dart';
import 'package:backup_vault/features/release/release_repository.dart';
import 'package:backup_vault/features/release/release_provider.dart';
import 'package:backup_vault/features/release/version_manager.dart';
import 'package:backup_vault/features/release/release_validator.dart';
import 'package:backup_vault/features/release/portable_manager.dart';
import 'package:backup_vault/features/release/installer_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late ReleaseRepository repository;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('release_test_');
    repository = ReleaseRepository(storagePath: tempDir.path);
    await repository.init();
    db = AppDatabase(executor: NativeDatabase.memory());

    container = ProviderContainer(
      overrides: [
        releaseRepositoryProvider.overrideWithValue(repository),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('Release Models Serialization Tests', () {
    test('VersionInfo converts to and from JSON', () {
      const info = VersionInfo(major: 2, minor: 1, patch: 5, buildNumber: 22, releaseChannel: 'Beta');
      final jsonMap = info.toJson();
      expect(jsonMap['major'], equals(2));
      expect(jsonMap['releaseChannel'], equals('Beta'));

      final parsed = VersionInfo.fromJson(jsonMap);
      expect(parsed.major, equals(2));
      expect(parsed.semVer, equals('2.1.5+22'));
    });

    test('ReleaseManifest converts to and from JSON', () {
      final manifest = ReleaseManifest(
        version: '1.2.0',
        buildNumber: 4,
        releaseDate: DateTime.now(),
        platform: 'windows',
        architecture: 'x64',
        minimumWindowsVersion: '10.0.17763',
        flutterVersion: '3.12.2',
        dartVersion: '3.1.0',
        packageVersions: {'drift': '^2.34.0'},
        gitCommit: 'abc1234',
      );

      final jsonMap = manifest.toJson();
      expect(jsonMap['version'], equals('1.2.0'));
      expect(jsonMap['gitCommit'], equals('abc1234'));

      final parsed = ReleaseManifest.fromJson(jsonMap);
      expect(parsed.version, equals('1.2.0'));
      expect(parsed.packageVersions['drift'], equals('^2.34.0'));
    });
  });

  group('ReleaseRepository & History Tests', () {
    test('should persist version updates and compile records', () async {
      const info = VersionInfo(major: 1, minor: 5, patch: 0);
      await repository.saveVersionInfo(info);
      expect(repository.versionInfo.semVer, equals('1.5.0+1'));

      final result = BuildResult(
        profile: 'Portable',
        success: true,
        installerPath: '/out/setup.exe',
        portableZipPath: '/out/portable.zip',
        releaseZipPath: '/out/release.zip',
        sha256Checksum: 'abcdef',
        timestamp: DateTime.now(),
      );

      await repository.addBuildResult(result);
      expect(repository.history.length, equals(1));
      expect(repository.history.first.profile, equals('Portable'));
    });
  });

  group('VersionManager Semantic Increments Tests', () {
    test('should support Major, Minor, and Patch increments', () async {
      final vm = VersionManager(repository);
      expect(vm.currentVersion.semVer, equals('1.0.0+1'));

      // Minor increment
      var info = await vm.incrementMinor();
      expect(info.semVer, equals('1.1.0+2'));

      // Patch increment
      info = await vm.incrementPatch();
      expect(info.semVer, equals('1.1.1+3'));

      // Major increment
      info = await vm.incrementMajor();
      expect(info.semVer, equals('2.0.0+4'));
    });
  });

  group('ReleaseValidator Integration Tests', () {
    test('should perform compile validations and subsystem integration checks', () async {
      final validator = ReleaseValidator(container);
      
      final buildIssues = await validator.runBuildValidation();
      expect(buildIssues, isNotEmpty);
      expect(buildIssues.containsKey('SQLite Database'), isTrue);

      final releaseStatus = await validator.runReleaseValidation();
      expect(releaseStatus, isNotEmpty);
      // SQLite Schema check will pass on active in-memory db setup
      expect(releaseStatus.containsKey('Database Schema'), isTrue);
    });
  });

  group('PortableManager Platform Tests', () {
    test('should create lock flags and detect first execution', () async {
      final pm = PortableManager();
      
      // Test first run
      final firstRun = await pm.detectFirstRun();
      expect(firstRun, isNotNull);

      // Verify portable mode toggle
      await pm.setPortableMode(true);
      expect(await pm.isPortableMode(), isTrue);

      await pm.setPortableMode(false);
      expect(await pm.isPortableMode(), isFalse);
    });
  });

  group('InstallerManager Generation Tests', () {
    test('should generate Inno Setup script code and compile build exe packages', () async {
      final im = InstallerManager();
      
      final script = im.generateInnoSetupScript(
        appName: 'BackupVault',
        appVersion: '1.2.0',
        publisher: 'BackupVault Corp',
        sourcePath: '/build/win',
        outputPath: '/out',
        createDesktopIcon: true,
        runAtStartup: true,
      );

      expect(script.contains('AppName=BackupVault'), isTrue);
      expect(script.contains('AppVersion=1.2.0'), isTrue);

      final exePath = await im.buildInstaller(
        appVersion: '1.2.0',
        sourcePath: tempDir.path,
        outputPath: tempDir.path,
      );

      expect(File(exePath).existsSync(), isTrue);
    });
  });

  group('ReleaseManager Packaging Pipeline Tests', () {
    test('should compile and export complete release manifests, notes, and checksums', () async {
      final manager = container.read(releaseManagerProvider);

      final result = await manager.createRelease(
        profile: 'Release',
        features: ['Security upgrade'],
        bugFixes: ['Lock fixes'],
        migrations: ['None'],
        force: true,
      );

      expect(result.success, isTrue);
      expect(File(result.installerPath).existsSync(), isTrue);

      final outputDir = Directory(p.join(tempDir.path, 'release_output'));
      expect(outputDir.existsSync(), isTrue);

      // Verify manifest exists
      final manifestFile = File(p.join(outputDir.path, 'release_manifest.json'));
      expect(manifestFile.existsSync(), isTrue);

      // Verify release notes
      final notesFile = File(p.join(outputDir.path, 'RELEASE_NOTES.md'));
      expect(notesFile.existsSync(), isTrue);

      // Verify checksums file
      final checksumFile = File(p.join(outputDir.path, 'checksums.sha256'));
      expect(checksumFile.existsSync(), isTrue);
    });
  });
}
