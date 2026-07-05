import 'search_models.dart';
import 'search_repository.dart';
import 'package:backup_vault/core/database/app_database.dart';

class SearchService {
  final SearchRepository repository;

  SearchService(this.repository);

  /// Search across all sources with filters and sorting
  Future<List<SearchResultItem>> search({
    required SearchQuery query,
    bool includeFiles = true,
    bool includeVersions = true,
    bool includeFolders = true,
    bool includeLogs = true,
    bool includeHistory = true,
  }) async {
    final List<Future<List<SearchResultItem>>> futures = [];

    if (includeFiles) futures.add(repository.searchFiles(query));
    if (includeVersions) futures.add(repository.searchVersions(query));
    if (includeFolders) futures.add(repository.searchFolders(query));
    if (includeLogs) futures.add(repository.searchLogs(query));
    if (includeHistory) futures.add(repository.searchBackupHistory(query));

    final resultsList = await Future.wait(futures);
    final allResults = resultsList.expand((list) => list).toList();

    // Sort aggregated results based on query sort
    allResults.sort((a, b) {
      int cmp = 0;
      switch (query.sort.field) {
        case SortField.name:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortField.size:
          final sizeA = a.sizeBytes ?? 0;
          final sizeB = b.sizeBytes ?? 0;
          cmp = sizeA.compareTo(sizeB);
          break;
        case SortField.folder:
          final subA = a.subtitle ?? '';
          final subB = b.subtitle ?? '';
          cmp = subA.toLowerCase().compareTo(subB.toLowerCase());
          break;
        case SortField.status:
          cmp = a.status.compareTo(b.status);
          break;
        case SortField.date:
          cmp = a.date.compareTo(b.date);
          break;
      }
      return query.sort.order == SortOrder.ascending ? cmp : -cmp;
    });

    return allResults;
  }

  /// Get suggestions (recent + popular extensions)
  Future<List<String>> getSuggestions(String partialQuery) async {
    final history = await repository.getSearchHistory();
    final List<String> suggestions = [];

    // Add matching history
    for (final item in history) {
      if (item.query.toLowerCase().contains(partialQuery.toLowerCase())) {
        suggestions.add(item.query);
      }
    }

    // Common/popular filters & searches
    final popular = ['zip', 'pdf', 'png', 'jpg', 'log', 'db', 'backup', 'txt', 'mp4', 'json'];
    for (final pop in popular) {
      if (pop.toLowerCase().startsWith(partialQuery.toLowerCase()) || 
          '.$pop'.startsWith(partialQuery.toLowerCase())) {
        suggestions.add('.$pop');
      }
    }

    // Add default suggestions if empty
    if (suggestions.isEmpty && partialQuery.isEmpty) {
      suggestions.addAll(history.map((h) => h.query));
      suggestions.addAll(['.zip', '.pdf', '.log']);
    }

    return suggestions.toSet().toList().take(8).toList();
  }

  // ==========================================
  // HISTORY DELEGATES
  // ==========================================

  Future<List<SearchHistory>> getHistory() => repository.getSearchHistory();

  Future<void> addHistory(String queryText) => repository.addSearchHistory(queryText);

  Future<void> togglePinHistory(SearchHistory item) => repository.togglePinSearchHistory(item);

  Future<void> deleteHistory(int id) => repository.deleteSearchHistory(id);

  Future<void> clearHistory() => repository.clearSearchHistory();
}
