import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/section_view.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/item_preview.dart';
import 'package:yaani_eh/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronounce.dart';

/// One section (`/section/:slug`): wires its items to [SectionView].
class SectionPage extends ConsumerWidget {
  const new({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(CatalogItem item) =>
        unawaited(context.push<void>(AppRoutes.item(item.slug)));
    return SectionView(
      state: ref.watch(sectionProvider(slug)),
      // Opened from a link with nothing under it: back goes Home.
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.home),
      onJumpToCategory: trackCategoryJump,
      onOpenSearch: () => unawaited(context.push<void>(AppRoutes.search)),
      onOpenItem: open,
      cardAction: (item) => ItemPlayButton(item: item),
      cardTrailingAction: (item) =>
          FavoriteButton(item: item, from: FavoriteSource.card),
      onPreviewItem: (item) => unawaited(
        showItemPreview(context, ref, item, onOpen: () => open(item)),
      ),
    );
  }
}
