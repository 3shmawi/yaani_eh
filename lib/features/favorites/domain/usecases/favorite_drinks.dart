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
    final sorted = [...favorites]
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return [for (final f in sorted) ?byId[f.itemId]];
  }
}
