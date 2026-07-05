import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import 'statistics_models.dart';

class HealthAnalyzer {
  static Future<BackupHealth> analyze({
    required List<BackupFolder> folders,
    required List<BackupFile> files,
    required List<BackupHistoryData> history,
    required List<BackupLog> logs,
    required int availableBytes,
    required int totalBytes,
    required bool isVersioningEnabled,
  }) async {
    int score = 100;
    final Map<String, int> scoreFactors = {
      'Failed Jobs': 100,
      'Verification Success': 100,
      'Storage Availability': 100,
      'Folder Status': 100,
      'Watcher Status': 100,
      'Database Health': 100,
      'Recent Errors': 100,
      'Versioning Status': 100,
    };

    final List<HealthRecommendation> recommendations = [];

    // 1. Failed Jobs (History)
    final recentHistory = history.where((h) => h.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    if (recentHistory.isNotEmpty) {
      final failedCount = recentHistory.where((h) => h.status == 'failed').length;
      final deduction = (failedCount * 15).clamp(0, 40);
      scoreFactors['Failed Jobs'] = 100 - deduction;
      score -= deduction;
      
      if (failedCount > 0) {
        recommendations.add(HealthRecommendation(
          title: 'Resolve Failed Backup Jobs',
          description: '$failedCount backup runs failed recently. Check error logs for specific file access permissions or network issues.',
          severity: 'high',
          icon: Icons.error_outline_rounded,
        ));
      }
    }

    // 2. Verification Success (Logs check)
    final verificationFailures = logs.where((l) => l.logType == 'error' && l.message.toLowerCase().contains('verification')).length;
    if (verificationFailures > 0) {
      final deduction = (verificationFailures * 10).clamp(0, 30);
      scoreFactors['Verification Success'] = 100 - deduction;
      score -= deduction;
      
      recommendations.add(HealthRecommendation(
        title: 'Integrity Verification Failures',
        description: 'Detected $verificationFailures hash check failures. Re-run integrity checks on these folders to ensure zero data corruption.',
        severity: 'high',
        icon: Icons.verified_user_sharp,
      ));
    }

    // 3. Storage Availability
    final freeSpacePercent = totalBytes > 0 ? (availableBytes / totalBytes) : 1.0;
    if (freeSpacePercent < 0.10) {
      final deduction = freeSpacePercent < 0.05 ? 40 : 20;
      scoreFactors['Storage Availability'] = 100 - deduction;
      score -= deduction;
      
      recommendations.add(HealthRecommendation(
        title: 'Critically Low Storage Space',
        description: 'Backup destination drive has less than ${(freeSpacePercent * 100).toStringAsFixed(1)}% space left. Please clear space or switch storage.',
        severity: 'high',
        icon: Icons.storage_rounded,
      ));
    } else if (freeSpacePercent < 0.20) {
      scoreFactors['Storage Availability'] = 85;
      score -= 15;
      
      recommendations.add(HealthRecommendation(
        title: 'Storage Space Warning',
        description: 'Less than 20% available space remains on your destination storage.',
        severity: 'medium',
        icon: Icons.storage_rounded,
      ));
    }

    // 4. Folder Status (Check if offline/missing source path)
    int offlineFolders = 0;
    for (final folder in folders) {
      if (folder.enabled) {
        final dir = Directory(folder.sourcePath);
        if (!dir.existsSync()) {
          offlineFolders++;
        }
      }
    }
    if (offlineFolders > 0) {
      final deduction = (offlineFolders * 20).clamp(0, 50);
      scoreFactors['Folder Status'] = 100 - deduction;
      score -= deduction;
      
      recommendations.add(HealthRecommendation(
        title: 'Source Folder Offline',
        description: '$offlineFolders monitored source folder paths do not exist or are offline. Verify external drive or network connection.',
        severity: 'high',
        icon: Icons.folder_off_outlined,
      ));
    }

    // 5. Watcher Status
    final watcherErrors = logs.where((l) => l.message.toLowerCase().contains('watcher') && l.logType == 'error').length;
    if (watcherErrors > 0) {
      final deduction = (watcherErrors * 10).clamp(0, 30);
      scoreFactors['Watcher Status'] = 100 - deduction;
      score -= deduction;
      
      recommendations.add(HealthRecommendation(
        title: 'Restart Stopped Watchers',
        description: 'Real-time folder watcher reported errors. Toggle folder monitoring to refresh watchers.',
        severity: 'medium',
        icon: Icons.track_changes_rounded,
      ));
    }

    // 6. Database Health
    final dbErrors = logs.where((l) => l.message.toLowerCase().contains('database') && l.logType == 'error').length;
    if (dbErrors > 0) {
      final deduction = (dbErrors * 15).clamp(0, 40);
      scoreFactors['Database Health'] = 100 - deduction;
      score -= deduction;
      
      recommendations.add(HealthRecommendation(
        title: 'Perform Database Maintenance',
        description: 'Drift SQLite engine logged $dbErrors exceptions. Run database compaction (Vacuum) to repair fragmentation.',
        severity: 'high',
        icon: Icons.settings_suggest_rounded,
      ));
    }

    // 7. Recent Errors (within 24 hours)
    final recentErrors = logs
        .where((l) => l.logType == 'error' && l.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24))))
        .length;
    if (recentErrors > 0) {
      final deduction = (recentErrors * 5).clamp(0, 25);
      scoreFactors['Recent Errors'] = 100 - deduction;
      score -= deduction;
      
      recommendations.add(HealthRecommendation(
        title: 'Inspect Recent Application Errors',
        description: 'BackupVault encountered $recentErrors errors in the past 24 hours. Review Log Inspector for details.',
        severity: 'medium',
        icon: Icons.bug_report_outlined,
      ));
    }

    // 8. Versioning Status
    if (!isVersioningEnabled) {
      scoreFactors['Versioning Status'] = 70;
      score -= 10;
      
      recommendations.add(HealthRecommendation(
        title: 'Enable File Versioning',
        description: 'File versioning is currently disabled in Settings. Enable it to protect against accidental file modifications/overwrites.',
        severity: 'low',
        icon: Icons.history_rounded,
      ));
    }

    score = score.clamp(0, 100);

    return BackupHealth(
      score: score,
      scoreFactors: scoreFactors,
      recommendations: recommendations,
    );
  }
}
