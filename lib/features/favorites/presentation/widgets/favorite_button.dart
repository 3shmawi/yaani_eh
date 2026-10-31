import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The heart over a drink's photo (the card's top-end corner, the drink
/// page): clear glass when not saved; saved, a warm-milk circle with an
/// espresso heart, like a selected chip. Saving pops the heart once and
/// gives a light tap; nothing moves with Reduce Motion.
class FavoriteButton extends ConsumerWidget {
  const new({
    required this.item,
    required this.from,
    this.tone = GlassTone.auto,
    this.minimal = true,
    super.key,
  });

  final CatalogItem item;
  final FavoriteSource from;
  final GlassTone tone;

  /// The cheapest glass (default): there's one on every card.
  final bool minimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saved = ref.watch(favoriteIdsProvider).contains(item.id);
    final button = AppIconButton(
      key: Key('favorite_${item.slug}'),
      icon: saved ? AppIconsFill.heart : AppIcons.heart,
      tooltip: saved
          ? l10n.favoriteRemoveOf(item.menuName)
          : l10n.favoriteAddOf(item.menuName),
      selected: saved,
      selectedLook: AppSelectedLook.chosen,
      tone: tone,
      minimal: minimal,
      onPressed: () async {
        final nowSaved = await ref
            .read(favoritesControllerProvider)
            .toggle(item, from);
        if (nowSaved) await HapticFeedback.lightImpact();
      },
    );
    if (MediaQuery.disableAnimationsOf(context)) return button;
    // Keyed on the state: a new save replays the pop.
    return TweenAnimationBuilder<double>(
      key: ValueKey(saved),
      tween: Tween(begin: saved ? AppMotion.popFrom : 1, end: 1),
      duration: AppMotion.pop,
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: button,
    );
  }
}
