import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// One category and its drinks, in menu order.
class BrowseSection {
  const new({required this.category, required this.items});

  final CatalogCategory category;
  final List<CatalogItem> items;
}

/// A top-level section of Home («مشروبات»، «حلويات»…): one option of the
/// header's switch. One without drinks yet is shown as coming soon.
class BrowseTab {
  const new({required this.section, required this.hasItems});

  final CatalogCategory section;
  final bool hasItems;
}

/// What the Home screen shows: the open tab's categories, one after
/// another, with a chip for each (tapping one scrolls to it).
class BrowseModel {
  const new({
    required this.tabs,
    required this.chips,
    required this.sections,
    this.selectedTabId,
    this.itemOfTheDay,
  });

  /// Every section, in order; the switch shows when there are two or more.
  final List<BrowseTab> tabs;

  /// Null only when there are no sections at all.
  final String? selectedTabId;

  /// The open tab's categories that have drinks.
  final List<CatalogCategory> chips;

  /// One per chip, in the same order.
  final List<BrowseSection> sections;

  /// From the open tab's drinks.
  final CatalogItem? itemOfTheDay;

  BrowseTab? get selectedTab =>
      tabs.where((t) => t.section.id == selectedTabId).firstOrNull;

  /// The open tab exists but has no drinks yet.
  bool get comingSoon => selectedTab != null && !selectedTab!.hasItems;

  /// Nothing anywhere (a fresh catalog with no drinks).
  bool get isEmpty => tabs.every((t) => !t.hasItems);
}

/// Arranges the cached catalog into tabs, chips and sections. Pure:
/// sections and categories are data, so a new one (desserts) appears with
/// no code change, as coming soon until its first drink is published.
class BuildBrowse {
  const new();

  BrowseModel call({
    required List<CatalogItem> items,
    required List<CatalogCategory> categories,
    required DateTime today,
    String? selectedTabId,
  }) {
    final byCategory = <String, List<CatalogItem>>{};
    for (final item in items) {
      (byCategory[item.categoryId] ??= []).add(item);
    }
    int bySortOrder(CatalogCategory a, CatalogCategory b) =>
        a.sortOrder.compareTo(b.sortOrder);
    final sections = [
      for (final c in categories)
        if (c.isSection) c,
    ]..sort(bySortOrder);
    List<CatalogCategory> filled(CatalogCategory section) => [
      for (final c in categories)
        if (c.parentId == section.id && (byCategory[c.id]?.isNotEmpty ?? false))
          c,
    ]..sort(bySortOrder);

    final tabs = [
      for (final s in sections)
        BrowseTab(section: s, hasItems: filled(s).isNotEmpty),
    ];
    // A tab that vanished in a sync (or none chosen yet): the first one
    // with drinks.
    final selected =
        tabs.where((t) => t.section.id == selectedTabId).firstOrNull ??
        tabs.where((t) => t.hasItems).firstOrNull ??
        tabs.firstOrNull;
    final chips = selected == null
        ? const <CatalogCategory>[]
        : filled(selected.section);
    final shown = [
      for (final c in chips)
        BrowseSection(category: c, items: byCategory[c.id] ?? const []),
    ];

    return BrowseModel(
      tabs: tabs,
      selectedTabId: selected?.section.id,
      chips: chips,
      sections: shown,
      itemOfTheDay: _ofTheDay([for (final s in shown) ...s.items], today),
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
