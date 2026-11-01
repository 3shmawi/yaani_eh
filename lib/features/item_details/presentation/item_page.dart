import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/item_controller.dart';
import 'package:yaani_eh/features/item_details/presentation/item_view.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronounce.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_sheet.dart';

/// `/item/:slug`: wires one drink's details to [ItemView].
class ItemPage extends ConsumerStatefulWidget {
  const new({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends ConsumerState<ItemPage> {
  bool _logged = false;

  /// Back to where the reader came from; a deep link opens on Home.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(itemStateProvider(widget.slug));
    switch (details) {
      case ItemLoading():
        return const ItemLoadingView();
      case ItemMissing():
        return ItemMissingView(onBack: () => context.go(AppRoutes.home));
      case ItemFound(:final item, :final traitSchema, :final similar):
        if (!_logged) {
          _logged = true;
          unawaited(Analytics.capture('item_viewed', {'item': item.slug}));
        }
        return ItemView(
          item: item,
          facts: const DescribeItem()(
            item: item,
            traitSchema: traitSchema,
            lang: Localizations.localeOf(context).languageCode,
            now: ref.watch(todayProvider),
          ),
          similar: similar,
          pronounce: ItemPronounce(item: item),
          saveButton: FavoriteButton(
            item: item,
            from: FavoriteSource.itemPage,
            tone: GlassTone.dark,
            minimal: false,
          ),
          onBack: _back,
          onOpenRecipe: () => unawaited(
            showRecipeSheet(context, item, from: RecipeSource.itemPage),
          ),
          onOpenItem: (other) =>
              unawaited(context.push<void>(AppRoutes.item(other.slug))),
        );
    }
  }
}
