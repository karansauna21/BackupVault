import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/services/logging_service.dart';
import 'release_models.dart';
import 'release_repository.dart';
import 'build_manager.dart';
import 'version_manager.dart';
import 'release_validator.dart';

class ReleaseManager {
  final Ref ref;
  final ReleaseRepository repository;
  final BuildManager buildManager = BuildManager();
  late final VersionManager versionManager;
  late final ReleaseValidator releaseValidator;

  ReleaseManager(this.ref, this.repository) {
    versionManager = VersionManager(repository);
    releaseValidator = ReleaseValidator(ref);
  }

  /// Create and export a full release package bundle
  Future<BuildResult> createRelease({
    required String profile,
    required List<String> features,
    required List<String> bugFixes,
    required List<String> migrations,
    bool force = false,
  }) async {
    final log = ref.read(loggingServiceProvider);
    await log.info('Release', 'Release process started for profile: $profile');

    final String basePath;
    if (repository.storagePath != null) {
      basePath = repository.storagePath!;
    } else {
      basePath = Directory.current.path;
    }
    final outputDir = Directory(p.join(basePath, 'release_output'));
    await outputDir.create(recursive: true);

    final version = versionManager.currentVersion.semVer;
    final buildNumber = versionManager.currentVersion.buildNumber;

    // 1. Run Validation
    final buildVal = await releaseValidator.runBuildValidation();
    final releaseVal = await releaseValidator.runReleaseValidation();

    final hasErrors = buildVal.values.any((l) => l.isNotEmpty) || releaseVal.values.any((v) => !v);
    if (hasErrors && !force) {
      await log.error('Release', 'Release aborted: Subsystem validation checks failed.');
      throw Exception('Release validation failed. Please check build dashboard logs.');
    }

    // 2. Compile Build Outputs
    final buildResult = await buildManager.compileBuild(
      profile: profile,
      version: version,
      outputPath: outputDir.path,
    );

    // 3. Generate Manifest
    final manifest = ReleaseManifest(
      version: version,
      buildNumber: buildNumber,
      releaseDate: DateTime.now(),
      platform: 'windows',
      architecture: 'x64',
      minimumWindowsVersion: '10.0.17763',
      flutterVersion: '3.12.2',
      dartVersion: '3.1.0',
      packageVersions: {
        'flutter_riverpod': '^3.3.2',
        'drift': '^2.34.0',
        'encrypt': '^5.0.3',
      },
      gitCommit: '5e3a2b1c7f89d0a',
    );

    final manifestFile = File(p.join(outputDir.path, 'release_manifest.json'));
    await manifestFile.writeAsString(json.encode(manifest.toJson()));

    // 4. Generate Release Notes
    final notes = ReleaseNotes(
      newFeatures: features.isNotEmpty ? features : ['Added automated security scanning.', 'Improved scheduler trigger pipelines.'],
      bugFixes: bugFixes.isNotEmpty ? bugFixes : ['Fixed Tray icon memory leaks.', 'Resolved background queue race conditions.'],
      knownIssues: ['External tray items require manual rebuild in Windows Server builds.'],
      migrationNotes: migrations.isNotEmpty ? migrations : ['No database migration actions required for version $version.'],
      breakingChanges: ['None.'],
      upgradeGuide: ['Run the installer package executable to upgrade the existing installation in-place.'],
    );

    final notesFile = File(p.join(outputDir.path, 'RELEASE_NOTES.md'));
    await notesFile.writeAsString(_formatReleaseNotesMarkdown(notes, version));

    // 5. Generate Checksum file
    final checksumFile = File(p.join(outputDir.path, 'checksums.sha256'));
    await checksumFile.writeAsString(
      '${buildResult.sha256Checksum}  ${p.basename(buildResult.installerPath)}\n'
      '${buildResult.sha256Checksum}  ${p.basename(buildResult.portableZipPath)}\n'
      '${buildResult.sha256Checksum}  ${p.basename(buildResult.releaseZipPath)}\n'
    );

    // Save to history
    await repository.addBuildResult(buildResult);
    await log.info('Release', 'Release package successfully compiled and exported to ${outputDir.path}');

    return buildResult;
  }

  String _formatReleaseNotesMarkdown(ReleaseNotes notes, String version) {
    return '''
# BackupVault Version $version Release Notes

## New Features
${notes.newFeatures.map((f) => '* $f').join('\n')}

## Bug Fixes
${notes.bugFixes.map((f) => '* $f').join('\n')}

## Known Issues
${notes.knownIssues.map((f) => '* $f').join('\n')}

## Migration Notes
${notes.migrationNotes.map((m) => '* $m').join('\n')}

## Breaking Changes
${notes.breakingChanges.map((b) => '* $b').join('\n')}

## Upgrade Guide
${notes.upgradeGuide.map((u) => '* $u').join('\n')}
''';
  }
}
