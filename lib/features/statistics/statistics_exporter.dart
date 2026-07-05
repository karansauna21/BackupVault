import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'statistics_models.dart';

class StatisticsExporter {
  /// Exports statistics report to a file.
  /// Returns the absolute path of the generated file.
  static Future<String> exportReport({
    required BackupStats stats,
    required StorageAnalysis storage,
    required PerformanceAnalysis performance,
    required BackupHealth health,
    required String format,
    required String targetDirectory,
    String? customFileName,
  }) async {
    final dir = Directory(targetDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final baseName = customFileName ?? 'backupvault_analytics_$dateStr';
    
    String content = '';
    String fileExt = '';

    switch (format.toLowerCase()) {
      case 'csv':
        fileExt = '.csv';
        content = _generateCsv(stats, storage, performance, health);
        break;
      case 'json':
        fileExt = '.json';
        content = _generateJson(stats, storage, performance, health);
        break;
      case 'pdf':
      case 'html':
      default:
        fileExt = '.html'; // HTML/PDF printable report
        content = _generatePrintableHtml(stats, storage, performance, health);
        break;
    }

    final String exportFilePath = p.join(targetDirectory, '$baseName$fileExt');
    final File exportFile = File(exportFilePath);
    await exportFile.writeAsString(content);

    return exportFilePath;
  }

  static String _generateJson(
    BackupStats stats,
    StorageAnalysis storage,
    PerformanceAnalysis performance,
    BackupHealth health,
  ) {
    final report = {
      'generatedAt': DateTime.now().toIso8601String(),
      'systemInfo': {
        'appName': 'BackupVault',
        'reportType': 'Backup Statistics & Analytics Report',
      },
      'overallMetrics': {
        'totalBackupSizeBytes': stats.totalBackupSize,
        'todaysBackupSizeBytes': stats.todaysBackupSize,
        'weeklyBackupSizeBytes': stats.weeklyBackupSize,
        'monthlyBackupSizeBytes': stats.monthlyBackupSize,
        'totalFilesCount': stats.totalFiles,
        'backedUpTodayCount': stats.backedUpToday,
        'versionedFilesCount': stats.versionedFilesCount,
        'duplicateFilesCount': stats.duplicateFilesCount,
        'duplicateStorageBytes': stats.duplicateStorageBytes,
        'skippedFilesCount': stats.skippedFilesCount,
        'failedFilesCount': stats.failedFilesCount,
        'restoredFilesCount': stats.restoredFilesCount,
        'foldersMonitored': stats.foldersMonitored,
        'currentQueueCount': stats.currentQueueCount,
        'storageUsedBytes': stats.storageUsedBytes,
        'storageAvailableBytes': stats.storageAvailableBytes,
        'averageBackupSpeedMbps': stats.averageBackupSpeed,
        'averageRestoreSpeedMbps': stats.averageRestoreSpeed,
      },
      'storageAnalysis': {
        'largestFolders': storage.largestFolders.map((f) => {
          'name': f.name,
          'path': f.path,
          'sizeBytes': f.sizeBytes,
        }).toList(),
        'largestFiles': storage.largestFiles.map((f) => {
          'name': f.name,
          'path': f.path,
          'sizeBytes': f.sizeBytes,
        }).toList(),
        'mostActiveFolder': storage.mostActiveFolder,
        'leastActiveFolder': storage.leastActiveFolder,
        'duplicateStorageSavedBytes': storage.duplicateStorageSavedBytes,
        'estimatedFutureStorageBytes30Days': storage.estimatedFutureStorageBytes30Days,
        'isLowStoragePredicted': storage.isLowStoragePredicted,
        'estimatedRemainingDays': storage.estimatedRemainingDays,
      },
      'performanceAnalysis': {
        'averageCopySpeedMbps': performance.averageCopySpeedMbps,
        'averageVerifyTimeSeconds': performance.averageVerifyTimeSeconds,
        'averageRestoreTimeSeconds': performance.averageRestoreTimeSeconds,
        'cpuUsagePercent': performance.cpuUsagePercent,
        'ramUsagePercent': performance.ramUsagePercent,
        'queueEfficiencyPercent': performance.queueEfficiencyPercent,
        'slowestJobs': performance.slowestJobs.map((j) => {
          'jobName': j.jobName,
          'speedMbps': j.speedMbps,
          'durationMs': j.durationMs,
          'sizeBytes': j.sizeBytes,
        }).toList(),
        'fastestJobs': performance.fastestJobs.map((j) => {
          'jobName': j.jobName,
          'speedMbps': j.speedMbps,
          'durationMs': j.durationMs,
          'sizeBytes': j.sizeBytes,
        }).toList(),
      },
      'backupHealth': {
        'score': health.score,
        'factors': health.scoreFactors,
        'recommendations': health.recommendations.map((r) => {
          'title': r.title,
          'description': r.description,
          'severity': r.severity,
        }).toList(),
      }
    };

    return const JsonEncoder.withIndent('  ').convert(report);
  }

  static String _generateCsv(
    BackupStats stats,
    StorageAnalysis storage,
    PerformanceAnalysis performance,
    BackupHealth health,
  ) {
    final buffer = StringBuffer();
    
    // Header Section
    buffer.writeln('BackupVault Analytics Report');
    buffer.writeln('Generated on,${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Health Score,${health.score}/100');
    buffer.writeln();

    // 1. Overall Metrics
    buffer.writeln('--- OVERALL METRICS ---');
    buffer.writeln('Metric,Value,Unit');
    buffer.writeln('Total Backup Size,${stats.totalBackupSize},Bytes');
    buffer.writeln('Today\'s Backup Size,${stats.todaysBackupSize},Bytes');
    buffer.writeln('Weekly Backup Size,${stats.weeklyBackupSize},Bytes');
    buffer.writeln('Monthly Backup Size,${stats.monthlyBackupSize},Bytes');
    buffer.writeln('Total Files,${stats.totalFiles},Files');
    buffer.writeln('Backed Up Today,${stats.backedUpToday},Files');
    buffer.writeln('Versioned Files,${stats.versionedFilesCount},Files');
    buffer.writeln('Duplicate Files,${stats.duplicateFilesCount},Files');
    buffer.writeln('Skipped Files,${stats.skippedFilesCount},Files');
    buffer.writeln('Failed Files,${stats.failedFilesCount},Files');
    buffer.writeln('Restored Files,${stats.restoredFilesCount},Files');
    buffer.writeln('Folders Monitored,${stats.foldersMonitored},Folders');
    buffer.writeln('Average Backup Speed,${stats.averageBackupSpeed},MB/s');
    buffer.writeln('Average Restore Speed,${stats.averageRestoreSpeed},MB/s');
    buffer.writeln();

    // 2. Largest Folders
    buffer.writeln('--- LARGEST FOLDERS ---');
    buffer.writeln('Folder Name,Source Path,Size (Bytes)');
    for (final f in storage.largestFolders) {
      buffer.writeln('"${f.name}","${f.path}",${f.sizeBytes}');
    }
    buffer.writeln();

    // 3. Performance stats
    buffer.writeln('--- PERFORMANCE ANALYSIS ---');
    buffer.writeln('Parameter,Value');
    buffer.writeln('Avg Copy Speed,${performance.averageCopySpeedMbps} MB/s');
    buffer.writeln('Avg Verify Time,${performance.averageVerifyTimeSeconds} seconds');
    buffer.writeln('Avg Restore Time,${performance.averageRestoreTimeSeconds} seconds');
    buffer.writeln('Queue Efficiency,${performance.queueEfficiencyPercent}%');
    buffer.writeln();

    // 4. Recommendations
    buffer.writeln('--- RECOMMENDATIONS ---');
    buffer.writeln('Title,Severity,Description');
    for (final r in health.recommendations) {
      buffer.writeln('"${r.title}","${r.severity.toUpperCase()}","${r.description.replaceAll('"', '""')}"');
    }

    return buffer.toString();
  }

  static String _generatePrintableHtml(
    BackupStats stats,
    StorageAnalysis storage,
    PerformanceAnalysis performance,
    BackupHealth health,
  ) {
    String formatBytes(int bytes) {
      if (bytes <= 0) return '0 B';
      const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
      var i = 0;
      double size = bytes.toDouble();
      while (size >= 1024 && i < suffixes.length - 1) {
        size /= 1024;
        i++;
      }
      return '${size.toStringAsFixed(2)} ${suffixes[i]}';
    }

    final recommendationsHtml = health.recommendations.isEmpty
        ? '<div class="no-recommendations">✓ System is in optimal condition. No recommendations at this time.</div>'
        : health.recommendations.map((r) => '''
      <div class="recommendation-item severity-${r.severity}">
        <strong>[${r.severity.toUpperCase()}] ${r.title}</strong><br/>
        <span>${r.description}</span>
      </div>
    ''').join('\n');

    final largestFoldersHtml = storage.largestFolders.map((f) => '''
      <tr>
        <td>${f.name}</td>
        <td><code>${f.path}</code></td>
        <td>${formatBytes(f.sizeBytes)}</td>
      </tr>
    ''').join('\n');

    final largestFilesHtml = storage.largestFiles.map((f) => '''
      <tr>
        <td>${f.name}</td>
        <td><code>${f.path}</code></td>
        <td>${formatBytes(f.sizeBytes)}</td>
      </tr>
    ''').join('\n');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>BackupVault Analytics Report</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      color: #333;
      line-height: 1.5;
      padding: 30px;
      background-color: #fafafa;
    }
    .container {
      max-width: 900px;
      margin: 0 auto;
      background: white;
      padding: 40px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }
    header {
      border-bottom: 2px solid #eaeaea;
      padding-bottom: 20px;
      margin-bottom: 30px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    h1 { margin: 0; color: #1a1a1a; font-size: 26px; }
    h2 { color: #2c3e50; border-bottom: 1px solid #eee; padding-bottom: 8px; margin-top: 30px; }
    .meta-time { color: #666; font-size: 14px; }
    .grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 20px;
      margin-bottom: 30px;
    }
    .card {
      background: #fdfdfd;
      border: 1px solid #f0f0f0;
      border-radius: 6px;
      padding: 20px;
    }
    .metric-value {
      font-size: 24px;
      font-weight: bold;
      color: #0f172a;
      margin-top: 5px;
    }
    .metric-label {
      color: #64748b;
      font-size: 13px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .health-badge {
      font-size: 32px;
      font-weight: 800;
      color: #10b981;
    }
    .health-badge.warning { color: #f59e0b; }
    .health-badge.danger { color: #ef4444; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 15px;
    }
    th, td {
      text-align: left;
      padding: 10px;
      border-bottom: 1px solid #eaeaea;
    }
    th {
      background-color: #f8fafc;
      color: #475569;
      font-size: 13px;
      text-transform: uppercase;
    }
    td { font-size: 14px; }
    code {
      font-family: monospace;
      background: #f1f5f9;
      padding: 2px 4px;
      border-radius: 4px;
      font-size: 12px;
    }
    .recommendation-item {
      padding: 15px;
      margin-bottom: 12px;
      border-left: 4px solid;
      border-radius: 0 4px 4px 0;
      background-color: #fbfbfb;
    }
    .recommendation-item.severity-high { border-left-color: #ef4444; background-color: #fef2f2; }
    .recommendation-item.severity-medium { border-left-color: #f59e0b; background-color: #fffbeb; }
    .recommendation-item.severity-low { border-left-color: #3b82f6; background-color: #eff6ff; }
    .no-recommendations {
      padding: 15px;
      background: #f0fdf4;
      color: #166534;
      border: 1px solid #bbf7d0;
      border-radius: 4px;
    }
    @media print {
      body { background: white; padding: 0; }
      .container { box-shadow: none; padding: 0; max-width: 100%; }
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div>
        <h1>BackupVault</h1>
        <div class="meta-time">Analytics & System Health Report</div>
      </div>
      <div class="meta-time" style="text-align: right;">
        Generated: <strong>${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}</strong>
      </div>
    </header>

    <div class="grid">
      <div class="card" style="text-align: center; display: flex; flex-direction: column; justify-content: center; align-items: center;">
        <span class="metric-label">System Health Score</span>
        <div class="health-badge ${health.score < 50 ? 'danger' : (health.score < 80 ? 'warning' : '')}">${health.score}/100</div>
      </div>
      <div class="card">
        <span class="metric-label">Total Monitored Size</span>
        <div class="metric-value">${formatBytes(stats.totalBackupSize)}</div>
        <div style="margin-top: 10px; font-size: 13px; color: #666;">
          Files Monitored: <strong>${stats.totalFiles}</strong> | Versions Saved: <strong>${stats.versionedFilesCount}</strong>
        </div>
      </div>
    </div>

    <h2>Overall Backup Metrics</h2>
    <div class="grid" style="grid-template-columns: repeat(3, 1fr);">
      <div class="card">
        <span class="metric-label">Backed Up Today</span>
        <div class="metric-value">${formatBytes(stats.todaysBackupSize)}</div>
        <div class="meta-time">${stats.backedUpToday} files</div>
      </div>
      <div class="card">
        <span class="metric-label">Weekly Volume</span>
        <div class="metric-value">${formatBytes(stats.weeklyBackupSize)}</div>
      </div>
      <div class="card">
        <span class="metric-label">Monthly Volume</span>
        <div class="metric-value">${formatBytes(stats.monthlyBackupSize)}</div>
      </div>
    </div>

    <h2>Storage & Deduplication</h2>
    <div class="grid">
      <div class="card">
        <span class="metric-label">Deduplicated Savings</span>
        <div class="metric-value" style="color: #10b981;">${formatBytes(storage.duplicateStorageSavedBytes)}</div>
        <div style="margin-top: 5px; font-size: 12px; color: #666;">Duplicates Detected: ${stats.duplicateFilesCount}</div>
      </div>
      <div class="card">
        <span class="metric-label">Predicted 30-Day Growth</span>
        <div class="metric-value">${formatBytes(storage.estimatedFutureStorageBytes30Days)}</div>
        <div style="margin-top: 5px; font-size: 12px; color: #666;">Estimated Limit: ${storage.estimatedRemainingDays == -1 ? 'Infinite / Stable' : '${storage.estimatedRemainingDays} Days'}</div>
      </div>
    </div>

    <h2>Performance Analytics</h2>
    <table style="margin-bottom: 30px;">
      <thead>
        <tr>
          <th>Metric Name</th>
          <th>Measured Value</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Average Copy Transfer Speed</td>
          <td><strong>${performance.averageCopySpeedMbps.toStringAsFixed(2)} MB/s</strong></td>
        </tr>
        <tr>
          <td>Average Verification Cycle duration</td>
          <td><strong>${performance.averageVerifyTimeSeconds.toStringAsFixed(2)} seconds</strong></td>
        </tr>
        <tr>
          <td>Average Restore execution duration</td>
          <td><strong>${performance.averageVerifyTimeSeconds.toStringAsFixed(2)} seconds</strong></td>
        </tr>
        <tr>
          <td>Queue Processing Efficiency Rate</td>
          <td><strong>${performance.queueEfficiencyPercent.toStringAsFixed(1)}%</strong></td>
        </tr>
      </tbody>
    </table>

    <h2>Largest Source Folders</h2>
    <table style="margin-bottom: 30px;">
      <thead>
        <tr>
          <th>Folder</th>
          <th>Source Path</th>
          <th>Monitored Size</th>
        </tr>
      </thead>
      <tbody>
        $largestFoldersHtml
      </tbody>
    </table>

    <h2>Largest Backup Files</h2>
    <table style="margin-bottom: 30px;">
      <thead>
        <tr>
          <th>File Name</th>
          <th>Original Path</th>
          <th>Size</th>
        </tr>
      </thead>
      <tbody>
        $largestFilesHtml
      </tbody>
    </table>

    <h2>Actionable System Recommendations</h2>
    <div class="recommendations-box">
      $recommendationsHtml
    </div>
  </div>
</body>
</html>
''';
  }
}
