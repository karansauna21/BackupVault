import 'version_models.dart';

class VersionComparer {
  /// Compare two file versions to detect changes in size, hashes, mod times, and metadata
  static VersionCompareResult compare(VersionDetail versionA, VersionDetail versionB) {
    return VersionCompareResult(
      versionA: versionA,
      versionB: versionB,
      sizeChanged: versionA.sizeBytes != versionB.sizeBytes,
      shaChanged: versionA.sha256 != versionB.sha256,
      dateChanged: versionA.version.createdAt != versionB.version.createdAt,
      modifiedDateChanged: versionA.modifiedAt != versionB.modifiedAt,
      metadataChanged: versionA.backupWorker != versionB.backupWorker ||
          versionA.verificationStatus != versionB.verificationStatus,
    );
  }
}
