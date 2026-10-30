import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/smart_search/domain/entities/search_text.dart';
import 'package:yaani_eh/features/smart_search/domain/usecases/search_menu.dart';

import '../../../helpers/fake_catalog_remote.dart';

/// The sample drinks plus a few search terms, like the real seed.
List<CatalogItem> _items() {
  final terms = <String, List<ItemTerm>>{
    'latte': const [
      ItemTerm(term: 'لبن', lang: TermLang.ar, kind: TermKind.ingredient),
      ItemTerm(term: 'قهوة', lang: TermLang.ar, kind: TermKind.ingredient),
      ItemTerm(
        term: 'laban w ahwa',
        lang: TermLang.franco,
        kind: TermKind.name,
      ),
    ],
    'espresso': const [
      ItemTerm(term: '2ahwa', lang: TermLang.franco, kind: TermKind.name),
    ],
  };
  return [
    for (final row in sampleItems())
      () {
        final item = CatalogRows.item(row)!;
        return CatalogItem(
          id: item.id,
          categoryId: item.categoryId,
          slug: item.slug,
          menuName: item.menuName,
          menuNameAr: item.menuNameAr,
          explanationAr: item.explanationAr,
          explanationEn: item.explanationEn,
          calories: item.calories,
          traits: item.traits,
          sortOrder: item.sortOrder,
          terms: terms[item.slug] ?? const [],
        );
      }(),
  ];
}

void main() {
  group(SearchText, () {
    test('Arabic letter families, diacritics and tatweel', () {
      expect(SearchText.normalize('أفوجاتو'), 'افوجاتو');
      expect(SearchText.normalize('قَهْوَة'), 'قهوه');
      expect(SearchText.normalize('قهـــوة'), 'قهوه');
      expect(SearchText.normalize('كركديه'), SearchText.normalize('كَركَدِيه'));
      expect(SearchText.normalize('مستوى'), 'مستوي');
    });

    test('Latin case and accents; Franco digits stay', () {
      expect(SearchText.normalize('Frappé'), 'frappe');
      expect(SearchText.normalize('CAFÉ  Latte!'), 'cafe latte');
      expect(SearchText.normalize('2ahwa'), '2ahwa');
    });

    test('light Arabic prefixes', () {
      expect(SearchText.tokens('القهوة'), ['قهوه']);
      expect(SearchText.tokens('وقهوة'), ['قهوه']);
      expect(SearchText.tokens('بالتلج'), ['تلج']);
      expect(SearchText.tokens('لبن وقهوة'), ['لبن', 'قهوه']);
    });

    test('matching: exact, prefix, one typo for longer words', () {
      expect(SearchText.match('latte', 'latte'), 1);
      expect(SearchText.match('lat', 'latte'), 0.8);
      expect(SearchText.match('lattee', 'latte'), 0.6);
      expect(SearchText.match('lta', 'latte'), 0);
      expect(
        SearchText.match('cat', 'bat'),
        0,
        reason: 'short words exact only',
      );
    });

    test('word positions for highlighting', () {
      final words = SearchText.words('إسبريسو بلبن سخن');
      expect(words.map((w) => w.token), ['اسبريسو', 'لبن', 'سخن']);
      expect(words[1].start, 8);
    });
  });

  group(SearchMenu, () {
    final search = SearchMenu(_items());

    test('a name gets an answer, in any script', () {
      for (final query in ['Latte', 'latte', 'لاتيه', 'لاتيه ', 'LATTE']) {
        final results = search(query);
        expect(results.answer?.item.slug, 'latte', reason: query);
      }
    });

    test('one typo still finds the name', () {
      expect(search('cortadoo').answer?.item.slug, 'cortado');
      expect(search('كابتشنو').answer?.item.slug, 'cappuccino');
    });

    test('prefixes rank the right drink first while typing', () {
      final results = search('cap');
      final first = results.answer ?? results.hits.first;
      expect(first.item.slug, 'cappuccino');
    });

    test('Franco works', () {
      final results = search('2ahwa');
      expect([
        results.answer?.item.slug,
        ...results.hits.map((h) => h.item.slug),
      ], contains('espresso'));
    });

    test('a description gets a ranked list, no answer', () {
      final results = search('لبن وقهوة');
      expect(results.answer, isNull);
      expect(results.hits, isNotEmpty);
      expect(results.hits.first.byName, isFalse);
      expect(results.hits.first.matched, contains('لبن'));
    });

    test('names outrank descriptions; variants follow the answer', () {
      final results = search('latte');
      expect(results.answer!.item.slug, 'latte');
      expect(
        results.hits.map((h) => h.item.slug),
        containsAll(['spanish_latte', 'iced_latte']),
      );
    });

    test('boosts (favorites, taste) reorder equal matches', () {
      final plain = search('iced');
      final boosted = search('iced', boosts: const _Boost({'iced_mocha'}));
      expect(plain.hits.first.item.slug, isNot('iced_mocha'));
      expect(boosted.hits.first.item.slug, 'iced_mocha');
    });

    test('nothing for every word: no results, "did you mean" instead', () {
      final results = search('سبانيش كورتادو');
      expect(results.isEmpty, isTrue);
      expect(
        results.suggestions.map((i) => i.slug),
        containsAll(['cortado', 'spanish_latte']),
      );
    });

    group('hostile or odd input never crashes', () {
      for (final query in [
        '',
        '   ',
        '!!!???',
        "'; DROP TABLE items; --",
        '<script>alert(1)</script>',
        'a' * 10000,
        '😀☕️',
        '\u202Eetal\u202C',
        r'.*+?^${}()|[]\',
        'ـــــ',
      ]) {
        test(query.length > 30 ? '${query.substring(0, 20)}…' : query, () {
          final results = search(query);
          expect(
            results.query.length,
            lessThanOrEqualTo(SearchMenu.maxQueryLength),
          );
        });
      }
    });

    test('an empty catalog finds nothing', () {
      expect(SearchMenu(const [])('latte').isEmpty, isTrue);
    });
  });
}

class _Boost implements SearchBoosts {
  const new(this.slugs);

  final Set<String> slugs;

  @override
  double boost(CatalogItem item) => slugs.contains(item.slug) ? 0.5 : 0;
}
