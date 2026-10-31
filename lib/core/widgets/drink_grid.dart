import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// Drink cards in a grid (Home, Favorites): two columns on phones, more on
/// tablets (cards stay ~170 wide). The first cards rise in one after
/// another ([firstIndex] continues the stagger across several grids).
class DrinkGrid extends StatelessWidget {
  const new({
    required this.items,
    this.firstIndex = 0,
    this.onOpenItem,
    this.onPreviewItem,
    this.cardAction,
    this.cardTrailingAction,
    this.hero = true,
    super.key,
  });

  final List<CatalogItem> items;
  final int firstIndex;
  final ValueChanged<CatalogItem>? onOpenItem;

  /// A long press: the quick preview.
  final ValueChanged<CatalogItem>? onPreviewItem;

  /// The card's top-start control (play) and top-end one (heart).
  final Widget Function(CatalogItem item)? cardAction;
  final Widget Function(CatalogItem item)? cardTrailingAction;

  /// Photos fly into the drink page; only one grid per screen may do it.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final gap = AppDimens.space3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 200).floor().clamp(2, 5);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, item) in items.indexed)
              SizedBox(
                width: width,
                child: AppReveal(
                  index: firstIndex + i,
                  child: DrinkCard(
                    key: ValueKey(item.id),
                    item: item,
                    hero: hero,
                    onTap: onOpenItem == null ? null : () => onOpenItem!(item),
                    onLongPress: onPreviewItem == null
                        ? null
                        : () => onPreviewItem!(item),
                    action: cardAction?.call(item),
                    trailingAction: cardTrailingAction?.call(item),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
