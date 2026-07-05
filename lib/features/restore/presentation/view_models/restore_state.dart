class RestoreState {
  final bool isRestoring;
  final int currentHistoryId;
  final double progress; // 0.0 to 1.0
  final String statusText;

  RestoreState({
    this.isRestoring = false,
    this.currentHistoryId = -1,
    this.progress = 0.0,
    this.statusText = '',
  });

  RestoreState copyWith({
    bool? isRestoring,
    int? currentHistoryId,
    double? progress,
    String? statusText,
  }) {
    return RestoreState(
      isRestoring: isRestoring ?? this.isRestoring,
      currentHistoryId: currentHistoryId ?? this.currentHistoryId,
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
    );
  }
}
