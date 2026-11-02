import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/section_view.dart';
import 'package:yaani_eh/features/browse/presentation/widgets/section_tabs.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/item_preview.dart';
import 'package:yaani_eh/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronounce.dart';

/// Home: the section tabs, and under them the picked section's items
/// ([SectionView] with `home` on). The first section with items opens
/// first; the pick lasts while the app runs.
class BrowsePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(CatalogItem item) =>
        unawaited(context.push<void>(AppRoutes.item(item.slug)));
    final hub = ref.watch(hubProvider);
    final slug = ref.watch(homeSectionSlugProvider);
    return SectionView(
      home: true,
      resetKey: slug,
      state: switch ((hub, slug)) {
        (null, _) => const SectionLoading(),
        (_, null) => const SectionNone(),
        (_, final slug?) => ref.watch(sectionProvider(slug)),
      },
      tabs: hub == null || hub.sections.isEmpty
          ? null
          : SectionTabs(
              sections: hub.sections,
              selectedSlug: slug,
              onSelected: (section) {
                trackSectionOpened(section);
                ref
                    .read(homePickedSectionProvider.notifier)
                    .pick(section.section.slug);
              },
            ),
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
