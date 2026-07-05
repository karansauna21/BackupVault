class BackupState {
  final bool isBackingUp;
  final int currentFolderId;
  final String currentFolderName;
  final double progress; // 0.0 to 1.0
  final String currentStatusText;

  BackupState({
    this.isBackingUp = false,
    this.currentFolderId = -1,
    this.currentFolderName = '',
    this.progress = 0.0,
    this.currentStatusText = '',
  });

  BackupState copyWith({
    bool? isBackingUp,
    int? currentFolderId,
    String? currentFolderName,
    double? progress,
    String? currentStatusText,
  }) {
    return BackupState(
      isBackingUp: isBackingUp ?? this.isBackingUp,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      currentFolderName: currentFolderName ?? this.currentFolderName,
      progress: progress ?? this.progress,
      currentStatusText: currentStatusText ?? this.currentStatusText,
    );
  }
}
