import 'release_models.dart';
import 'release_repository.dart';

class VersionManager {
  final ReleaseRepository repository;

  VersionManager(this.repository);

  VersionInfo get currentVersion => repository.versionInfo;

  /// Update active release channel setting
  Future<VersionInfo> updateChannel(String channel) async {
    final updated = repository.versionInfo.copyWith(releaseChannel: channel);
    await repository.saveVersionInfo(updated);
    return updated;
  }

  /// Increment the major version block
  Future<VersionInfo> incrementMajor() async {
    final updated = repository.versionInfo.copyWith(
      major: repository.versionInfo.major + 1,
      minor: 0,
      patch: 0,
      buildNumber: repository.versionInfo.buildNumber + 1,
    );
    await repository.saveVersionInfo(updated);
    return updated;
  }

  /// Increment the minor version block
  Future<VersionInfo> incrementMinor() async {
    final updated = repository.versionInfo.copyWith(
      minor: repository.versionInfo.minor + 1,
      patch: 0,
      buildNumber: repository.versionInfo.buildNumber + 1,
    );
    await repository.saveVersionInfo(updated);
    return updated;
  }

  /// Increment the patch version block
  Future<VersionInfo> incrementPatch() async {
    final updated = repository.versionInfo.copyWith(
      patch: repository.versionInfo.patch + 1,
      buildNumber: repository.versionInfo.buildNumber + 1,
    );
    await repository.saveVersionInfo(updated);
    return updated;
  }

  /// Manually update version info
  Future<VersionInfo> setVersion(int major, int minor, int patch, int build) async {
    final updated = VersionInfo(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: build,
      releaseChannel: repository.versionInfo.releaseChannel,
    );
    await repository.saveVersionInfo(updated);
    return updated;
  }
}
