import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/widgets/drink_grid.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The Favorites tab: the drinks saved on this phone, newest first, as the
/// same cards as Home. Empty: a heart and how to save one, with a way to
/// the menu. Works offline (everything is on the phone).
class FavoritesView extends StatelessWidget {
  const new({
    required this.drinks,
    required this.onOpenMenu,
    this.onOpenItem,
    this.onPreviewItem,
    this.cardAction,
    this.cardTrailingAction,
    super.key,
  });

  /// Null while loading from the device.
  final List<CatalogItem>? drinks;
  final VoidCallback onOpenMenu;
  final ValueChanged<CatalogItem>? onOpenItem;
  final ValueChanged<CatalogItem>? onPreviewItem;
  final Widget Function(CatalogItem item)? cardAction;
  final Widget Function(CatalogItem item)? cardTrailingAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final drinks = this.drinks;
    final Widget body;
    if (drinks == null) {
      body = const SliverFillRemaining(child: LoadingView());
    } else if (drinks.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          key: const Key('favorites_empty'),
          icon: AppIcons.heart,
          title: l10n.favoritesEmptyTitle,
          message: l10n.favoritesEmptyMessage,
          actionLabel: l10n.favoritesEmptyAction,
          onAction: onOpenMenu,
        ),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppDimens.space4,
          AppDimens.space4,
          AppDimens.space4,
          // Clear of the floating tab bar.
          AppDimens.tabBarHeight + AppDimens.space8,
        ),
        sliver: SliverToBoxAdapter(
          child: DrinkGrid(
            key: const Key('favorites_grid'),
            items: drinks,
            onOpenItem: onOpenItem,
            onPreviewItem: onPreviewItem,
            cardAction: cardAction,
            cardTrailingAction: cardTrailingAction,
          ),
        ),
      );
    }
    return Material(
      color: context.palette.surface,
      child: HeaderOverscroll(
        child: CustomScrollView(
          key: const Key('favorites_list'),
          slivers: [
            SliverToBoxAdapter(
              child: HeaderBand(
                title: l10n.favoritesTitle,
                subtitle: drinks == null
                    ? null
                    : l10n.favoritesCount(drinks.length),
              ),
            ),
            const SliverToBoxAdapter(child: OfflineBanner()),
            body,
          ],
        ),
      ),
    );
  }
}
