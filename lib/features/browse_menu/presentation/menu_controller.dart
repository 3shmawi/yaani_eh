import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/features/browse_menu/domain/usecases/build_menu.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';

/// The open section of Home («مشروبات»، «حلويات»); null = the first one
/// with drinks.
final selectedTabProvider = NotifierProvider<SelectedTab, String?>(
  SelectedTab.new,
);

class SelectedTab extends Notifier<String?> {
  @override
  String? build() => null;

  void select(MenuTab tab) {
    if (tab.section.id == state) return;
    state = tab.section.id;
    unawaited(
      Analytics.capture('menu_section_selected', {
        'section': tab.section.slug,
        'coming_soon': !tab.hasItems,
      }),
    );
  }
}

/// A category chip was tapped (the list scrolls to it). Slug only, no
/// personal data.
void trackCategoryJump(CatalogCategory category) => unawaited(
  Analytics.capture('menu_category_selected', {'category': category.slug}),
);

/// Overridable clock, so "drink of the day" is testable.
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

/// The Home screen's content, rebuilt whenever the catalog syncs.
/// Null while the device copy is still loading.
final menuProvider = Provider<MenuModel?>((ref) {
  final items = ref.watch(catalogItemsProvider).value;
  final categories = ref.watch(catalogCategoriesProvider).value;
  if (items == null || categories == null) return null;
  return const BuildMenu()(
    items: items,
    categories: categories,
    today: ref.watch(todayProvider),
    selectedTabId: ref.watch(selectedTabProvider),
  );
});
