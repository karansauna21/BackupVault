import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import 'search_models.dart';
import 'search_repository.dart';
import 'search_service.dart';
import 'search_indexer.dart';
import 'package:backup_vault/core/database/app_database.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SearchRepository(db);
});

final searchServiceProvider = Provider<SearchService>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchService(repo);
});

final searchIndexerProvider = Provider<SearchIndexer>((ref) {
  final db = ref.watch(databaseProvider);
  return SearchIndexer(db);
});

class SearchSourcesNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return const {
      'files': true,
      'versions': true,
      'folders': true,
      'logs': false,
      'history': false,
    };
  }

  void updateSources(Map<String, bool> updated) {
    state = updated;
  }
}

final searchSourcesProvider = NotifierProvider<SearchSourcesNotifier, Map<String, bool>>(() {
  return SearchSourcesNotifier();
});

class SearchQueryNotifier extends Notifier<SearchQuery> {
  @override
  SearchQuery build() {
    return const SearchQuery();
  }

  void update(SearchQuery Function(SearchQuery) cb) {
    state = cb(state);
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, SearchQuery>(() {
  return SearchQueryNotifier();
});

// Suggestions provider based on partial input
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, partialQuery) async {
  final service = ref.watch(searchServiceProvider);
  return service.getSuggestions(partialQuery);
});

// Search history provider
final searchHistoryProvider = FutureProvider<List<SearchHistory>>((ref) async {
  final service = ref.watch(searchServiceProvider);
  return service.getHistory();
});

// Dynamic live search results
final searchResultsProvider = FutureProvider<List<SearchResultItem>>((ref) async {
  final service = ref.watch(searchServiceProvider);
  final query = ref.watch(searchQueryProvider);
  final sources = ref.watch(searchSourcesProvider);

  // Return empty list if no query and no filters applied
  if (query.queryText.isEmpty && query.filter.isEmpty) {
    return const [];
  }

  return service.search(
    query: query,
    includeFiles: sources['files'] ?? true,
    includeVersions: sources['versions'] ?? true,
    includeFolders: sources['folders'] ?? true,
    includeLogs: sources['logs'] ?? false,
    includeHistory: sources['history'] ?? false,
  );
});

// Indexer stats
final searchIndexerStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final indexer = ref.watch(searchIndexerProvider);
  return indexer.getIndexerStats();
});
