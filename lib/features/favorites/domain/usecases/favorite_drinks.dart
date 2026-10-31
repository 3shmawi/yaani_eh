import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/domain/entities/favorite.dart';

/// The saved drinks that are still on the menu, newest first. A saved
/// drink that was hidden or removed in a sync is left out (and comes back
/// if it's published again).
class FavoriteDrinks {
  const new();

  List<CatalogItem> call({
    required List<Favorite> favorites,
    required List<CatalogItem> items,
  }) {
    final byId = {for (final i in items) i.id: i};
    // Newest first; on a tie, the order they came in (the repository's,
    // which knows which was saved last).
    final sorted = [...favorites.indexed]
      ..sort((a, b) {
        final byDate = b.$2.savedAt.compareTo(a.$2.savedAt);
        return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
      });
    return [for (final (_, f) in sorted) ?byId[f.itemId]];
  }
}
