
class StatisticsState {
  final int totalAttempts;
  final int successCount;
  final int failureCount;
  final double averageSizeMb;
  final Map<String, int> folderSizeDistribution; // Folder Name -> Size in bytes
  final Map<String, int> folderFileCountDistribution; // Folder Name -> File Count
  final bool isLoading;

  StatisticsState({
    required this.totalAttempts,
    required this.successCount,
    required this.failureCount,
    required this.averageSizeMb,
    required this.folderSizeDistribution,
    required this.folderFileCountDistribution,
    this.isLoading = false,
  });

  factory StatisticsState.initial() {
    return StatisticsState(
      totalAttempts: 0,
      successCount: 0,
      failureCount: 0,
      averageSizeMb: 0.0,
      folderSizeDistribution: {},
      folderFileCountDistribution: {},
      isLoading: false,
    );
  }

  StatisticsState copyWith({
    int? totalAttempts,
    int? successCount,
    int? failureCount,
    double? averageSizeMb,
    Map<String, int>? folderSizeDistribution,
    Map<String, int>? folderFileCountDistribution,
    bool? isLoading,
  }) {
    return StatisticsState(
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      averageSizeMb: averageSizeMb ?? this.averageSizeMb,
      folderSizeDistribution: folderSizeDistribution ?? this.folderSizeDistribution,
      folderFileCountDistribution: folderFileCountDistribution ?? this.folderFileCountDistribution,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
