
enum SearchMode {
  instant,
  advanced,
  wildcard,
  exactMatch,
  contains,
  startsWith,
  endsWith,
}

enum SortField {
  name,
  date,
  size,
  folder,
  status,
}

enum SortOrder {
  ascending,
  descending,
}

class SearchSort {
  final SortField field;
  final SortOrder order;

  const SearchSort({
    this.field = SortField.date,
    this.order = SortOrder.descending,
  });

  SearchSort copyWith({
    SortField? field,
    SortOrder? order,
  }) {
    return SearchSort(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }
}

class SearchFilter {
  final int? folderId;
  final String? fileType; // extension
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minSize;
  final int? maxSize;
  final String? backupStatus; // success, failed, pending
  final String? restoreStatus; // success, failed, pending
  final String? workerId;
  final String? logLevel; // info, warning, error

  const SearchFilter({
    this.folderId,
    this.fileType,
    this.startDate,
    this.endDate,
    this.minSize,
    this.maxSize,
    this.backupStatus,
    this.restoreStatus,
    this.workerId,
    this.logLevel,
  });

  SearchFilter copyWith({
    int? folderId,
    String? fileType,
    DateTime? startDate,
    DateTime? endDate,
    int? minSize,
    int? maxSize,
    String? backupStatus,
    String? restoreStatus,
    String? workerId,
    String? logLevel,
  }) {
    return SearchFilter(
      folderId: folderId ?? this.folderId,
      fileType: fileType ?? this.fileType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      backupStatus: backupStatus ?? this.backupStatus,
      restoreStatus: restoreStatus ?? this.restoreStatus,
      workerId: workerId ?? this.workerId,
      logLevel: logLevel ?? this.logLevel,
    );
  }

  bool get isEmpty =>
      folderId == null &&
      fileType == null &&
      startDate == null &&
      endDate == null &&
      minSize == null &&
      maxSize == null &&
      backupStatus == null &&
      restoreStatus == null &&
      workerId == null &&
      logLevel == null;
}

class SearchQuery {
  final String queryText;
  final SearchMode mode;
  final SearchFilter filter;
  final SearchSort sort;
  final int page;
  final int limit;

  const SearchQuery({
    this.queryText = '',
    this.mode = SearchMode.contains,
    this.filter = const SearchFilter(),
    this.sort = const SearchSort(),
    this.page = 1,
    this.limit = 50,
  });

  SearchQuery copyWith({
    String? queryText,
    SearchMode? mode,
    SearchFilter? filter,
    SearchSort? sort,
    int? page,
    int? limit,
  }) {
    return SearchQuery(
      queryText: queryText ?? this.queryText,
      mode: mode ?? this.mode,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

enum SearchResultType {
  file,
  version,
  folder,
  log,
  backupJob,
  restoreJob,
}

class SearchResultItem {
  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? path;
  final String? backupPath;
  final int? sizeBytes;
  final DateTime date;
  final String status; // success, failed, warning, info, error
  final int versionCount;
  final String? workerId;
  final dynamic rawData;

  const SearchResultItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.path,
    this.backupPath,
    this.sizeBytes,
    required this.date,
    required this.status,
    this.versionCount = 0,
    this.workerId,
    this.rawData,
  });
}
