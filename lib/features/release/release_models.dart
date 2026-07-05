class VersionInfo {
  final int major;
  final int minor;
  final int patch;
  final int buildNumber;
  final String releaseChannel; // Stable, Beta, Dev, Portable

  const VersionInfo({
    this.major = 1,
    this.minor = 0,
    this.patch = 0,
    this.buildNumber = 1,
    this.releaseChannel = 'Stable',
  });

  String get semVer => '$major.$minor.$patch+$buildNumber';
  String get displayString => '$major.$minor.$patch ($releaseChannel)';

  Map<String, dynamic> toJson() => {
    'major': major,
    'minor': minor,
    'patch': patch,
    'buildNumber': buildNumber,
    'releaseChannel': releaseChannel,
  };

  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
    major: json['major'] as int? ?? 1,
    minor: json['minor'] as int? ?? 0,
    patch: json['patch'] as int? ?? 0,
    buildNumber: json['buildNumber'] as int? ?? 1,
    releaseChannel: json['releaseChannel'] as String? ?? 'Stable',
  );

  VersionInfo copyWith({
    int? major,
    int? minor,
    int? patch,
    int? buildNumber,
    String? releaseChannel,
  }) => VersionInfo(
    major: major ?? this.major,
    minor: minor ?? this.minor,
    patch: patch ?? this.patch,
    buildNumber: buildNumber ?? this.buildNumber,
    releaseChannel: releaseChannel ?? this.releaseChannel,
  );
}

class ReleaseManifest {
  final String version;
  final int buildNumber;
  final DateTime releaseDate;
  final String platform;
  final String architecture;
  final String minimumWindowsVersion;
  final String flutterVersion;
  final String dartVersion;
  final Map<String, String> packageVersions;
  final String gitCommit;

  const ReleaseManifest({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.platform,
    required this.architecture,
    required this.minimumWindowsVersion,
    required this.flutterVersion,
    required this.dartVersion,
    required this.packageVersions,
    required this.gitCommit,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'buildNumber': buildNumber,
    'releaseDate': releaseDate.toIso8601String(),
    'platform': platform,
    'architecture': architecture,
    'minimumWindowsVersion': minimumWindowsVersion,
    'flutterVersion': flutterVersion,
    'dartVersion': dartVersion,
    'packageVersions': packageVersions,
    'gitCommit': gitCommit,
  };

  factory ReleaseManifest.fromJson(Map<String, dynamic> json) => ReleaseManifest(
    version: json['version'] ?? '1.0.0',
    buildNumber: json['buildNumber'] as int? ?? 1,
    releaseDate: DateTime.parse(json['releaseDate'] ?? DateTime.now().toIso8601String()),
    platform: json['platform'] ?? 'windows',
    architecture: json['architecture'] ?? 'x64',
    minimumWindowsVersion: json['minimumWindowsVersion'] ?? '10.0.17763',
    flutterVersion: json['flutterVersion'] ?? '3.12.2',
    dartVersion: json['dartVersion'] ?? '3.1.0',
    packageVersions: Map<String, String>.from(json['packageVersions'] ?? {}),
    gitCommit: json['gitCommit'] ?? 'unknown',
  );
}

class ReleaseNotes {
  final List<String> newFeatures;
  final List<String> bugFixes;
  final List<String> knownIssues;
  final List<String> migrationNotes;
  final List<String> breakingChanges;
  final List<String> upgradeGuide;

  const ReleaseNotes({
    required this.newFeatures,
    required this.bugFixes,
    required this.knownIssues,
    required this.migrationNotes,
    required this.breakingChanges,
    required this.upgradeGuide,
  });

  Map<String, dynamic> toJson() => {
    'newFeatures': newFeatures,
    'bugFixes': bugFixes,
    'knownIssues': knownIssues,
    'migrationNotes': migrationNotes,
    'breakingChanges': breakingChanges,
    'upgradeGuide': upgradeGuide,
  };

  factory ReleaseNotes.fromJson(Map<String, dynamic> json) => ReleaseNotes(
    newFeatures: List<String>.from(json['newFeatures'] ?? []),
    bugFixes: List<String>.from(json['bugFixes'] ?? []),
    knownIssues: List<String>.from(json['knownIssues'] ?? []),
    migrationNotes: List<String>.from(json['migrationNotes'] ?? []),
    breakingChanges: List<String>.from(json['breakingChanges'] ?? []),
    upgradeGuide: List<String>.from(json['upgradeGuide'] ?? []),
  );
}

class BuildResult {
  final String profile; // Debug, Profile, Release, Portable, Testing, Preview, Stable
  final bool success;
  final String installerPath;
  final String portableZipPath;
  final String releaseZipPath;
  final String sha256Checksum;
  final DateTime timestamp;

  const BuildResult({
    required this.profile,
    required this.success,
    required this.installerPath,
    required this.portableZipPath,
    required this.releaseZipPath,
    required this.sha256Checksum,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'profile': profile,
    'success': success,
    'installerPath': installerPath,
    'portableZipPath': portableZipPath,
    'releaseZipPath': releaseZipPath,
    'sha256Checksum': sha256Checksum,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BuildResult.fromJson(Map<String, dynamic> json) => BuildResult(
    profile: json['profile'] ?? 'Release',
    success: json['success'] as bool? ?? false,
    installerPath: json['installerPath'] ?? '',
    portableZipPath: json['portableZipPath'] ?? '',
    releaseZipPath: json['releaseZipPath'] ?? '',
    sha256Checksum: json['sha256Checksum'] ?? '',
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
  );
}
