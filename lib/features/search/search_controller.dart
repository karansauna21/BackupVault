import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_models.dart';
import 'search_provider.dart';
import 'package:backup_vault/core/database/app_database.dart';

class SearchController {
  final WidgetRef ref;

  SearchController(this.ref);

  void updateQuery(String queryText) {
    ref.read(searchQueryProvider.notifier).update((state) => state.copyWith(queryText: queryText, page: 1));
  }

  void updateMode(SearchMode mode) {
    ref.read(searchQueryProvider.notifier).update((state) => state.copyWith(mode: mode, page: 1));
  }

  void updateFilter(SearchFilter filter) {
    ref.read(searchQueryProvider.notifier).update((state) => state.copyWith(filter: filter, page: 1));
  }

  void updateSort(SearchSort sort) {
    ref.read(searchQueryProvider.notifier).update((state) => state.copyWith(sort: sort));
  }

  void updateSource(String sourceKey, bool enabled) {
    final currentSources = ref.read(searchSourcesProvider);
    final updated = Map<String, bool>.from(currentSources)..[sourceKey] = enabled;
    ref.read(searchSourcesProvider.notifier).updateSources(updated);
  }

  void nextPage() {
    ref.read(searchQueryProvider.notifier).update((state) => state.copyWith(page: state.page + 1));
  }

  void previousPage() {
    ref.read(searchQueryProvider.notifier).update((state) => state.copyWith(page: (state.page - 1).clamp(1, 99999)));
  }

  void resetFilters() {
    ref.read(searchQueryProvider.notifier).update((state) => state.copyWith(
          filter: const SearchFilter(),
          mode: SearchMode.contains,
        ));
  }

  Future<void> addHistory(String queryText) async {
    final service = ref.read(searchServiceProvider);
    await service.addHistory(queryText);
    ref.invalidate(searchHistoryProvider);
  }

  Future<void> deleteHistory(int id) async {
    final service = ref.read(searchServiceProvider);
    await service.deleteHistory(id);
    ref.invalidate(searchHistoryProvider);
  }

  Future<void> togglePinHistory(SearchHistory item) async {
    final service = ref.read(searchServiceProvider);
    await service.togglePinHistory(item);
    ref.invalidate(searchHistoryProvider);
  }

  Future<void> clearHistory() async {
    final service = ref.read(searchServiceProvider);
    await service.clearHistory();
    ref.invalidate(searchHistoryProvider);
  }

  Future<void> reindexDatabase() async {
    final indexer = ref.read(searchIndexerProvider);
    await indexer.reindexDatabase();
    ref.invalidate(searchIndexerStatsProvider);
  }

  Future<void> optimizeIndexes() async {
    final indexer = ref.read(searchIndexerProvider);
    await indexer.optimizeIndexes();
    ref.invalidate(searchIndexerStatsProvider);
  }
}
