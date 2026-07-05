import '../../core/database/app_database.dart';
import 'statistics_models.dart';

class StorageAnalyzer {
  /// Run analysis on database records and disk info to return StorageAnalysis
  static Future<StorageAnalysis> analyze({
    required List<BackupFolder> folders,
    required List<BackupFile> files,
    required List<BackupHistoryData> history,
    required int availableBytes,
    required int totalBytes,
  }) async {
    if (files.isEmpty) {
      return const StorageAnalysis();
    }

    // 1. Largest Files
    final sortedFiles = List<BackupFile>.from(files)
      ..sort((a, b) => b.fileSize.compareTo(a.fileSize));
    final largestFiles = sortedFiles.take(10).map((f) {
      return FileSizeInfo(
        name: f.fileName,
        path: f.originalPath,
        sizeBytes: f.fileSize,
      );
    }).toList();

    // 2. Largest Folders
    final Map<int, int> folderSizes = {};
    for (final file in files) {
      folderSizes[file.folderId] = (folderSizes[file.folderId] ?? 0) + file.fileSize;
    }

    final List<FolderSizeInfo> largestFolders = [];
    for (final folder in folders) {
      final size = folderSizes[folder.id] ?? 0;
      largestFolders.add(FolderSizeInfo(
        name: folder.name,
        path: folder.sourcePath,
        sizeBytes: size,
      ));
    }
    largestFolders.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    // 3. Most/Least Active Folders
    final Map<int, int> folderActivityCounts = {};
    for (final file in files) {
      folderActivityCounts[file.folderId] = (folderActivityCounts[file.folderId] ?? 0) + 1;
    }
    for (final run in history) {
      if (run.folderId != null) {
        folderActivityCounts[run.folderId!] = (folderActivityCounts[run.folderId!] ?? 0) + 2; // Weight runs higher
      }
    }

    int maxActivity = -1;
    int minActivity = 9999999;
    BackupFolder? mostActive;
    BackupFolder? leastActive;

    for (final folder in folders) {
      final activity = folderActivityCounts[folder.id] ?? 0;
      if (activity > maxActivity) {
        maxActivity = activity;
        mostActive = folder;
      }
      if (activity < minActivity) {
        minActivity = activity;
        leastActive = folder;
      }
    }

    final mostActiveName = mostActive != null ? '${mostActive.name} ($maxActivity events)' : 'N/A';
    final leastActiveName = leastActive != null ? '${leastActive.name} ($minActivity events)' : 'N/A';

    // 4. Duplicate Storage Saved
    final Map<String, List<BackupFile>> shaGroups = {};
    for (final f in files) {
      if (f.backupStatus == 'success') {
        shaGroups.putIfAbsent(f.sha256, () => []).add(f);
      }
    }

    int duplicateStorageSaved = 0;
    for (final group in shaGroups.values) {
      if (group.length > 1) {
        // If a file is backed up N times, N-1 are duplicates.
        // The space saved by deduplication (or just space occupied by duplicates)
        final singleSize = group.first.fileSize;
        duplicateStorageSaved += (group.length - 1) * singleSize;
      }
    }

    // 5. Estimated Future Storage (30 Days) & Remaining Days
    // We compute growth by comparing sizes over the last 14 days
    final now = DateTime.now();
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));
    
    final recentFiles = files.where((f) => f.createdAt.isAfter(fourteenDaysAgo)).toList();
    
    // Average daily growth = sum of recent files size / 14 (or days between oldest and newest file in this window)
    double dailyGrowthBytes = 0.0;
    if (recentFiles.isNotEmpty) {
      final totalRecentSize = recentFiles.fold<int>(0, (sum, f) => sum + f.fileSize);
      dailyGrowthBytes = totalRecentSize / 14.0;
    }

    final estimatedFutureGrowth30Days = (dailyGrowthBytes * 30).round();
    
    int estimatedRemainingDays = -1;
    bool isLowStorage = false;

    if (dailyGrowthBytes > 0) {
      estimatedRemainingDays = (availableBytes / dailyGrowthBytes).floor();
      if (estimatedRemainingDays < 30 || (availableBytes / (totalBytes > 0 ? totalBytes : 1) < 0.10)) {
        isLowStorage = true;
      }
    } else {
      // Check if available space is simply very low
      final freePercent = totalBytes > 0 ? (availableBytes / totalBytes) : 1.0;
      if (freePercent < 0.05) {
        isLowStorage = true;
        estimatedRemainingDays = 5; // Urgent warning
      }
    }

    return StorageAnalysis(
      largestFolders: largestFolders.take(5).toList(),
      largestFiles: largestFiles,
      mostActiveFolder: mostActiveName,
      leastActiveFolder: leastActiveName,
      duplicateStorageSavedBytes: duplicateStorageSaved,
      estimatedFutureStorageBytes30Days: estimatedFutureGrowth30Days,
      isLowStoragePredicted: isLowStorage,
      estimatedRemainingDays: estimatedRemainingDays,
    );
  }
}
