import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/browse_menu/domain/usecases/build_menu.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

import '../../../../helpers/fake_catalog_remote.dart';
import '../../../../helpers/fake_catalog_repository.dart';

void main() {
  const build = BuildMenu();
  final items = sampleCatalogItems();
  final categories = [
    for (final r in sampleCategories()) CatalogRows.category(r)!,
  ];
  final day = DateTime(2026, 10, 30);

  test('opens on the first section with drinks: all its categories', () {
    final menu = build(items: items, categories: categories, today: day);

    expect(menu.tabs.map((t) => t.section.slug), ['cafe', 'desserts']);
    expect(menu.selectedTabId, cafeId);
    expect(menu.chips.map((c) => c.slug), ['coffee', 'iced_coffee']);
    expect(menu.sections, hasLength(2));
    expect(menu.sections.first.items, hasLength(8));
    expect(menu.sections.last.items, hasLength(4));
    expect(menu.drinkOfTheDay, isNotNull);
    expect(menu.comingSoon, isFalse);
    expect(menu.isEmpty, isFalse);
  });

  test('a section without drinks is coming soon', () {
    final menu = build(
      items: items,
      categories: categories,
      today: day,
      selectedTabId: dessertsId,
    );
    expect(
      menu.tabs.firstWhere((t) => t.section.slug == 'desserts').hasItems,
      isFalse,
    );
    expect(menu.comingSoon, isTrue);
    expect(menu.chips, isEmpty);
    expect(menu.sections, isEmpty);
    expect(menu.drinkOfTheDay, isNull);
    expect(menu.isEmpty, isFalse);
  });

  test('a section that vanished falls back to the first with drinks', () {
    final menu = build(
      items: items,
      categories: categories,
      today: day,
      selectedTabId: fakeId(999),
    );
    expect(menu.selectedTabId, cafeId);
    expect(menu.sections, hasLength(2));
  });

  test('desserts goes live with its first dessert, no code change', () {
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
    final menu = build(
      items: [...items, cheesecake],
      categories: [...categories, cakes],
      today: day,
      selectedTabId: dessertsId,
    );
    expect(menu.comingSoon, isFalse);
    expect(menu.chips.single.slug, 'cakes');
    expect(menu.drinkOfTheDay?.slug, 'cheesecake');
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
    final menu = build(items: items, categories: extra, today: day);
    expect(menu.chips.map((c) => c.slug), isNot(contains('smoothies')));
  });

  test('no drinks anywhere: empty', () {
    final menu = build(items: const [], categories: categories, today: day);
    expect(menu.isEmpty, isTrue);
  });

  test('the drink of the day is stable all day and changes daily', () {
    CatalogItem? pick(DateTime t) =>
        build(items: items, categories: categories, today: t).drinkOfTheDay;
    expect(pick(DateTime(2026, 10, 30, 8)), pick(DateTime(2026, 10, 30, 23)));
    final week = {
      for (var d = 0; d < 7; d++) pick(DateTime(2026, 11, 1 + d))!.slug,
    };
    expect(week.length, greaterThan(1));
  });

  test('nothing on the device: empty menu, no drink of the day', () {
    final menu = build(items: const [], categories: categories, today: day);
    expect(menu.isEmpty, isTrue);
    expect(menu.chips, isEmpty);
    expect(menu.drinkOfTheDay, isNull);
  });
}
