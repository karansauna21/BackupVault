import 'package:drift/drift.dart';
import 'package:backup_vault/core/database/app_database.dart';
import 'search_models.dart';

class SearchRepository {
  final AppDatabase db;

  SearchRepository(this.db);

  Expression<bool> _buildStringMatch(Expression<String> field, String queryText, SearchMode mode) {
    if (queryText.isEmpty) return const Constant(true);
    switch (mode) {
      case SearchMode.exactMatch:
        return field.equals(queryText);
      case SearchMode.startsWith:
        return field.like('$queryText%');
      case SearchMode.endsWith:
        return field.like('%$queryText');
      case SearchMode.wildcard:
        final sqlWildcard = queryText.replaceAll('*', '%').replaceAll('?', '_');
        return field.like(sqlWildcard);
      case SearchMode.contains:
      case SearchMode.instant:
      case SearchMode.advanced:
        return field.like('%$queryText%');
    }
  }

  /// Search BackupFiles and map them to SearchResultItem
  Future<List<SearchResultItem>> searchFiles(SearchQuery query) async {
    final q = db.select(db.backupFiles);

    // Text search filter
    if (query.queryText.isNotEmpty) {
      q.where((t) =>
          _buildStringMatch(t.fileName, query.queryText, query.mode) |
          _buildStringMatch(t.originalPath, query.queryText, query.mode) |
          _buildStringMatch(t.sha256, query.queryText, query.mode));
    }

    // Advanced filters
    if (query.filter.folderId != null) {
      q.where((t) => t.folderId.equals(query.filter.folderId!));
    }
    if (query.filter.fileType != null) {
      q.where((t) => t.extension.equals(query.filter.fileType!));
    }
    if (query.filter.minSize != null) {
      q.where((t) => t.fileSize.isBiggerOrEqualValue(query.filter.minSize!));
    }
    if (query.filter.maxSize != null) {
      q.where((t) => t.fileSize.isSmallerOrEqualValue(query.filter.maxSize!));
    }
    if (query.filter.backupStatus != null) {
      q.where((t) => t.backupStatus.equals(query.filter.backupStatus!));
    }
    if (query.filter.startDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(query.filter.startDate!));
    }
    if (query.filter.endDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(query.filter.endDate!));
    }

    // Sorting
    final field = query.sort.field;
    final order = query.sort.order;
    q.orderBy([
      (t) {
        Expression exp;
        switch (field) {
          case SortField.name:
            exp = t.fileName;
            break;
          case SortField.size:
            exp = t.fileSize;
            break;
          case SortField.date:
          default:
            exp = t.createdAt;
            break;
        }
        return OrderingTerm(
          expression: exp,
          mode: order == SortOrder.ascending ? OrderingMode.asc : OrderingMode.desc,
        );
      }
    ]);

    // Pagination
    q.limit(query.limit, offset: (query.page - 1) * query.limit);

    final files = await q.get();

    // Map to SearchResultItem
    final List<SearchResultItem> items = [];
    for (final f in files) {
      // Get version count
      final versionQuery = db.select(db.fileVersions)..where((t) => t.fileId.equals(f.id));
      final versions = await versionQuery.get();

      items.add(SearchResultItem(
        id: 'file_${f.id}',
        type: SearchResultType.file,
        title: f.fileName,
        subtitle: f.originalPath,
        path: f.originalPath,
        backupPath: f.backupPath,
        sizeBytes: f.fileSize,
        date: f.createdAt,
        status: f.backupStatus,
        versionCount: versions.length,
        rawData: f,
      ));
    }

    return items;
  }

  /// Search FileVersions and map them to SearchResultItem
  Future<List<SearchResultItem>> searchVersions(SearchQuery query) async {
    final q = db.select(db.fileVersions);

    if (query.queryText.isNotEmpty) {
      q.where((t) => _buildStringMatch(t.backupPath, query.queryText, query.mode));
    }

    if (query.filter.startDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(query.filter.startDate!));
    }
    if (query.filter.endDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(query.filter.endDate!));
    }

    q.orderBy([
      (t) => OrderingTerm(
            expression: t.createdAt,
            mode: query.sort.order == SortOrder.ascending ? OrderingMode.asc : OrderingMode.desc,
          )
    ]);

    q.limit(query.limit, offset: (query.page - 1) * query.limit);

    final versions = await q.get();
    final List<SearchResultItem> items = [];

    for (final v in versions) {
      // Try to find parent file info
      final fileQuery = db.select(db.backupFiles)..where((t) => t.id.equals(v.fileId));
      final parentFile = await fileQuery.getSingleOrNull();

      items.add(SearchResultItem(
        id: 'version_${v.id}',
        type: SearchResultType.version,
        title: parentFile != null ? '${parentFile.fileName} (v${v.versionNumber})' : 'Version #${v.versionNumber}',
        subtitle: 'Backup Path: ${v.backupPath}',
        path: parentFile?.originalPath,
        backupPath: v.backupPath,
        sizeBytes: parentFile?.fileSize,
        date: v.createdAt,
        status: 'success',
        rawData: v,
      ));
    }

    return items;
  }

  /// Search BackupFolders and map them to SearchResultItem
  Future<List<SearchResultItem>> searchFolders(SearchQuery query) async {
    final q = db.select(db.backupFolders);

    if (query.queryText.isNotEmpty) {
      q.where((t) =>
          _buildStringMatch(t.name, query.queryText, query.mode) |
          _buildStringMatch(t.sourcePath, query.queryText, query.mode));
    }

    if (query.filter.folderId != null) {
      q.where((t) => t.id.equals(query.filter.folderId!));
    }

    q.orderBy([
      (t) {
        Expression exp;
        switch (query.sort.field) {
          case SortField.name:
            exp = t.name;
            break;
          case SortField.date:
          default:
            exp = t.createdAt;
            break;
        }
        return OrderingTerm(
          expression: exp,
          mode: query.sort.order == SortOrder.ascending ? OrderingMode.asc : OrderingMode.desc,
        );
      }
    ]);

    final folders = await q.get();
    return folders.map((f) {
      return SearchResultItem(
        id: 'folder_${f.id}',
        type: SearchResultType.folder,
        title: f.name,
        subtitle: f.sourcePath,
        path: f.sourcePath,
        backupPath: f.destinationPath,
        date: f.createdAt,
        status: f.enabled ? 'success' : 'warning',
        rawData: f,
      );
    }).toList();
  }

  /// Search BackupLogs and map them to SearchResultItem
  Future<List<SearchResultItem>> searchLogs(SearchQuery query) async {
    final q = db.select(db.backupLogs);

    if (query.queryText.isNotEmpty) {
      q.where((t) =>
          _buildStringMatch(t.message, query.queryText, query.mode) |
          _buildStringMatch(t.tag, query.queryText, query.mode));
    }

    if (query.filter.logLevel != null) {
      q.where((t) => t.logType.equals(query.filter.logLevel!));
    }
    if (query.filter.startDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(query.filter.startDate!));
    }
    if (query.filter.endDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(query.filter.endDate!));
    }

    q.orderBy([
      (t) => OrderingTerm(
            expression: t.createdAt,
            mode: query.sort.order == SortOrder.ascending ? OrderingMode.asc : OrderingMode.desc,
          )
    ]);

    q.limit(query.limit, offset: (query.page - 1) * query.limit);

    final logs = await q.get();
    return logs.map((l) {
      return SearchResultItem(
        id: 'log_${l.id}',
        type: SearchResultType.log,
        title: l.message,
        subtitle: 'Tag: ${l.tag ?? 'General'} | Level: ${l.logType.toUpperCase()}',
        date: l.createdAt,
        status: l.logType == 'error' ? 'failed' : (l.logType == 'warning' ? 'warning' : 'info'),
        rawData: l,
      );
    }).toList();
  }

  /// Search BackupHistory runs
  Future<List<SearchResultItem>> searchBackupHistory(SearchQuery query) async {
    final q = db.select(db.backupHistory);

    if (query.queryText.isNotEmpty) {
      q.where((t) => _buildStringMatch(t.message, query.queryText, query.mode));
    }

    if (query.filter.folderId != null) {
      q.where((t) => t.folderId.equals(query.filter.folderId!));
    }
    if (query.filter.backupStatus != null) {
      q.where((t) => t.status.equals(query.filter.backupStatus!));
    }
    if (query.filter.startDate != null) {
      q.where((t) => t.timestamp.isBiggerOrEqualValue(query.filter.startDate!));
    }
    if (query.filter.endDate != null) {
      q.where((t) => t.timestamp.isSmallerOrEqualValue(query.filter.endDate!));
    }

    q.orderBy([
      (t) => OrderingTerm(
            expression: t.timestamp,
            mode: query.sort.order == SortOrder.ascending ? OrderingMode.asc : OrderingMode.desc,
          )
    ]);

    q.limit(query.limit, offset: (query.page - 1) * query.limit);

    final history = await q.get();
    return history.map((h) {
      return SearchResultItem(
        id: 'history_${h.id}',
        type: SearchResultType.backupJob,
        title: 'Backup Run #${h.id} (${h.backupType.toUpperCase()})',
        subtitle: h.message,
        date: h.timestamp,
        status: h.status == 'success' ? 'success' : (h.status == 'failed' ? 'failed' : 'info'),
        rawData: h,
      );
    }).toList();
  }

  // ==========================================
  // SEARCH HISTORY OPERATIONS
  // ==========================================

  Future<List<SearchHistory>> getSearchHistory({int limit = 50}) {
    return db.searchHistoriesDao.getRecentSearchHistory(limit: limit);
  }

  Future<void> addSearchHistory(String queryText) async {
    if (queryText.trim().isEmpty) return;
    
    // Check if query already exists
    final existing = await (db.select(db.searchHistories)
      ..where((t) => t.query.equals(queryText.trim())))
      .getSingleOrNull();

    if (existing != null) {
      // Just update timestamp
      await db.searchHistoriesDao.updateSearchHistory(
        existing.copyWith(createdAt: DateTime.now()),
      );
    } else {
      await db.searchHistoriesDao.insertSearchHistory(
        SearchHistoriesCompanion.insert(
          query: queryText.trim(),
          createdAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> togglePinSearchHistory(SearchHistory item) async {
    await db.searchHistoriesDao.updateSearchHistory(
      item.copyWith(pinned: !item.pinned),
    );
  }

  Future<void> deleteSearchHistory(int id) async {
    await db.searchHistoriesDao.deleteSearchHistoryById(id);
  }

  Future<void> clearSearchHistory() async {
    await db.searchHistoriesDao.clearSearchHistory();
  }
}
