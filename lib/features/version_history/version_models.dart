import 'package:backup_vault/core/database/app_database.dart';

class VersionDetail {
  final FileVersion version;
  final BackupFile parentFile;
  final BackupFolder folder;
  
  // File properties at version timestamp
  final DateTime modifiedAt;
  final DateTime createdAt; // Original file creation
  final String sha256;
  final int sizeBytes;
  final String backupWorker;
  final Duration backupDuration;
  final String verificationStatus; // 'verified', 'corrupt', 'unchecked', 'failed'
  final String? notes;

  const VersionDetail({
    required this.version,
    required this.parentFile,
    required this.folder,
    required this.modifiedAt,
    required this.createdAt,
    required this.sha256,
    required this.sizeBytes,
    required this.backupWorker,
    required this.backupDuration,
    required this.verificationStatus,
    this.notes,
  });

  VersionDetail copyWith({
    FileVersion? version,
    BackupFile? parentFile,
    BackupFolder? folder,
    DateTime? modifiedAt,
    DateTime? createdAt,
    String? sha256,
    int? sizeBytes,
    String? backupWorker,
    Duration? backupDuration,
    String? verificationStatus,
    String? notes,
  }) {
    return VersionDetail(
      version: version ?? this.version,
      parentFile: parentFile ?? this.parentFile,
      folder: folder ?? this.folder,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdAt: createdAt ?? this.createdAt,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      backupWorker: backupWorker ?? this.backupWorker,
      backupDuration: backupDuration ?? this.backupDuration,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      notes: notes ?? this.notes,
    );
  }
}

class VersionCompareResult {
  final VersionDetail versionA;
  final VersionDetail versionB;
  
  final bool sizeChanged;
  final bool shaChanged;
  final bool dateChanged;
  final bool modifiedDateChanged;
  final bool metadataChanged;

  const VersionCompareResult({
    required this.versionA,
    required this.versionB,
    required this.sizeChanged,
    required this.shaChanged,
    required this.dateChanged,
    required this.modifiedDateChanged,
    required this.metadataChanged,
  });
}

class VersionHistoryStats {
  final int totalVersions;
  final double averageVersionsPerFile;
  final int largestVersionChain;
  final String largestChainFileName;
  final Map<String, int> mostFrequentlyUpdatedFiles; // Map of file path to update count
  final int versionStorageUsageBytes;
  final int restoreFrequency;
  final double verificationSuccessRate;

  const VersionHistoryStats({
    required this.totalVersions,
    required this.averageVersionsPerFile,
    required this.largestVersionChain,
    required this.largestChainFileName,
    required this.mostFrequentlyUpdatedFiles,
    required this.versionStorageUsageBytes,
    required this.restoreFrequency,
    required this.verificationSuccessRate,
  });

  factory VersionHistoryStats.empty() {
    return const VersionHistoryStats(
      totalVersions: 0,
      averageVersionsPerFile: 0.0,
      largestVersionChain: 0,
      largestChainFileName: 'N/A',
      mostFrequentlyUpdatedFiles: {},
      versionStorageUsageBytes: 0,
      restoreFrequency: 0,
      verificationSuccessRate: 100.0,
    );
  }
}

enum VersionFilterType {
  all,
  latest,
  oldest,
  modified,
  restored,
  verified,
  failed,
}

class VersionHistoryFilter {
  final VersionFilterType type;
  final DateTimeRange? dateRange;
  final int? folderId;
  final String? searchPrefix;

  const VersionHistoryFilter({
    this.type = VersionFilterType.all,
    this.dateRange,
    this.folderId,
    this.searchPrefix,
  });

  VersionHistoryFilter copyWith({
    VersionFilterType? type,
    DateTimeRange? dateRange,
    int? folderId,
    String? searchPrefix,
  }) {
    return VersionHistoryFilter(
      type: type ?? this.type,
      dateRange: dateRange ?? this.dateRange,
      folderId: folderId ?? this.folderId,
      searchPrefix: searchPrefix ?? this.searchPrefix,
    );
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});
}
