import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';

/// Everything the details screen needs about one drink.
sealed class DrinkDetails {
  const new();
}

/// Still reading the device copy.
final class DrinkLoading extends DrinkDetails {
  const new();
}

/// No such drink (an old link, or it was removed from the menu).
final class DrinkMissing extends DrinkDetails {
  const new();
}

final class DrinkFound extends DrinkDetails {
  const new({
    required this.item,
    required this.traitSchema,
    required this.similar,
  });

  final CatalogItem item;

  /// The item's section schema (for the trait pills).
  final List<Object?>? traitSchema;
  final List<CatalogItem> similar;
}

/// Details for the drink with this slug, from the device copy; updates
/// when a sync changes it.
final ProviderFamily<DrinkDetails, String> drinkDetailsProvider =
    Provider.family<DrinkDetails, String>((ref, slug) {
      final items = ref.watch(catalogItemsProvider).value;
      final categories = ref.watch(catalogCategoriesProvider).value;
      if (items == null || categories == null) return const DrinkLoading();
      final item = items.where((i) => i.slug == slug).firstOrNull;
      if (item == null) return const DrinkMissing();

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
      return DrinkFound(
        item: item,
        traitSchema: category?.traitSchema,
        similar: const SimilarItems()(item, items),
      );
    });
