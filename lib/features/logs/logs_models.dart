import 'dart:convert';
import 'package:flutter/material.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  success,
  system;

  String get key => name;
  
  static LogLevel fromString(String val) {
    return LogLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => LogLevel.info,
    );
  }
}

enum LogModule {
  backup,
  restore,
  folderManager,
  watcher,
  database,
  settings,
  system;

  String get displayName {
    switch (this) {
      case LogModule.folderManager:
        return 'Folder Manager';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  static LogModule fromString(String val) {
    return LogModule.values.firstWhere(
      (e) => e.name.toLowerCase() == val.replaceAll(' ', '').toLowerCase(),
      orElse: () => LogModule.system,
    );
  }
}

enum LogCategory {
  backupStarted('Backup Started'),
  backupCompleted('Backup Completed'),
  backupFailed('Backup Failed'),
  restoreStarted('Restore Started'),
  restoreCompleted('Restore Completed'),
  restoreFailed('Restore Failed'),
  folderAdded('Folder Added'),
  folderRemoved('Folder Removed'),
  folderModified('Folder Modified'),
  watcherStarted('Watcher Started'),
  watcherStopped('Watcher Stopped'),
  workerStarted('Worker Started'),
  workerStopped('Worker Stopped'),
  queueEvents('Queue Events'),
  databaseEvents('Database Events'),
  settingsChanged('Settings Changed'),
  startup('Startup'),
  shutdown('Shutdown'),
  crash('Crash'),
  warning('Warning'),
  information('Information'),
  debug('Debug'),
  systemEvents('System Events');

  final String displayName;
  const LogCategory(this.displayName);

  static LogCategory fromString(String val) {
    return LogCategory.values.firstWhere(
      (e) => e.displayName.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => LogCategory.information,
    );
  }
}

class LogEntry {
  final int id;
  final DateTime timestamp;
  final LogLevel level;
  final LogModule module;
  final LogCategory category;
  final String message;
  final String? sourceFile;
  final String? destinationFile;
  final int? durationMs;
  final String? workerId;
  final int? fileSize;
  final String? sha256;
  final String? status;
  final String? errorCode;
  final String? exceptionDetails;
  final bool isPinned;
  final bool isImportant;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.module,
    required this.category,
    required this.message,
    this.sourceFile,
    this.destinationFile,
    this.durationMs,
    this.workerId,
    this.fileSize,
    this.sha256,
    this.status,
    this.errorCode,
    this.exceptionDetails,
    this.isPinned = false,
    this.isImportant = false,
  });

  LogEntry copyWith({
    int? id,
    DateTime? timestamp,
    LogLevel? level,
    LogModule? module,
    LogCategory? category,
    String? message,
    String? sourceFile,
    String? destinationFile,
    int? durationMs,
    String? workerId,
    int? fileSize,
    String? sha256,
    String? status,
    String? errorCode,
    String? exceptionDetails,
    bool? isPinned,
    bool? isImportant,
  }) {
    return LogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      level: level ?? this.level,
      module: module ?? this.module,
      category: category ?? this.category,
      message: message ?? this.message,
      sourceFile: sourceFile ?? this.sourceFile,
      destinationFile: destinationFile ?? this.destinationFile,
      durationMs: durationMs ?? this.durationMs,
      workerId: workerId ?? this.workerId,
      fileSize: fileSize ?? this.fileSize,
      sha256: sha256 ?? this.sha256,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      exceptionDetails: exceptionDetails ?? this.exceptionDetails,
      isPinned: isPinned ?? this.isPinned,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  /// Deserializes a Drift BackupLog entity into our rich domain model
  factory LogEntry.fromDrift(dynamic log, {bool isPinned = false}) {
    final rawMessage = log.message as String;
    
    // Check if the message is a JSON string
    if (rawMessage.startsWith('{') && rawMessage.endsWith('}')) {
      try {
        final Map<String, dynamic> data = json.decode(rawMessage);
        final levelStr = log.logType as String;
        final tagStr = log.tag as String? ?? '';
        
        return LogEntry(
          id: log.id as int,
          timestamp: log.createdAt as DateTime,
          level: LogLevel.fromString(data['level'] ?? levelStr),
          module: LogModule.fromString(data['module'] ?? tagStr),
          category: LogCategory.fromString(data['category'] ?? ''),
          message: data['message'] ?? '',
          sourceFile: data['sourceFile'],
          destinationFile: data['destinationFile'],
          durationMs: data['durationMs'],
          workerId: data['workerId'],
          fileSize: data['fileSize'],
          sha256: data['sha256'],
          status: data['status'],
          errorCode: data['errorCode'],
          exceptionDetails: data['exceptionDetails'] ?? log.stackTrace,
          isPinned: isPinned,
          isImportant: data['isImportant'] ?? (levelStr.toLowerCase() == 'error'),
        );
      } catch (_) {
        // Fallback to text parsing on json error
      }
    }

    // Fallback: Parse non-structured logs
    final levelStr = log.logType as String;
    final tagStr = log.tag as String? ?? 'system';
    final level = LogLevel.fromString(levelStr);
    
    return LogEntry(
      id: log.id as int,
      timestamp: log.createdAt as DateTime,
      level: level,
      module: LogModule.fromString(tagStr),
      category: level == LogLevel.error 
          ? LogCategory.crash 
          : (level == LogLevel.warning ? LogCategory.warning : LogCategory.information),
      message: rawMessage,
      exceptionDetails: log.stackTrace,
      isPinned: isPinned,
      isImportant: level == LogLevel.error,
    );
  }

  /// Serializes into a JSON format to be stored in the DB message field
  String toStructuredMessageJson() {
    return json.encode({
      'level': level.name,
      'module': module.name,
      'category': category.name,
      'message': message,
      'sourceFile': sourceFile,
      'destinationFile': destinationFile,
      'durationMs': durationMs,
      'workerId': workerId,
      'fileSize': fileSize,
      'sha256': sha256,
      'status': status,
      'errorCode': errorCode,
      'exceptionDetails': exceptionDetails,
      'isImportant': isImportant,
    });
  }
}

class LogSearchQuery {
  final String keyword;
  final String? folder;
  final String? file;
  final DateTimeRange? dateRange;
  final LogLevel? level;
  final LogCategory? category;
  final String? status;
  final String? errorCode;
  final String? worker;

  const LogSearchQuery({
    this.keyword = '',
    this.folder,
    this.file,
    this.dateRange,
    this.level,
    this.category,
    this.status,
    this.errorCode,
    this.worker,
  });

  LogSearchQuery copyWith({
    String? keyword,
    String? folder,
    String? file,
    DateTimeRange? dateRange,
    LogLevel? level,
    LogCategory? category,
    String? status,
    String? errorCode,
    String? worker,
    bool clearDateRange = false,
  }) {
    return LogSearchQuery(
      keyword: keyword ?? this.keyword,
      folder: folder ?? this.folder,
      file: file ?? this.file,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      level: level ?? this.level,
      category: category ?? this.category,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      worker: worker ?? this.worker,
    );
  }

  bool get isEmpty =>
      keyword.isEmpty &&
      folder == null &&
      file == null &&
      dateRange == null &&
      level == null &&
      category == null &&
      status == null &&
      errorCode == null &&
      worker == null;
}

class LogFilterOptions {
  final Set<LogLevel> levels;
  final Set<LogModule> modules;
  final bool showOnlyErrors;
  final bool showOnlyWarnings;
  final bool showOnlySuccess;
  final bool showOnlyImportant;

  const LogFilterOptions({
    this.levels = const {},
    this.modules = const {},
    this.showOnlyErrors = false,
    this.showOnlyWarnings = false,
    this.showOnlySuccess = false,
    this.showOnlyImportant = false,
  });

  LogFilterOptions copyWith({
    Set<LogLevel>? levels,
    Set<LogModule>? modules,
    bool? showOnlyErrors,
    bool? showOnlyWarnings,
    bool? showOnlySuccess,
    bool? showOnlyImportant,
  }) {
    return LogFilterOptions(
      levels: levels ?? this.levels,
      modules: modules ?? this.modules,
      showOnlyErrors: showOnlyErrors ?? this.showOnlyErrors,
      showOnlyWarnings: showOnlyWarnings ?? this.showOnlyWarnings,
      showOnlySuccess: showOnlySuccess ?? this.showOnlySuccess,
      showOnlyImportant: showOnlyImportant ?? this.showOnlyImportant,
    );
  }

  bool get isEmpty =>
      levels.isEmpty &&
      modules.isEmpty &&
      !showOnlyErrors &&
      !showOnlyWarnings &&
      !showOnlySuccess &&
      !showOnlyImportant;
}

class LogStatisticsState {
  final int totalLogs;
  final int errors;
  final int warnings;
  final int successfulBackups;
  final int successfulRestores;
  final int averageBackupTimeMs;
  final int averageRestoreTimeMs;
  final String mostActiveFolder;
  final Map<String, int> mostCommonErrors;

  const LogStatisticsState({
    this.totalLogs = 0,
    this.errors = 0,
    this.warnings = 0,
    this.successfulBackups = 0,
    this.successfulRestores = 0,
    this.averageBackupTimeMs = 0,
    this.averageRestoreTimeMs = 0,
    this.mostActiveFolder = 'N/A',
    this.mostCommonErrors = const {},
  });
}

class MaintenanceConfig {
  final int logRetentionDays;
  final int maxDatabaseSizeMb;
  final bool autoCleanupEnabled;

  const MaintenanceConfig({
    this.logRetentionDays = 30,
    this.maxDatabaseSizeMb = 50,
    this.autoCleanupEnabled = true,
  });

  MaintenanceConfig copyWith({
    int? logRetentionDays,
    int? maxDatabaseSizeMb,
    bool? autoCleanupEnabled,
  }) {
    return MaintenanceConfig(
      logRetentionDays: logRetentionDays ?? this.logRetentionDays,
      maxDatabaseSizeMb: maxDatabaseSizeMb ?? this.maxDatabaseSizeMb,
      autoCleanupEnabled: autoCleanupEnabled ?? this.autoCleanupEnabled,
    );
  }
}
