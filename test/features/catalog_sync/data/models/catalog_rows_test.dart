import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

import '../../../../helpers/fake_catalog_remote.dart';

void main() {
  final item = sampleItems().first;
  final category = sampleCategories().first;

  group('items', () {
    test('a valid row becomes an item', () {
      final parsed = CatalogRows.item(item)!;
      expect(parsed.menuName, 'Espresso');
      expect(parsed.menuNameAr, 'إسبريسو');
      expect(parsed.calories, 3);
      expect(parsed.traits['temp'], 'hot');
    });

    test('numbers sent as whole doubles are accepted', () {
      expect(CatalogRows.item({...item, 'calories': 190.0})!.calories, 190);
    });

    final hostile = <String, Map<String, Object?>>{
      'not a map': {},
      'missing id': {...item}..remove('id'),
      'id is not a uuid': {...item, 'id': "1' OR '1'='1"},
      'slug with SQL': {...item, 'slug': 'x; DROP TABLE items'},
      'slug with capitals': {...item, 'slug': 'Latte'},
      'empty name': {...item, 'menu_name': '   '},
      'name too long': {...item, 'menu_name': 'A' * 81},
      'explanation too long': {...item, 'explanation_ar': 'ق' * 301},
      'name is a number': {...item, 'menu_name': 42},
      'calories is text': {...item, 'calories': 'lots'},
      'negative calories': {...item, 'calories': -1},
      'absurd calories': {...item, 'calories': 99999},
      'fractional size': {...item, 'size_ml': 1.5},
      'upside-down price': {...item, 'price_min_egp': 90, 'price_max_egp': 10},
      'traits is a list': {
        ...item,
        'traits': <Object?>[1, 2],
      },
    };
    for (final MapEntry(:key, :value) in hostile.entries) {
      test('rejects: $key', () {
        expect(CatalogRows.item(key == 'not a map' ? 'nope' : value), isNull);
      });
    }

    test('the «يعني» line is read; a broken one is dropped, the item kept', () {
      expect(
        CatalogRows.item({...item, 'gist_ar': ' قهوة بلبن كتير '})!.gistAr,
        'قهوة بلبن كتير',
      );
      for (final bad in <Object?>['', '   ', 'ق' * 61, 42, <Object?>[]]) {
        final parsed = CatalogRows.item({...item, 'gist_en': bad});
        expect(parsed, isNotNull, reason: '$bad');
        expect(parsed!.gistEn, isNull, reason: '$bad');
      }
      // Shown as plain text, never run: an injection-like line stays text.
      const sneaky = "<script>x</script>'; DROP TABLE items;--";
      expect(CatalogRows.item({...item, 'gist_en': sneaky})!.gistEn, sneaky);
    });

    test('unsafe media paths are dropped, the item is kept', () {
      for (final path in ['../secret', '/etc/passwd', 'a' * 301]) {
        final parsed = CatalogRows.item({...item, 'image_path': path})!;
        expect(parsed.imagePath, isNull, reason: path);
      }
      expect(
        CatalogRows.item({...item, 'image_path': 'latte.webp'})!.imagePath,
        'latte.webp',
      );
    });
  });

  group('categories', () {
    test('a section keeps its trait schema', () {
      final parsed = CatalogRows.category(category)!;
      expect(parsed.isSection, isTrue);
      expect(parsed.traitSchema, isNotEmpty);
    });

    test('rejects broken rows', () {
      expect(CatalogRows.category({...category, 'slug': 'Bad Slug'}), isNull);
      expect(CatalogRows.category({...category, 'name_ar': ''}), isNull);
      expect(
        CatalogRows.category({...category, 'trait_schema': 'oops'}),
        isNull,
      );
      expect(
        CatalogRows.category({...category, 'parent_id': 'not-a-uuid'}),
        isNull,
      );
    });
  });

  group('terms and removals', () {
    test('a valid term', () {
      final parsed = CatalogRows.term({
        'item_id': fakeId(1),
        'term': 'قهوة',
        'lang': 'ar',
        'kind': 'ingredient',
      })!;
      expect(parsed.$1, fakeId(1));
      expect(parsed.$2.lang, TermLang.ar);
      expect(parsed.$2.kind, TermKind.ingredient);
    });

    test('rejects unknown languages and long terms', () {
      expect(
        CatalogRows.term({'item_id': fakeId(1), 'term': 'x', 'lang': 'xx'}),
        isNull,
      );
      expect(
        CatalogRows.term({
          'item_id': fakeId(1),
          'term': 'x' * 61,
          'lang': 'en',
        }),
        isNull,
      );
    });

    test('removals are categories or items only', () {
      expect(CatalogRows.removed({'kind': 'item', 'id': fakeId(3)}), isNotNull);
      expect(CatalogRows.removed({'kind': 'user', 'id': fakeId(3)}), isNull);
      expect(CatalogRows.removed({'kind': 'item', 'id': 'x'}), isNull);
    });

    test('broken JSON decodes to null', () {
      expect(CatalogRows.decode('{oops'), isNull);
      expect(CatalogRows.decode(null), isNull);
      expect(CatalogRows.decode('{"a":1}'), {'a': 1});
    });
  });
}
