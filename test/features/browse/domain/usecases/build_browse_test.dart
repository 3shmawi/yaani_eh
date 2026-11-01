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

    test('one card per section, in order, with count and examples', () {
      final model = hub(items: items, categories: categories, today: day);

      expect(model.sections.map((s) => s.section.slug), ['cafe', 'desserts']);
      final cafe = model.sections.first;
      expect(cafe.count, 12);
      expect(cafe.hasItems, isTrue);
      expect(cafe.examples, hasLength(BuildHub.examples));
      // The first items in menu order: the first category's first items.
      expect(cafe.examples.first.slug, items.first.slug);
      expect(model.itemOfTheDay, isNotNull);
      expect(model.isEmpty, isFalse);
    });

    test('a section without items is coming soon, still listed', () {
      final model = hub(items: items, categories: categories, today: day);
      final desserts = model.sections.last;
      expect(desserts.hasItems, isFalse);
      expect(desserts.count, 0);
      expect(desserts.examples, isEmpty);
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
        today: day,
      );
      expect(model.sections.map((s) => s.section.slug), [
        'cafe',
        'desserts',
        'terms',
      ]);
      expect(model.sections[1].count, 1);
      expect(model.sections[2].hasItems, isFalse);
    });

    test('the item of the day comes from any section', () {
      final picks = {
        for (var d = 0; d < 60; d++)
          hub(
            items: [...items, cheesecake],
            categories: [...categories, cakes],
            today: DateTime(2026, 11, 1 + d),
          ).itemOfTheDay!.slug,
      };
      expect(picks, contains('cheesecake'));
    });

    test('stable all day, changes daily', () {
      CatalogItem? pick(DateTime t) =>
          hub(items: items, categories: categories, today: t).itemOfTheDay;
      expect(pick(DateTime(2026, 10, 30, 8)), pick(DateTime(2026, 10, 30, 23)));
      final week = {
        for (var d = 0; d < 7; d++) pick(DateTime(2026, 11, 1 + d))!.slug,
      };
      expect(week.length, greaterThan(1));
    });

    test('nothing on the device: empty, no item of the day', () {
      final model = hub(items: const [], categories: categories, today: day);
      expect(model.isEmpty, isTrue);
      expect(model.itemOfTheDay, isNull);
      final none = hub(items: const [], categories: const [], today: day);
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
      final model = hub(
        items: [...items, orphan],
        categories: categories,
        today: day,
      );
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
  });
}
