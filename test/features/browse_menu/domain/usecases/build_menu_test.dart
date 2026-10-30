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

  test('"All": chips for categories with drinks, one section each', () {
    final menu = build(items: items, categories: categories, today: day);

    expect(menu.chips.map((c) => c.slug), ['coffee', 'iced_coffee']);
    expect(menu.selectedCategoryId, isNull);
    expect(menu.sections, hasLength(2));
    expect(menu.sections.first.items, hasLength(8));
    expect(menu.sections.last.items, hasLength(4));
    expect(menu.drinkOfTheDay, isNotNull);
    expect(menu.isEmpty, isFalse);
  });

  test('a category shows only its drinks and no drink of the day', () {
    final menu = build(
      items: items,
      categories: categories,
      today: day,
      selectedCategoryId: coldId,
    );
    expect(menu.sections.single.category.slug, 'iced_coffee');
    expect(
      menu.sections.single.items.map((i) => i.slug),
      contains('cold_brew'),
    );
    expect(menu.drinkOfTheDay, isNull);
  });

  test('a category that vanished falls back to "All"', () {
    final menu = build(
      items: items,
      categories: categories,
      today: day,
      selectedCategoryId: fakeId(999),
    );
    expect(menu.selectedCategoryId, isNull);
    expect(menu.sections, hasLength(2));
  });

  test('empty categories get no chip; sections are data, not code', () {
    final extra = [
      ...categories,
      const CatalogCategory(
        id: '00000000-0000-4000-8000-0000000c0009',
        parentId: cafeId,
        slug: 'desserts',
        nameAr: 'حلويات',
        nameEn: 'Desserts',
        sortOrder: 9,
      ),
    ];
    final menu = build(items: items, categories: extra, today: day);
    expect(menu.chips.map((c) => c.slug), isNot(contains('desserts')));
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
