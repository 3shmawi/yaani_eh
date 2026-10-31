import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/favorites/domain/entities/favorite.dart';
import 'package:yaani_eh/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:yaani_eh/features/favorites/domain/usecases/favorite_drinks.dart';

/// Override in tests: `favoritesRepositoryProvider.overrideWithValue(…)`.
final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => Dependencies.favoritesRepository,
);

/// Every saved drink, newest first.
final favoritesProvider = StreamProvider<List<Favorite>>(
  (ref) => ref.watch(favoritesRepositoryProvider).watch(),
);

/// The ids of the saved drinks, for the hearts. Always listened to while
/// the app runs (the tab bar shows the count), so it's never stale when a
/// heart or the preview reads it.
final favoriteIdsProvider = Provider<Set<String>>(
  (ref) => {
    for (final f in ref.watch(favoritesProvider).value ?? const <Favorite>[])
      f.itemId,
  },
);

/// The saved drinks still on the menu, newest first; null while loading.
final favoriteDrinksProvider = Provider<List<CatalogItem>?>((ref) {
  final favorites = ref.watch(favoritesProvider).value;
  final items = ref.watch(catalogItemsProvider).value;
  if (favorites == null || items == null) return null;
  return const FavoriteDrinks()(favorites: favorites, items: items);
});

/// Where a heart was tapped, for analytics.
enum FavoriteSource { card, drinkPage, preview, favorites }

final favoritesControllerProvider = Provider<FavoritesController>(
  FavoritesController.new,
);

class FavoritesController {
  new(this._ref);

  final Ref _ref;

  bool isSaved(CatalogItem item) =>
      _ref.read(favoriteIdsProvider).contains(item.id);

  /// Saves [item], or removes it when it's saved. True when it ends saved.
  Future<bool> toggle(CatalogItem item, FavoriteSource from) async {
    final repository = _ref.read(favoritesRepositoryProvider);
    final save = !isSaved(item);
    final result = save
        ? await repository.add(item.id)
        : await repository.remove(item.id);
    switch (result) {
      case Success():
        unawaited(
          Analytics.capture(save ? 'favorite_added' : 'favorite_removed', {
            'drink': item.slug,
            'from': from.name,
          }),
        );
        return save;
      case Failed():
        // guard already reported anything unexpected to monitoring.
        return !save;
    }
  }
}
