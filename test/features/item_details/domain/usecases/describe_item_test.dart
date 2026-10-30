import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';

import '../../../../helpers/fake_catalog_remote.dart';
import '../../../../helpers/fake_catalog_repository.dart';

CatalogItem _item(Map<String, Object?> changes) =>
    CatalogRows.item({...sampleItems()[2], ...changes})!; // Flat White

void main() {
  const describe = DescribeItem();
  final now = DateTime(2026, 10, 30);

  group(DescribeItem, () {
    test('traits come from the section schema, in the reader language', () {
      final item = _item({
        'traits': {'temp': 'hot', 'sweetness': 0, 'milk': true, 'caffeine': 3},
      });
      final ar = describe(
        item: item,
        traitSchema: cafeTraitSchema,
        lang: 'ar',
        now: now,
      );
      final en = describe(
        item: item,
        traitSchema: cafeTraitSchema,
        lang: 'en',
        now: now,
      );
      expect(ar.traits, ['سخن', 'سادة', 'بلبن', 'قوي']);
      expect(en.traits, ['Hot', 'Not sweet', 'With milk', 'Strong']);
      expect(ar.calories, 110);
    });

    test('missing values and unknown trait types are skipped', () {
      final item = _item({
        'traits': {'temp': 'lukewarm', 'caffeine': 9, 'foam': 'lots'},
      });
      final facts = describe(
        item: item,
        traitSchema: [
          ...cafeTraitSchema,
          {'key': 'foam', 'type': 'hologram'},
        ],
        lang: 'en',
        now: now,
      );
      expect(facts.traits, isEmpty);
    });

    test('a hostile or broken schema never crashes', () {
      final item = _item({
        'traits': {'temp': 'hot', 'milk': true, 'sweetness': 1},
      });
      for (final schema in <List<Object?>?>[
        null,
        [],
        ['not a map', 42, null],
        [
          {'key': 'temp', 'type': 'enum', 'options': 'nope'},
          {
            'key': 'milk',
            'type': 'bool',
            'labels': {
              'en': ['only one'],
            },
          },
          {
            'key': 'sweetness',
            'type': 'scale',
            'labels': {
              'en': ['x', 'A' * 500],
            },
          },
        ],
      ]) {
        expect(
          describe(
            item: item,
            traitSchema: schema,
            lang: 'en',
            now: now,
          ).traits,
          isEmpty,
          reason: '$schema',
        );
      }
    });

    test('prices: none, fresh, stale after 90 days, undated', () {
      expect(
        describe(
          item: _item({}),
          traitSchema: null,
          lang: 'ar',
          now: now,
        ).hasPrice,
        isFalse,
      );
      final fresh = describe(
        item: _item({
          'price_min_egp': 70,
          'price_max_egp': 150,
          'price_updated_at': '2026-09-01',
        }),
        traitSchema: null,
        lang: 'ar',
        now: now,
      );
      expect(fresh.hasPrice, isTrue);
      expect(fresh.priceIsStale, isFalse);
      expect(fresh.priceMax, 150);

      final stale = describe(
        item: _item({'price_min_egp': 70, 'price_updated_at': '2026-06-01'}),
        traitSchema: null,
        lang: 'ar',
        now: now,
      );
      expect(stale.priceIsStale, isTrue);
      expect(stale.priceMax, 70, reason: 'a single price');

      final undated = describe(
        item: _item({'price_min_egp': 70}),
        traitSchema: null,
        lang: 'ar',
        now: now,
      );
      expect(undated.priceIsStale, isTrue);
    });
  });

  group(SimilarItems, () {
    test('same category and closest taste first, never itself', () {
      final items = sampleCatalogItems();
      final flatWhite = items.firstWhere((i) => i.slug == 'flat_white');
      final similar = const SimilarItems()(flatWhite, items, max: 4);
      expect(similar, hasLength(4));
      expect(similar.map((i) => i.slug), isNot(contains('flat_white')));
      expect(
        similar.every((i) => i.categoryId == flatWhite.categoryId),
        isTrue,
      );
    });

    test('an iced drink suggests iced drinks first', () {
      final items = sampleCatalogItems();
      final coldBrew = items.firstWhere((i) => i.slug == 'cold_brew');
      final similar = const SimilarItems()(coldBrew, items, max: 3);
      expect(similar.every((i) => i.traits['temp'] == 'cold'), isTrue);
    });

    test('a menu of one has no similar drinks', () {
      final one = [sampleCatalogItems().first];
      expect(const SimilarItems()(one.first, one), isEmpty);
    });
  });
}
