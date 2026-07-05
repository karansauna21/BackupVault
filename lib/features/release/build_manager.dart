import 'dart:io';
import 'package:path/path.dart' as p;
import 'release_models.dart';
import 'installer_manager.dart';
import 'portable_manager.dart';

class BuildManager {
  final InstallerManager installerManager = InstallerManager();
  final PortableManager portableManager = PortableManager();

  /// Execute packaging compile actions for a specific profile build
  Future<BuildResult> compileBuild({
    required String profile,
    required String version,
    required String outputPath,
  }) async {
    // Artificial build compilation delay
    await Future.delayed(const Duration(milliseconds: 1000));

    final sourcePath = p.join(outputPath, 'app_source');
    await Directory(sourcePath).create(recursive: true);

    // Build the installer
    final installerPath = await installerManager.buildInstaller(
      appVersion: version,
      sourcePath: sourcePath,
      outputPath: outputPath,
    );

    // Build the portable ZIP
    final portablePath = await portableManager.packagePortableZip(outputPath);

    // Generate release ZIP (simulated)
    final releaseZipFile = File(p.join(outputPath, 'BackupVault_Release_v$version.zip'));
    await releaseZipFile.writeAsString('BackupVault Standard Release Package.');

    return BuildResult(
      profile: profile,
      success: true,
      installerPath: installerPath,
      portableZipPath: portablePath,
      releaseZipPath: releaseZipFile.path,
      sha256Checksum: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', // SHA-256 of empty/mock
      timestamp: DateTime.now(),
    );
  }
}
