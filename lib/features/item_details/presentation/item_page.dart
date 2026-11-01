import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/update/store_link.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/details_sheet.dart';
import 'package:yaani_eh/features/item_details/presentation/item_controller.dart';
import 'package:yaani_eh/features/item_details/presentation/item_view.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronounce.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_sheet.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// `/item/:slug`: wires one item's details to [ItemView].
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

  Future<void> _openStore() async {
    unawaited(Analytics.capture('update_from_details_tapped'));
    await ref.read(openStoreProvider)();
  }

  static String _defaultTitle(BuildContext context, ItemDetails? details) =>
      switch (details) {
        StoryDetails() => context.l10n.detailsStory,
        UsageDetails() => context.l10n.detailsUsage,
        _ => context.l10n.previewRecipe,
      };

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(itemStateProvider(widget.slug));
    switch (details) {
      case ItemLoading():
        return const ItemLoadingView();
      case ItemMissing():
        return ItemMissingView(onBack: () => context.go(AppRoutes.home));
      case ItemFound(
        :final item,
        :final traitSchema,
        :final similar,
        :final section,
      ):
        final arabic = Localizations.localeOf(context).languageCode == 'ar';
        final detailsTitle = section?.detailsTitle(arabic: arabic);
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
          detailsTitle: detailsTitle,
          onOpenDetails: () => unawaited(switch (item.details) {
            RecipeDetails() => showRecipeSheet(
              context,
              item,
              from: RecipeSource.itemPage,
            ),
            _ => showDetailsSheet(
              context,
              item,
              title: detailsTitle ?? _defaultTitle(context, item.details),
            ),
          }),
          onUpdateApp: () => unawaited(_openStore()),
          onOpenItem: (other) =>
              unawaited(context.push<void>(AppRoutes.item(other.slug))),
        );
    }
  }
}
