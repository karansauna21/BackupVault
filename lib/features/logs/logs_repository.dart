import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/repositories/backup_log_repository.dart';
import '../settings/settings_database.dart';
import 'logs_models.dart';

class LogsRepository {
  final AppDatabase _db;
  final BackupLogRepository _logRepo;
  final SettingsDatabase _settingsDb;

  LogsRepository(this._db, this._logRepo, this._settingsDb);

  /// Load pinned log IDs from settings KV database
  Future<Set<int>> getPinnedLogIds() async {
    try {
      final val = _settingsDb.getValue('pinned_log_ids');
      if (val != null) {
        final List<dynamic> decoded = json.decode(val);
        return decoded.map((e) => e as int).toSet();
      }
    } catch (_) {}
    return {};
  }

  /// Save pinned log IDs back to settings KV database
  Future<void> _savePinnedLogIds(Set<int> ids) async {
    _settingsDb.setValue('pinned_log_ids', json.encode(ids.toList()));
  }

  /// Toggle pin status of a log
  Future<void> togglePinLog(int logId) async {
    final pinned = await getPinnedLogIds();
    if (pinned.contains(logId)) {
      pinned.remove(logId);
    } else {
      pinned.add(logId);
    }
    await _savePinnedLogIds(pinned);
  }

  /// Query logs from sqlite using search and filter options
  Future<List<LogEntry>> getLogs({
    LogSearchQuery? search,
    LogFilterOptions? filters,
    int limit = 1000,
  }) async {
    final pinnedIds = await getPinnedLogIds();
    
    // Select all logs ordered by timestamp desc
    final query = _db.select(_db.backupLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
      
    final results = await query.get();

    // Map to LogEntry domain models
    final List<LogEntry> entries = results.map((r) {
      final isPinned = pinnedIds.contains(r.id);
      return LogEntry.fromDrift(r, isPinned: isPinned);
    }).toList();

    // In-memory advanced search and filter mapping for high performance
    return entries.where((entry) {
      // 1. Search Query Filters
      if (search != null && !search.isEmpty) {
        if (search.keyword.isNotEmpty) {
          final kw = search.keyword.toLowerCase();
          final matchesMsg = entry.message.toLowerCase().contains(kw);
          final matchesException = entry.exceptionDetails?.toLowerCase().contains(kw) ?? false;
          final matchesSrc = entry.sourceFile?.toLowerCase().contains(kw) ?? false;
          final matchesDst = entry.destinationFile?.toLowerCase().contains(kw) ?? false;
          if (!matchesMsg && !matchesException && !matchesSrc && !matchesDst) {
            return false;
          }
        }
        
        if (search.folder != null && search.folder!.isNotEmpty) {
          final f = search.folder!.toLowerCase();
          final srcMatch = entry.sourceFile?.toLowerCase().contains(f) ?? false;
          final dstMatch = entry.destinationFile?.toLowerCase().contains(f) ?? false;
          if (!srcMatch && !dstMatch) return false;
        }

        if (search.file != null && search.file!.isNotEmpty) {
          final fl = search.file!.toLowerCase();
          final srcMatch = entry.sourceFile?.toLowerCase().contains(fl) ?? false;
          final dstMatch = entry.destinationFile?.toLowerCase().contains(fl) ?? false;
          if (!srcMatch && !dstMatch) return false;
        }

        if (search.dateRange != null) {
          final start = search.dateRange!.start;
          final end = search.dateRange!.end.add(const Duration(days: 1)); // inclusive of end day
          if (entry.timestamp.isBefore(start) || entry.timestamp.isAfter(end)) {
            return false;
          }
        }

        if (search.level != null && entry.level != search.level) {
          return false;
        }

        if (search.category != null && entry.category != search.category) {
          return false;
        }

        if (search.status != null && search.status!.isNotEmpty) {
          if (entry.status?.toLowerCase() != search.status!.toLowerCase()) {
            return false;
          }
        }

        if (search.errorCode != null && search.errorCode!.isNotEmpty) {
          if (entry.errorCode?.toLowerCase() != search.errorCode!.toLowerCase()) {
            return false;
          }
        }

        if (search.worker != null && search.worker!.isNotEmpty) {
          if (entry.workerId?.toLowerCase() != search.worker!.toLowerCase()) {
            return false;
          }
        }
      }

      // 2. Log Filter Options
      if (filters != null && !filters.isEmpty) {
        if (filters.levels.isNotEmpty && !filters.levels.contains(entry.level)) {
          return false;
        }

        if (filters.modules.isNotEmpty && !filters.modules.contains(entry.module)) {
          return false;
        }

        if (filters.showOnlyErrors && entry.level != LogLevel.error) {
          return false;
        }

        if (filters.showOnlyWarnings && entry.level != LogLevel.warning) {
          return false;
        }

        if (filters.showOnlySuccess && entry.level != LogLevel.success) {
          return false;
        }

        if (filters.showOnlyImportant && !entry.isImportant) {
          return false;
        }
      }

      return true;
    }).take(limit).toList();
  }

  /// Write a new log entry
  Future<void> addLogEntry(LogEntry entry) async {
    await _logRepo.addLog(
      BackupLogsCompanion.insert(
        logType: entry.level.name,
        message: entry.toStructuredMessageJson(),
        tag: Value(entry.module.name),
        stackTrace: Value(entry.exceptionDetails),
        createdAt: Value(entry.timestamp),
      ),
    );
  }

  /// Clear all logs
  Future<void> clearAllLogs() async {
    await _logRepo.clearLogs();
  }

  /// Purge old logs from SQLite
  Future<int> deleteLogsOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final query = _db.delete(_db.backupLogs)
      ..where((t) => t.createdAt.isSmallerThanValue(cutoff));
    return await query.go();
  }

  /// Get current SQLite database file size in MB
  Future<int> getDatabaseSize() async {
    try {
      final dbPath = _settingsDb.dbPath;
      if (dbPath != null && dbPath != ':memory:') {
        final file = File(dbPath);
        if (await file.exists()) {
          final bytes = await file.length();
          return (bytes / (1024 * 1024)).ceil();
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Execute automatic maintenance cleanup based on config
  Future<void> autoCleanup(MaintenanceConfig config) async {
    if (!config.autoCleanupEnabled) return;
    
    // 1. Delete logs older than retention period
    await deleteLogsOlderThan(config.logRetentionDays);

    // 2. Check DB size, if it exceeds cap, purge oldest non-pinned logs
    final dbSize = await getDatabaseSize();
    if (dbSize > config.maxDatabaseSizeMb) {
      // Find oldest logs and delete them until size is acceptable
      final pinnedIds = await getPinnedLogIds();
      final allLogs = await _db.select(_db.backupLogs).get();
      if (allLogs.length > 500) {
        final toDeleteIds = allLogs
            .where((l) => !pinnedIds.contains(l.id))
            .take(allLogs.length ~/ 3)
            .map((l) => l.id)
            .toList();
        
        if (toDeleteIds.isNotEmpty) {
          final query = _db.delete(_db.backupLogs)
            ..where((t) => t.id.isIn(toDeleteIds));
          await query.go();
        }
      }
    }
  }

  /// Calculate summary statistics of logs database
  Future<LogStatisticsState> calculateStatistics() async {
    final pinnedIds = await getPinnedLogIds();
    final results = await _db.select(_db.backupLogs).get();
    
    final List<LogEntry> entries = results.map((r) {
      final isPinned = pinnedIds.contains(r.id);
      return LogEntry.fromDrift(r, isPinned: isPinned);
    }).toList();

    int errors = 0;
    int warnings = 0;
    int successfulBackups = 0;
    int successfulRestores = 0;
    
    int totalBackupTimeMs = 0;
    int backupCountWithTime = 0;
    int totalRestoreTimeMs = 0;
    int restoreCountWithTime = 0;
    
    final Map<String, int> folderActivity = {};
    final Map<String, int> commonErrors = {};

    for (final entry in entries) {
      if (entry.level == LogLevel.error) {
        errors++;
        if (entry.errorCode != null && entry.errorCode!.isNotEmpty) {
          commonErrors[entry.errorCode!] = (commonErrors[entry.errorCode!] ?? 0) + 1;
        } else if (entry.message.isNotEmpty) {
          final msgSummary = entry.message.split(':').first;
          commonErrors[msgSummary] = (commonErrors[msgSummary] ?? 0) + 1;
        }
      }
      
      if (entry.level == LogLevel.warning) {
        warnings++;
      }

      if (entry.category == LogCategory.backupCompleted) {
        successfulBackups++;
        if (entry.durationMs != null) {
          totalBackupTimeMs += entry.durationMs!;
          backupCountWithTime++;
        }
      }

      if (entry.category == LogCategory.restoreCompleted) {
        successfulRestores++;
        if (entry.durationMs != null) {
          totalRestoreTimeMs += entry.durationMs!;
          restoreCountWithTime++;
        }
      }

      // Track folder activity by checking source or destination parent directories
      String? activePath;
      if (entry.sourceFile != null && entry.sourceFile!.isNotEmpty) {
        activePath = _getParentFolder(entry.sourceFile!);
      } else if (entry.destinationFile != null && entry.destinationFile!.isNotEmpty) {
        activePath = _getParentFolder(entry.destinationFile!);
      }
      
      if (activePath != null) {
        folderActivity[activePath] = (folderActivity[activePath] ?? 0) + 1;
      }
    }

    // Sort errors to get top 5
    final sortedErrors = commonErrors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topErrors = Map.fromEntries(sortedErrors.take(5));

    // Get most active folder
    String mostActiveFolder = 'N/A';
    int maxActivity = 0;
    folderActivity.forEach((folder, count) {
      if (count > maxActivity) {
        maxActivity = count;
        mostActiveFolder = folder;
      }
    });

    return LogStatisticsState(
      totalLogs: entries.length,
      errors: errors,
      warnings: warnings,
      successfulBackups: successfulBackups,
      successfulRestores: successfulRestores,
      averageBackupTimeMs: backupCountWithTime > 0 ? totalBackupTimeMs ~/ backupCountWithTime : 0,
      averageRestoreTimeMs: restoreCountWithTime > 0 ? totalRestoreTimeMs ~/ restoreCountWithTime : 0,
      mostActiveFolder: mostActiveFolder,
      mostCommonErrors: topErrors,
    );
  }

  String _getParentFolder(String filePath) {
    try {
      final parts = filePath.split(Platform.isWindows ? '\\' : '/');
      if (parts.length > 1) {
        return parts[parts.length - 2];
      }
    } catch (_) {}
    return filePath;
  }
}
