import 'package:flutter/material.dart';

enum NotificationCategory {
  backupStarted,
  backupCompleted,
  backupFailed,
  restoreStarted,
  restoreCompleted,
  restoreFailed,
  verificationSuccess,
  verificationFailed,
  duplicateFile,
  versionCreated,
  queueCompleted,
  folderAdded,
  folderRemoved,
  folderPaused,
  folderResumed,
  watcherStarted,
  watcherStopped,
  databaseError,
  diskError,
  permissionError,
  lowStorage,
  storageFull,
  usbConnected,
  usbRemoved,
  externalDriveConnected,
  externalDriveRemoved,
  applicationStarted,
  applicationClosed,
  updateAvailable;

  String get displayName {
    switch (this) {
      case NotificationCategory.backupStarted: return 'Backup Started';
      case NotificationCategory.backupCompleted: return 'Backup Completed';
      case NotificationCategory.backupFailed: return 'Backup Failed';
      case NotificationCategory.restoreStarted: return 'Restore Started';
      case NotificationCategory.restoreCompleted: return 'Restore Completed';
      case NotificationCategory.restoreFailed: return 'Restore Failed';
      case NotificationCategory.verificationSuccess: return 'Verification Success';
      case NotificationCategory.verificationFailed: return 'Verification Failed';
      case NotificationCategory.duplicateFile: return 'Duplicate File Detected';
      case NotificationCategory.versionCreated: return 'Version Created';
      case NotificationCategory.queueCompleted: return 'Queue Completed';
      case NotificationCategory.folderAdded: return 'Folder Added';
      case NotificationCategory.folderRemoved: return 'Folder Removed';
      case NotificationCategory.folderPaused: return 'Folder Paused';
      case NotificationCategory.folderResumed: return 'Folder Resumed';
      case NotificationCategory.watcherStarted: return 'Watcher Started';
      case NotificationCategory.watcherStopped: return 'Watcher Stopped';
      case NotificationCategory.databaseError: return 'Database Error';
      case NotificationCategory.diskError: return 'Disk Error';
      case NotificationCategory.permissionError: return 'Permission Error';
      case NotificationCategory.lowStorage: return 'Low Storage Warning';
      case NotificationCategory.storageFull: return 'Storage Full';
      case NotificationCategory.usbConnected: return 'USB Connected';
      case NotificationCategory.usbRemoved: return 'USB Removed';
      case NotificationCategory.externalDriveConnected: return 'External Drive Connected';
      case NotificationCategory.externalDriveRemoved: return 'External Drive Removed';
      case NotificationCategory.applicationStarted: return 'Application Started';
      case NotificationCategory.applicationClosed: return 'Application Closed';
      case NotificationCategory.updateAvailable: return 'Update Available';
    }
  }
}

enum NotificationPriority {
  critical,
  error,
  warning,
  information,
  success,
  background;

  Color get color {
    switch (this) {
      case NotificationPriority.critical: return Colors.deepOrange.shade800;
      case NotificationPriority.error: return Colors.red.shade700;
      case NotificationPriority.warning: return Colors.amber.shade800;
      case NotificationPriority.information: return Colors.blue.shade700;
      case NotificationPriority.success: return Colors.green.shade700;
      case NotificationPriority.background: return Colors.blueGrey;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationPriority.critical: return Icons.gpp_maybe_rounded;
      case NotificationPriority.error: return Icons.error_outline_rounded;
      case NotificationPriority.warning: return Icons.warning_amber_rounded;
      case NotificationPriority.information: return Icons.info_outline_rounded;
      case NotificationPriority.success: return Icons.check_circle_outline_rounded;
      case NotificationPriority.background: return Icons.settings_backup_restore_rounded;
    }
  }

  Duration get displayDuration {
    switch (this) {
      case NotificationPriority.critical: return const Duration(seconds: 15);
      case NotificationPriority.error: return const Duration(seconds: 10);
      case NotificationPriority.warning: return const Duration(seconds: 7);
      case NotificationPriority.information: return const Duration(seconds: 4);
      case NotificationPriority.success: return const Duration(seconds: 4);
      case NotificationPriority.background: return const Duration(seconds: 2);
    }
  }
}

class NotificationItem {
  final int id;
  final DateTime timestamp;
  final NotificationPriority priority;
  final NotificationCategory category;
  final String message;
  final String? action;
  final String? source;
  final String? destination;
  final String? status;
  final String? worker;
  final int? relatedBackupId;
  final bool isRead;
  final bool isPinned;

  const NotificationItem({
    required this.id,
    required this.timestamp,
    required this.priority,
    required this.category,
    required this.message,
    this.action,
    this.source,
    this.destination,
    this.status,
    this.worker,
    this.relatedBackupId,
    this.isRead = false,
    this.isPinned = false,
  });

  NotificationItem copyWith({
    int? id,
    DateTime? timestamp,
    NotificationPriority? priority,
    NotificationCategory? category,
    String? message,
    String? action,
    String? source,
    String? destination,
    String? status,
    String? worker,
    int? relatedBackupId,
    bool? isRead,
    bool? isPinned,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      message: message ?? this.message,
      action: action ?? this.action,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      worker: worker ?? this.worker,
      relatedBackupId: relatedBackupId ?? this.relatedBackupId,
      isRead: isRead ?? this.isRead,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.name,
      'category': category.name,
      'message': message,
      'action': action,
      'source': source,
      'destination': destination,
      'status': status,
      'worker': worker,
      'relatedBackupId': relatedBackupId,
      'isRead': isRead ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.information,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => NotificationCategory.applicationStarted,
      ),
      message: json['message'] as String,
      action: json['action'] as String?,
      source: json['source'] as String?,
      destination: json['destination'] as String?,
      status: json['status'] as String?,
      worker: json['worker'] as String?,
      relatedBackupId: json['relatedBackupId'] as int?,
      isRead: (json['isRead'] as int? ?? 0) == 1,
      isPinned: (json['isPinned'] as int? ?? 0) == 1,
    );
  }
}

class NotificationSettings {
  final bool quietHoursEnabled;
  final String quietHoursStart; // HH:mm
  final String quietHoursEnd;   // HH:mm
  final bool dndEnabled;
  final String frequency; // 'immediate' or 'batch'
  final int batchIntervalMinutes;
  final Map<NotificationCategory, bool> categoriesEnabled;

  const NotificationSettings({
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.dndEnabled = false,
    this.frequency = 'immediate',
    this.batchIntervalMinutes = 15,
    this.categoriesEnabled = const {},
  });

  NotificationSettings copyWith({
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? dndEnabled,
    String? frequency,
    int? batchIntervalMinutes,
    Map<NotificationCategory, bool>? categoriesEnabled,
  }) {
    return NotificationSettings(
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      frequency: frequency ?? this.frequency,
      batchIntervalMinutes: batchIntervalMinutes ?? this.batchIntervalMinutes,
      categoriesEnabled: categoriesEnabled ?? this.categoriesEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'dndEnabled': dndEnabled,
      'frequency': frequency,
      'batchIntervalMinutes': batchIntervalMinutes,
      'categoriesEnabled': categoriesEnabled.map((k, v) => MapEntry(k.name, v)),
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categoriesEnabled'] as Map<String, dynamic>? ?? {};
    final Map<NotificationCategory, bool> cats = {};
    for (final val in NotificationCategory.values) {
      cats[val] = rawCats[val.name] as bool? ?? true;
    }

    return NotificationSettings(
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '08:00',
      dndEnabled: json['dndEnabled'] as bool? ?? false,
      frequency: json['frequency'] as String? ?? 'immediate',
      batchIntervalMinutes: json['batchIntervalMinutes'] as int? ?? 15,
      categoriesEnabled: cats,
    );
  }
}

class NotificationFilters {
  final NotificationPriority? priority;
  final NotificationCategory? category;
  final DateTimeRange? dateRange;
  final int? folderId;
  final String? status;
  final String? worker;
  final String? searchPrefix;
  final String? storageDevice;

  const NotificationFilters({
    this.priority,
    this.category,
    this.dateRange,
    this.folderId,
    this.status,
    this.worker,
    this.searchPrefix,
    this.storageDevice,
  });

  NotificationFilters copyWith({
    NotificationPriority? Function()? priority,
    NotificationCategory? Function()? category,
    DateTimeRange? Function()? dateRange,
    int? Function()? folderId,
    String? Function()? status,
    String? Function()? worker,
    String? Function()? searchPrefix,
    String? Function()? storageDevice,
  }) {
    return NotificationFilters(
      priority: priority != null ? priority() : this.priority,
      category: category != null ? category() : this.category,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      folderId: folderId != null ? folderId() : this.folderId,
      status: status != null ? status() : this.status,
      worker: worker != null ? worker() : this.worker,
      searchPrefix: searchPrefix != null ? searchPrefix() : this.searchPrefix,
      storageDevice: storageDevice != null ? storageDevice() : this.storageDevice,
    );
  }

  NotificationFilters reset() {
    return const NotificationFilters();
  }
}

class NotificationHistoryStats {
  final int totalCount;
  final int unreadCount;
  final int readCount;
  final int pinnedCount;
  final int criticalCount;
  final int todayCount;

  const NotificationHistoryStats({
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
    required this.pinnedCount,
    required this.criticalCount,
    required this.todayCount,
  });

  factory NotificationHistoryStats.empty() {
    return const NotificationHistoryStats(
      totalCount: 0,
      unreadCount: 0,
      readCount: 0,
      pinnedCount: 0,
      criticalCount: 0,
      todayCount: 0,
    );
  }
}
