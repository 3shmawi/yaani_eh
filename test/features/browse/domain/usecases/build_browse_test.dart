import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

import '../../../../helpers/fake_catalog_remote.dart';
import '../../../../helpers/fake_catalog_repository.dart';

void main() {
  final items = sampleCatalogItems();
  final categories = [
    for (final r in sampleCategories()) CatalogRows.category(r)!,
  ];
  final day = DateTime(2026, 10, 30);

  const cakes = CatalogCategory(
    id: '00000000-0000-4000-8000-0000000c0009',
    parentId: dessertsId,
    slug: 'cakes',
    nameAr: 'كيك',
    nameEn: 'Cakes',
  );
  final cheesecake = CatalogItem(
    id: fakeId(900),
    categoryId: cakes.id,
    slug: 'cheesecake',
    menuName: 'Cheesecake',
    menuNameAr: 'تشيز كيك',
    explanationAr: 'كيكة بالجبنة الكريمي.',
    explanationEn: 'A cream cheese cake.',
  );

  group(BuildHub, () {
    const hub = BuildHub();

    test('one tab per section, in order, with its count', () {
      final model = hub(items: items, categories: categories);

      expect(model.sections.map((s) => s.section.slug), ['cafe', 'desserts']);
      final cafe = model.sections.first;
      expect(cafe.count, 12);
      expect(cafe.hasItems, isTrue);
      expect(model.isEmpty, isFalse);
    });

    test('a section without items is coming soon, still listed', () {
      final model = hub(items: items, categories: categories);
      final desserts = model.sections.last;
      expect(desserts.hasItems, isFalse);
      expect(desserts.count, 0);
    });

    test('a new section shows up with no code change', () {
      const terms = CatalogCategory(
        id: '00000000-0000-4000-8000-0000000c0010',
        slug: 'terms',
        nameAr: 'مصطلحات',
        nameEn: 'Terms',
        icon: 'book',
        sortOrder: 2,
      );
      final model = hub(
        items: [...items, cheesecake],
        categories: [...categories, cakes, terms],
      );
      expect(model.sections.map((s) => s.section.slug), [
        'cafe',
        'desserts',
        'terms',
      ]);
      expect(model.sections[1].count, 1);
      expect(model.sections[2].hasItems, isFalse);
    });

    test('nothing on the device: empty', () {
      final model = hub(items: const [], categories: categories);
      expect(model.isEmpty, isTrue);
      final none = hub(items: const [], categories: const []);
      expect(none.sections, isEmpty);
    });

    test('items in a category of no section are left out', () {
      final orphan = CatalogItem(
        id: fakeId(901),
        categoryId: '00000000-0000-4000-8000-0000000c0099',
        slug: 'orphan',
        menuName: 'Orphan',
        menuNameAr: 'يتيم',
        explanationAr: '.',
        explanationEn: '.',
      );
      final model = hub(items: [...items, orphan], categories: categories);
      expect(model.sections.first.count, 12);
    });
  });

  group(BuildBrowse, () {
    const build = BuildBrowse();

    test('a section by its slug: all its categories with items', () {
      final menu = build(
        slug: 'cafe',
        items: items,
        categories: categories,
        today: day,
      )!;
      expect(menu.section.id, cafeId);
      expect(menu.chips.map((c) => c.slug), ['coffee', 'iced_coffee']);
      expect(menu.sections, hasLength(2));
      expect(menu.sections.first.items, hasLength(8));
      expect(menu.sections.last.items, hasLength(4));
      expect(menu.count, 12);
      expect(menu.itemOfTheDay, isNotNull);
      expect(menu.comingSoon, isFalse);
    });

    test('a section without items is coming soon', () {
      final menu = build(
        slug: 'desserts',
        items: items,
        categories: categories,
        today: day,
      )!;
      expect(menu.comingSoon, isTrue);
      expect(menu.chips, isEmpty);
      expect(menu.itemOfTheDay, isNull);
    });

    test('desserts goes live with its first dessert', () {
      final menu = build(
        slug: 'desserts',
        items: [...items, cheesecake],
        categories: [...categories, cakes],
        today: day,
      )!;
      expect(menu.comingSoon, isFalse);
      expect(menu.chips.single.slug, 'cakes');
      expect(menu.itemOfTheDay?.slug, 'cheesecake');
    });

    test('an unknown slug, or a category slug, is no section', () {
      for (final slug in ['no_such', 'coffee', '', 'CAFE']) {
        expect(
          build(slug: slug, items: items, categories: categories, today: day),
          isNull,
          reason: slug,
        );
      }
    });

    test('empty categories get no chip', () {
      final extra = [
        ...categories,
        const CatalogCategory(
          id: '00000000-0000-4000-8000-0000000c0008',
          parentId: cafeId,
          slug: 'smoothies',
          nameAr: 'سموذي',
          nameEn: 'Smoothies',
          sortOrder: 9,
        ),
      ];
      final menu = build(
        slug: 'cafe',
        items: items,
        categories: extra,
        today: day,
      )!;
      expect(menu.chips.map((c) => c.slug), isNot(contains('smoothies')));
    });

    test('the item of the day is stable all day and changes daily', () {
      CatalogItem? pick(DateTime t) => build(
        slug: 'cafe',
        items: items,
        categories: categories,
        today: t,
      )!.itemOfTheDay;
      expect(pick(DateTime(2026, 10, 30, 8)), pick(DateTime(2026, 10, 30, 23)));
      final week = {
        for (var d = 0; d < 7; d++) pick(DateTime(2026, 11, 1 + d))!.slug,
      };
      expect(week.length, greaterThan(1));
    });

    group('pages', () {
      // 40 coffees then 30 iced coffees: 70 items, three pages of 24.
      final many = [
        for (var i = 0; i < 70; i++)
          CatalogItem(
            id: fakeId(1000 + i),
            categoryId: i < 40 ? coffeeId : coldId,
            slug: 'item_$i',
            menuName: 'Item $i',
            menuNameAr: 'صنف $i',
            explanationAr: '.',
            explanationEn: '.',
          ),
      ];
      final model = build(
        slug: 'cafe',
        items: many,
        categories: categories,
        today: day,
      )!;
      const page = BrowseModel.pageSize;

      List<int> sizes(int limit) => [
        for (final s in model.firstItems(limit)) s.items.length,
      ];

      test('the first page is cut at the page size, in menu order', () {
        expect(model.count, 70);
        expect(sizes(page), [page]);
        expect(model.firstItems(page).single.items.first.slug, 'item_0');
        expect(model.firstItems(page).single.items.last.slug, 'item_23');
      });

      test('a page that crosses a category continues in the next one', () {
        expect(sizes(page * 2), [40, page * 2 - 40]);
        expect(model.firstItems(page * 2).last.items.first.slug, 'item_40');
      });

      test('a limit past the end shows everything, nothing twice', () {
        expect(sizes(1000), [40, 30]);
        expect(sizes(70), [40, 30]);
      });

      test('nothing for a limit of zero or less', () {
        expect(model.firstItems(0), isEmpty);
        expect(model.firstItems(-5), isEmpty);
      });

      test('a chip past the built items asks for enough to reach it', () {
        final cold = model.chips.last;
        // 40 items come before it: its heading is built at 40 + a page.
        expect(model.limitFor(cold.id), 40 + page);
        expect(model.limitFor(model.chips.first.id), page);
        // The first category is always inside the first page.
        expect(model.firstItems(page).map((s) => s.category.id), [
          model.chips.first.id,
        ]);
        expect(
          model.firstItems(model.limitFor(cold.id)).map((s) => s.category.id),
          contains(cold.id),
        );
        // An id that isn't a chip needs nothing more.
        expect(model.limitFor('no-such-category'), page);
      });

      test('a small section fits in its first page', () {
        final small = build(
          slug: 'cafe',
          items: items,
          categories: categories,
          today: day,
        )!;
        expect(small.count, lessThan(page));
        expect(small.firstItems(page).map((s) => s.items.length), [8, 4]);
      });
    });
  });
}
