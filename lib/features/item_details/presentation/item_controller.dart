import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';

/// Everything the details screen needs about one item.
sealed class ItemState {
  const new();
}

/// Still reading the device copy.
final class ItemLoading extends ItemState {
  const new();
}

/// No such item (an old link, or it was removed).
final class ItemMissing extends ItemState {
  const new();
}

final class ItemFound extends ItemState {
  const new({
    required this.item,
    required this.traitSchema,
    required this.similar,
    this.section,
  });

  final CatalogItem item;

  /// The item's section (its kind of details and what they're called).
  final CatalogCategory? section;

  /// The item's section schema (for the trait pills).
  final List<Object?>? traitSchema;
  final List<CatalogItem> similar;
}

/// Details for the drink with this slug, from the device copy; updates
/// when a sync changes it.
final ProviderFamily<ItemState, String> itemStateProvider =
    Provider.family<ItemState, String>((ref, slug) {
      final items = ref.watch(catalogItemsProvider).value;
      final categories = ref.watch(catalogCategoriesProvider).value;
      if (items == null || categories == null) return const ItemLoading();
      final item = items.where((i) => i.slug == slug).firstOrNull;
      if (item == null) return const ItemMissing();

      final byId = {for (final c in categories) c.id: c};
      var category = byId[item.categoryId];
      // Walk up to the section that holds the trait schema.
      for (
        var hops = 0;
        category != null && !category.isSection && hops < 4;
        hops++
      ) {
        category = byId[category.parentId];
      }
      return ItemFound(
        item: item,
        section: category != null && category.isSection ? category : null,
        traitSchema: category?.traitSchema,
        similar: const SimilarItems()(item, items),
      );
    });
