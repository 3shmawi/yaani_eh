import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// One category and its items, in order.
class BrowseSection {
  const new({required this.category, required this.items});

  final CatalogCategory category;
  final List<CatalogItem> items;
}

/// One section's tab on Home: how many items it has. A section without
/// items yet is coming soon.
class HubSection {
  const new({required this.section, required this.count});

  final CatalogCategory section;
  final int count;

  bool get hasItems => count > 0;
}

/// Home's section tabs: every section, in order.
class HubModel {
  const new({required this.sections});

  final List<HubSection> sections;

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

  /// How many items one page adds while the list is scrolled.
  static const pageSize = 24;

  /// The categories with their first [limit] items, in order: what a page
  /// shows so far. A category with none of its items inside [limit] is left
  /// out, and the last one shown may be cut short.
  List<BrowseSection> firstItems(int limit) {
    final shown = <BrowseSection>[];
    var left = limit;
    for (final s in sections) {
      if (left <= 0) break;
      final items = s.items.length <= left ? s.items : s.items.sublist(0, left);
      shown.add(BrowseSection(category: s.category, items: items));
      left -= items.length;
    }
    return shown;
  }

  /// The smallest limit that shows the start of the category with [id]
  /// plus a page of its items, so a chip can jump to it before it has been
  /// scrolled to. Unknown ids need nothing more than the first page.
  int limitFor(String id) {
    var before = 0;
    for (final s in sections) {
      if (s.category.id == id) return before + pageSize;
      before += s.items.length;
    }
    return pageSize;
  }

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

/// Arranges the cached catalog into Home's section tabs. Pure: sections
/// are data, so a new one appears with no code change, as coming soon
/// until its first item is published.
class BuildHub {
  const new();

  HubModel call({
    required List<CatalogItem> items,
    required List<CatalogCategory> categories,
  }) {
    final catalog = _Catalog(items, categories);
    return HubModel(
      sections: [
        for (final s in catalog.sections)
          () {
            return HubSection(
              section: s,
              count: [for (final c in catalog.filled(s)) ...catalog.itemsOf(c)]
                  .length,
            );
          }(),
      ],
    );
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
