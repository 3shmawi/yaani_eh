import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// One category and its drinks, in menu order.
class MenuSection {
  const new({required this.category, required this.items});

  final CatalogCategory category;
  final List<CatalogItem> items;
}

/// What the Home screen shows.
class MenuModel {
  const new({
    required this.chips,
    required this.sections,
    this.selectedCategoryId,
    this.drinkOfTheDay,
  });

  /// Categories that have drinks, for the chips ("All" comes first in UI).
  final List<CatalogCategory> chips;

  /// Null = "All".
  final String? selectedCategoryId;

  /// Shown on "All" only.
  final CatalogItem? drinkOfTheDay;
  final List<MenuSection> sections;

  bool get isEmpty => sections.every((s) => s.items.isEmpty);
}

/// Arranges the cached catalog into chips and sections. Pure: categories
/// are data, so a new section or category appears with no code change.
class BuildMenu {
  const new();

  MenuModel call({
    required List<CatalogItem> items,
    required List<CatalogCategory> categories,
    required DateTime today,
    String? selectedCategoryId,
  }) {
    final byCategory = <String, List<CatalogItem>>{};
    for (final item in items) {
      (byCategory[item.categoryId] ??= []).add(item);
    }
    final sectionOrder = {
      for (final c in categories)
        if (c.isSection) c.id: c.sortOrder,
    };
    int rank(CatalogCategory c) =>
        c.isSection ? c.sortOrder : (sectionOrder[c.parentId] ?? 0);
    final chips =
        [
          for (final c in categories)
            if (!c.isSection && (byCategory[c.id]?.isNotEmpty ?? false)) c,
        ]..sort((a, b) {
          final bySection = rank(a).compareTo(rank(b));
          return bySection != 0
              ? bySection
              : a.sortOrder.compareTo(b.sortOrder);
        });

    // A category that vanished in a sync falls back to "All".
    final selected = chips.any((c) => c.id == selectedCategoryId)
        ? selectedCategoryId
        : null;
    final shown = selected == null
        ? chips
        : chips.where((c) => c.id == selected).toList();

    return MenuModel(
      chips: chips,
      selectedCategoryId: selected,
      drinkOfTheDay: selected == null ? _ofTheDay(items, today) : null,
      sections: [
        for (final c in shown)
          MenuSection(category: c, items: byCategory[c.id] ?? const []),
      ],
    );
  }

  /// The same drink all day, a different one tomorrow.
  static CatalogItem? _ofTheDay(List<CatalogItem> items, DateTime today) {
    if (items.isEmpty) return null;
    final day = DateTime.utc(today.year, today.month, today.day);
    final index = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final sorted = [...items]..sort((a, b) => a.slug.compareTo(b.slug));
    return sorted[index % sorted.length];
  }
}
