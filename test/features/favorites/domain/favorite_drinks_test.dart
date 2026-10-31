import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/favorites/domain/entities/favorite.dart';
import 'package:yaani_eh/features/favorites/domain/usecases/favorite_drinks.dart';

import '../../../helpers/fake_catalog_repository.dart';

void main() {
  final items = sampleCatalogItems();

  test('saved drinks still on the menu, newest first', () {
    final drinks = const FavoriteDrinks()(
      items: items,
      favorites: [
        Favorite(itemId: items[0].id, savedAt: DateTime.utc(2026, 10, 4)),
        Favorite(itemId: items[2].id, savedAt: DateTime.utc(2026, 10, 6)),
        Favorite(itemId: items[1].id, savedAt: DateTime.utc(2026, 10, 5)),
      ],
    );
    expect(drinks, [items[2], items[1], items[0]]);
  });

  test('the same date keeps the order they came in', () {
    final same = DateTime.utc(2026, 10, 4);
    final drinks = const FavoriteDrinks()(
      items: items,
      favorites: [
        for (final i in [3, 0, 2, 1])
          Favorite(itemId: items[i].id, savedAt: same),
      ],
    );
    expect(drinks, [items[3], items[0], items[2], items[1]]);
  });

  test('a drink taken off the menu is left out', () {
    final drinks = const FavoriteDrinks()(
      items: items,
      favorites: [
        Favorite(itemId: items[0].id, savedAt: DateTime.utc(2026, 10, 4)),
        Favorite(itemId: 'gone', savedAt: DateTime.utc(2026, 10, 5)),
      ],
    );
    expect(drinks, [items[0]]);
  });
}
