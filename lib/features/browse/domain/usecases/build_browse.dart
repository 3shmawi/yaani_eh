import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// One category and its items, in order.
class BrowseSection {
  const new({required this.category, required this.items});

  final CatalogCategory category;
  final List<CatalogItem> items;
}

/// One section's card on Home: how many items it has and the first few.
/// A section without items yet is coming soon.
class HubSection {
  const new({
    required this.section,
    required this.count,
    required this.examples,
  });

  final CatalogCategory section;
  final int count;

  /// The section's first items, in order (at most [BuildHub.examples]).
  final List<CatalogItem> examples;

  bool get hasItems => count > 0;
}

/// Home: every section, in order, and an item of the day from any of them.
class HubModel {
  const new({required this.sections, this.itemOfTheDay});

  final List<HubSection> sections;
  final CatalogItem? itemOfTheDay;

  /// Nothing anywhere (a fresh catalog with no items).
  bool get isEmpty => sections.every((s) => !s.hasItems);
}

/// One section's page: its categories with items, one after another, with
/// a chip for each (tapping one scrolls to it).
class BrowseModel {
  const new({
    required this.section,
    required this.chips,
    required this.sections,
    this.itemOfTheDay,
  });

  final CatalogCategory section;

  /// The section's categories that have items.
  final List<CatalogCategory> chips;

  /// One per chip, in the same order.
  final List<BrowseSection> sections;

  /// From this section's items.
  final CatalogItem? itemOfTheDay;

  int get count => sections.fold(0, (n, s) => n + s.items.length);

  /// The section exists but has no items yet.
  bool get comingSoon => chips.isEmpty;
}

/// The catalog's sections, their categories with items, and those items,
/// in sort order. Shared by [BuildHub] and [BuildBrowse].
class _Catalog {
  new(List<CatalogItem> items, List<CatalogCategory> categories) {
    for (final item in items) {
      (_byCategory[item.categoryId] ??= []).add(item);
    }
    sections = [
      for (final c in categories)
        if (c.isSection) c,
    ]..sort(_bySortOrder);
    _categories = categories;
  }

  final _byCategory = <String, List<CatalogItem>>{};
  late final List<CatalogCategory> sections;
  late final List<CatalogCategory> _categories;

  static int _bySortOrder(CatalogCategory a, CatalogCategory b) =>
      a.sortOrder.compareTo(b.sortOrder);

  List<CatalogItem> itemsOf(CatalogCategory category) =>
      _byCategory[category.id] ?? const [];

  /// A section's categories that have items.
  List<CatalogCategory> filled(CatalogCategory section) => [
    for (final c in _categories)
      if (c.parentId == section.id && itemsOf(c).isNotEmpty) c,
  ]..sort(_bySortOrder);
}

/// The same item all day, a different one tomorrow.
CatalogItem? _ofTheDay(List<CatalogItem> items, DateTime today) {
  if (items.isEmpty) return null;
  final day = DateTime.utc(today.year, today.month, today.day);
  final index = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  final sorted = [...items]..sort((a, b) => a.slug.compareTo(b.slug));
  return sorted[index % sorted.length];
}

/// Arranges the cached catalog into Home's section cards. Pure: sections
/// are data, so a new one appears with no code change, as coming soon
/// until its first item is published.
class BuildHub {
  const new();

  /// How many example names a section card shows.
  static const examples = 3;

  HubModel call({
    required List<CatalogItem> items,
    required List<CatalogCategory> categories,
    required DateTime today,
  }) {
    final catalog = _Catalog(items, categories);
    final shown = <CatalogItem>[];
    final sections = [
      for (final s in catalog.sections)
        () {
          final all = [
            for (final c in catalog.filled(s)) ...catalog.itemsOf(c),
          ];
          shown.addAll(all);
          return HubSection(
            section: s,
            count: all.length,
            examples: all.take(examples).toList(),
          );
        }(),
    ];
    return HubModel(sections: sections, itemOfTheDay: _ofTheDay(shown, today));
  }
}

/// Arranges one section (by its slug) into chips and categories. Null
/// when no section has that slug (an old or crafted link).
class BuildBrowse {
  const new();

  BrowseModel? call({
    required String slug,
    required List<CatalogItem> items,
    required List<CatalogCategory> categories,
    required DateTime today,
  }) {
    final catalog = _Catalog(items, categories);
    final section = catalog.sections.where((s) => s.slug == slug).firstOrNull;
    if (section == null) return null;
    final chips = catalog.filled(section);
    final shown = [
      for (final c in chips)
        BrowseSection(category: c, items: catalog.itemsOf(c)),
    ];
    return BrowseModel(
      section: section,
      chips: chips,
      sections: shown,
      itemOfTheDay: _ofTheDay([for (final s in shown) ...s.items], today),
    );
  }
}
