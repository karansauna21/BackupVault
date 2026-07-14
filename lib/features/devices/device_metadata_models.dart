class DeviceFolderMetadata {
  final String folderName;
  final String folderPath;
  final String folderType; // e.g. "Sync", "Backup", "Archive"
  final int totalFiles;
  final int folderSize; // in bytes
  final DateTime lastModified;
  final String syncStatus; // "Synced", "Pending", "Missing", "Not Backed Up"
  final String localDetails; // Compare details
  final String remoteDetails; // Compare details

  const DeviceFolderMetadata({
    required this.folderName,
    required this.folderPath,
    required this.folderType,
    required this.totalFiles,
    required this.folderSize,
    required this.lastModified,
    required this.syncStatus,
    required this.localDetails,
    required this.remoteDetails,
  });

  DeviceFolderMetadata copyWith({
    String? folderName,
    String? folderPath,
    String? folderType,
    int? totalFiles,
    int? folderSize,
    DateTime? lastModified,
    String? syncStatus,
    String? localDetails,
    String? remoteDetails,
  }) {
    return DeviceFolderMetadata(
      folderName: folderName ?? this.folderName,
      folderPath: folderPath ?? this.folderPath,
      folderType: folderType ?? this.folderType,
      totalFiles: totalFiles ?? this.totalFiles,
      folderSize: folderSize ?? this.folderSize,
      lastModified: lastModified ?? this.lastModified,
      syncStatus: syncStatus ?? this.syncStatus,
      localDetails: localDetails ?? this.localDetails,
      remoteDetails: remoteDetails ?? this.remoteDetails,
    );
  }
}

class DeviceFileMetadata {
  final String filename;
  final String extension;
  final String relativePath;
  final int fileSize;
  final String sha256;
  final DateTime modifiedDate;
  final DateTime createdDate;
  final int version;
  final String backupStatus; // "Already Synced", "New File", "Modified", "Missing", "Skipped"

  const DeviceFileMetadata({
    required this.filename,
    required this.extension,
    required this.relativePath,
    required this.fileSize,
    required this.sha256,
    required this.modifiedDate,
    required this.createdDate,
    required this.version,
    required this.backupStatus,
  });

  DeviceFileMetadata copyWith({
    String? filename,
    String? extension,
    String? relativePath,
    int? fileSize,
    String? sha256,
    DateTime? modifiedDate,
    DateTime? createdDate,
    int? version,
    String? backupStatus,
  }) {
    return DeviceFileMetadata(
      filename: filename ?? this.filename,
      extension: extension ?? this.extension,
      relativePath: relativePath ?? this.relativePath,
      fileSize: fileSize ?? this.fileSize,
      sha256: sha256 ?? this.sha256,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      createdDate: createdDate ?? this.createdDate,
      version: version ?? this.version,
      backupStatus: backupStatus ?? this.backupStatus,
    );
  }
}
