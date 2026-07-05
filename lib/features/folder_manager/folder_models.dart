class FolderRules {
  final List<String> includeExtensions;
  final List<String> excludeExtensions;
  final bool includeHidden;
  final bool ignoreTemp;
  final bool ignoreSystem;
  final bool ignoreEmpty;
  final int? minSize; // in bytes
  final int? maxSize; // in bytes
  final int? maxDepth;
  final int? maxFileCount;

  const FolderRules({
    this.includeExtensions = const [],
    this.excludeExtensions = const [],
    this.includeHidden = false,
    this.ignoreTemp = true,
    this.ignoreSystem = true,
    this.ignoreEmpty = false,
    this.minSize,
    this.maxSize,
    this.maxDepth = 10,
    this.maxFileCount = 50000,
  });

  FolderRules copyWith({
    List<String>? includeExtensions,
    List<String>? excludeExtensions,
    bool? includeHidden,
    bool? ignoreTemp,
    bool? ignoreSystem,
    bool? ignoreEmpty,
    int? minSize,
    int? maxSize,
    int? maxDepth,
    int? maxFileCount,
  }) {
    return FolderRules(
      includeExtensions: includeExtensions ?? this.includeExtensions,
      excludeExtensions: excludeExtensions ?? this.excludeExtensions,
      includeHidden: includeHidden ?? this.includeHidden,
      ignoreTemp: ignoreTemp ?? this.ignoreTemp,
      ignoreSystem: ignoreSystem ?? this.ignoreSystem,
      ignoreEmpty: ignoreEmpty ?? this.ignoreEmpty,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      maxDepth: maxDepth ?? this.maxDepth,
      maxFileCount: maxFileCount ?? this.maxFileCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeExtensions': includeExtensions,
      'excludeExtensions': excludeExtensions,
      'includeHidden': includeHidden,
      'ignoreTemp': ignoreTemp,
      'ignoreSystem': ignoreSystem,
      'ignoreEmpty': ignoreEmpty,
      'minSize': minSize,
      'maxSize': maxSize,
      'maxDepth': maxDepth,
      'maxFileCount': maxFileCount,
    };
  }

  factory FolderRules.fromJson(Map<String, dynamic> json) {
    return FolderRules(
      includeExtensions: List<String>.from(
        json['includeExtensions'] ?? const [],
      ),
      excludeExtensions: List<String>.from(
        json['excludeExtensions'] ?? const [],
      ),
      includeHidden: json['includeHidden'] ?? false,
      ignoreTemp: json['ignoreTemp'] ?? true,
      ignoreSystem: json['ignoreSystem'] ?? true,
      ignoreEmpty: json['ignoreEmpty'] ?? false,
      minSize: json['minSize'],
      maxSize: json['maxSize'],
      maxDepth: json['maxDepth'] ?? 10,
      maxFileCount: json['maxFileCount'] ?? 50000,
    );
  }
}

class FolderHealthScore {
  final int score; // 0 to 100
  final bool isReadable;
  final bool isWritable;
  final bool pathExists;
  final bool diskSpaceAvailable;
  final List<String> warnings;

  const FolderHealthScore({
    required this.score,
    required this.isReadable,
    required this.isWritable,
    required this.pathExists,
    required this.diskSpaceAvailable,
    required this.warnings,
  });

  factory FolderHealthScore.perfect() {
    return const FolderHealthScore(
      score: 100,
      isReadable: true,
      isWritable: true,
      pathExists: true,
      diskSpaceAvailable: true,
      warnings: [],
    );
  }

  factory FolderHealthScore.failed(List<String> warnings) {
    return FolderHealthScore(
      score: 0,
      isReadable: false,
      isWritable: false,
      pathExists: false,
      diskSpaceAvailable: false,
      warnings: warnings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'isReadable': isReadable,
      'isWritable': isWritable,
      'pathExists': pathExists,
      'diskSpaceAvailable': diskSpaceAvailable,
      'warnings': warnings,
    };
  }

  factory FolderHealthScore.fromJson(Map<String, dynamic> json) {
    return FolderHealthScore(
      score: json['score'] ?? 0,
      isReadable: json['isReadable'] ?? false,
      isWritable: json['isWritable'] ?? false,
      pathExists: json['pathExists'] ?? false,
      diskSpaceAvailable: json['diskSpaceAvailable'] ?? false,
      warnings: List<String>.from(json['warnings'] ?? const []),
    );
  }
}

class FolderStats {
  final int folderId;
  final int fileCount;
  final int totalSize; // in bytes
  final DateTime? lastScanTime;
  final String watcherStatus; // active, paused, idle, error
  final String backupStatus; // idle, backing_up, failed, success
  final FolderHealthScore health;
  final FolderRules rules;

  const FolderStats({
    required this.folderId,
    this.fileCount = 0,
    this.totalSize = 0,
    this.lastScanTime,
    this.watcherStatus = 'idle',
    this.backupStatus = 'idle',
    this.health = const FolderHealthScore(
      score: 100,
      isReadable: true,
      isWritable: true,
      pathExists: true,
      diskSpaceAvailable: true,
      warnings: [],
    ),
    this.rules = const FolderRules(),
  });

  FolderStats copyWith({
    int? fileCount,
    int? totalSize,
    DateTime? lastScanTime,
    String? watcherStatus,
    String? backupStatus,
    FolderHealthScore? health,
    FolderRules? rules,
  }) {
    return FolderStats(
      folderId: folderId,
      fileCount: fileCount ?? this.fileCount,
      totalSize: totalSize ?? this.totalSize,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      watcherStatus: watcherStatus ?? this.watcherStatus,
      backupStatus: backupStatus ?? this.backupStatus,
      health: health ?? this.health,
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderId': folderId,
      'fileCount': fileCount,
      'totalSize': totalSize,
      'lastScanTime': lastScanTime?.toIso8601String(),
      'watcherStatus': watcherStatus,
      'backupStatus': backupStatus,
      'health': health.toJson(),
      'rules': rules.toJson(),
    };
  }

  factory FolderStats.fromJson(Map<String, dynamic> json) {
    return FolderStats(
      folderId: json['folderId'] ?? 0,
      fileCount: json['fileCount'] ?? 0,
      totalSize: json['totalSize'] ?? 0,
      lastScanTime: json['lastScanTime'] != null
          ? DateTime.parse(json['lastScanTime'])
          : null,
      watcherStatus: json['watcherStatus'] ?? 'idle',
      backupStatus: json['backupStatus'] ?? 'idle',
      health: FolderHealthScore.fromJson(json['health'] ?? {}),
      rules: FolderRules.fromJson(json['rules'] ?? {}),
    );
  }
}
