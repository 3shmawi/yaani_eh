import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/features/browse_menu/domain/usecases/build_menu.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';

/// The selected category chip (null = "All").
final selectedCategoryProvider = NotifierProvider<SelectedCategory, String?>(
  SelectedCategory.new,
);

class SelectedCategory extends Notifier<String?> {
  @override
  String? build() => null;

  /// [slug] is only for analytics (no personal data).
  void select(String? id, {String? slug}) {
    if (id == state) return;
    state = id;
    unawaited(
      Analytics.capture('menu_category_selected', {'category': slug ?? 'all'}),
    );
  }
}

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
    selectedCategoryId: ref.watch(selectedCategoryProvider),
  );
});
