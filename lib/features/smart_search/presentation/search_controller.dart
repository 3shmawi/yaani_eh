import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/smart_search/domain/usecases/search_menu.dart';

/// The search index, rebuilt whenever the catalog syncs.
final searchIndexProvider = Provider<SearchMenu?>((ref) {
  final items = ref.watch(catalogItemsProvider).value;
  return items == null ? null : SearchMenu(items);
});

/// Ranking signals; favorites and taste plug in here with their features.
final searchBoostsProvider = Provider<SearchBoosts>((ref) => const NoBoosts());

/// What the reader typed (debounced by the page).
final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  // A setter would read oddly at call sites (`notifier.set(q)` is clearer).
  // ignore: use_setters_to_change_properties
  void set(String query) => state = query;
}

/// Results for the current query; null while the index loads.
final searchResultsProvider = Provider<SearchResults?>((ref) {
  final index = ref.watch(searchIndexProvider);
  if (index == null) return null;
  return index(
    ref.watch(searchQueryProvider),
    boosts: ref.watch(searchBoostsProvider),
  );
});
