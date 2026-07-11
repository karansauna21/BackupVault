import '../models/notification_models.dart';

class NotificationHistoryManager {
  static List<NotificationItem> filter(List<NotificationItem> list, NotificationFilters filters) {
    return list.where((item) {
      if (filters.searchPrefix != null && filters.searchPrefix!.trim().isNotEmpty) {
        final query = filters.searchPrefix!.trim().toLowerCase();
        final matchMessage = item.message.toLowerCase().contains(query);
        final matchSource = item.source?.toLowerCase().contains(query) ?? false;
        final matchDest = item.destination?.toLowerCase().contains(query) ?? false;
        final matchWorker = item.worker?.toLowerCase().contains(query) ?? false;
        if (!matchMessage && !matchSource && !matchDest && !matchWorker) {
          return false;
        }
      }

      if (filters.priority != null && item.priority != filters.priority) {
        return false;
      }

      if (filters.category != null && item.category != filters.category) {
        return false;
      }

      if (filters.folderId != null) {
        final folderQuery = 'folder_${filters.folderId}';
        final sourceMatch = item.source?.contains(folderQuery) ?? false;
        final destMatch = item.destination?.contains(folderQuery) ?? false;
        final backupMatch = item.relatedBackupId == filters.folderId;
        if (!sourceMatch && !destMatch && !backupMatch) {
          return false;
        }
      }

      if (filters.status != null && filters.status!.isNotEmpty) {
        if (item.status?.toLowerCase() != filters.status!.toLowerCase()) {
          return false;
        }
      }

      if (filters.worker != null && filters.worker!.isNotEmpty) {
        if (item.worker?.toLowerCase() != filters.worker!.toLowerCase()) {
          return false;
        }
      }

      if (filters.dateRange != null) {
        final start = filters.dateRange!.start;
        final end = filters.dateRange!.end;
        if (item.timestamp.isBefore(start) || item.timestamp.isAfter(end)) {
          return false;
        }
      }

      if (filters.storageDevice != null && filters.storageDevice!.isNotEmpty) {
        final dev = filters.storageDevice!.toLowerCase();
        final matchDest = item.destination?.toLowerCase().contains(dev) ?? false;
        final matchMessage = item.message.toLowerCase().contains(dev);
        if (!matchDest && matchMessage == false) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  static NotificationHistoryStats calculateStats(List<NotificationItem> list) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    int unread = 0;
    int read = 0;
    int pinned = 0;
    int critical = 0;
    int today = 0;

    for (final item in list) {
      if (item.isRead) {
        read++;
      } else {
        unread++;
      }

      if (item.isPinned) {
        pinned++;
      }

      if (item.priority == NotificationPriority.critical) {
        critical++;
      }

      if (item.timestamp.isAfter(todayStart) && item.timestamp.isBefore(todayEnd)) {
        today++;
      }
    }

    return NotificationHistoryStats(
      totalCount: list.length,
      unreadCount: unread,
      readCount: read,
      pinnedCount: pinned,
      criticalCount: critical,
      todayCount: today,
    );
  }
}
