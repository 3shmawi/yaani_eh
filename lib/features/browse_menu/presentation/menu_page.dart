import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_controller.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_view.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/presentation/drink_preview.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronounce.dart';

/// Home: wires the menu state to [MenuView].
class MenuPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(CatalogItem item) =>
        unawaited(context.push<void>(AppRoutes.drink(item.slug)));
    return MenuView(
      menu: ref.watch(menuProvider),
      onSelectTab: ref.read(selectedTabProvider.notifier).select,
      onJumpToCategory: trackCategoryJump,
      onOpenSettings: () => unawaited(context.push<void>(AppRoutes.settings)),
      onOpenSearch: () => unawaited(context.push<void>(AppRoutes.search)),
      onOpenItem: open,
      cardAction: (item) => ItemPlayButton(item: item),
      cardTrailingAction: (item) =>
          FavoriteButton(item: item, from: FavoriteSource.card),
      onPreviewItem: (item) => unawaited(
        showDrinkPreview(context, ref, item, onOpen: () => open(item)),
      ),
    );
  }
}
