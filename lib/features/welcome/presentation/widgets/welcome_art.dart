import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/recipe.dart';
import 'package:yaani_eh/features/recipes/presentation/widgets/recipe_cup.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Menu names as a café prints them: Latin in both languages, like the
/// catalog's own names (content, not UI copy).
const _menu = ['Flat White', 'Cortado', 'Affogato', 'Cold Brew'];
const _affogato = 'Affogato';
const _match = 'Iced Spanish Latte';

/// A flat white, for the cup on the second page.
const _flatWhite = Recipe(
  minutes: 2,
  layers: [
    RecipeLayer(tone: RecipeTone.espresso, ml: 60, nameAr: '', nameEn: ''),
    RecipeLayer(tone: RecipeTone.milk, ml: 100, nameAr: '', nameEn: ''),
    RecipeLayer(tone: RecipeTone.foam, ml: 20, nameAr: '', nameEn: ''),
  ],
  steps: [],
);

/// The picture above a welcome page's title (design: Welcome 1–3). It's a
/// picture: hidden from screen readers (the title and text say it all),
/// and its text doesn't grow with the phone's text size; the whole picture
/// shrinks to fit instead.
class WelcomeArt extends StatelessWidget {
  const new menu({super.key}) : _page = 0;
  const new hear({super.key}) : _page = 1;
  const new taste({super.key}) : _page = 2;

  final int _page;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: MediaQuery.withNoTextScaling(
      // As tall as it needs (the page scales it down to fit); the menu's
      // stacked cards need a fixed box.
      child: SizedBox(
        width: AppDimens.welcomeArtWidth,
        height: _page == 0 ? AppDimens.welcomeArtHeight : null,
        child: switch (_page) {
          0 => const _MenuArt(),
          1 => const _HearArt(),
          _ => const _TasteArt(),
        },
      ),
    ),
  );
}

TextStyle _style(BuildContext context, TextRole role, Color color) =>
    context.text(role).copyWith(color: color);

/// A printed menu, tilted, and the drink's explanation card over it.
class _MenuArt extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      children: [
        PositionedDirectional(
          top: AppDimens.space2,
          start: AppDimens.space2,
          child: Transform.rotate(
            angle: rtl ? -0.07 : 0.07,
            child: Container(
              width: AppDimens.welcomeMenuCard,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space4,
                vertical: AppDimens.space3,
              ),
              decoration: BoxDecoration(
                color: AppColors.layerFoam,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.photoScrim,
                    blurRadius: 40,
                    offset: Offset(0, 18),
                    spreadRadius: -16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeArtMenu,
                    style: _style(
                      context,
                      TextRole.caption,
                      AppColors.espresso,
                    ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.4),
                  ),
                  SizedBox(height: AppDimens.space2),
                  for (final (i, name) in _menu.indexed)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: AppDimens.space1,
                      ),
                      child: Text(
                        name,
                        style: AppTextStyles.forText(name, TextRole.callout)
                            .copyWith(
                              color: AppColors.espresso.withValues(
                                alpha: i == 0 ? 1 : 0.55,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: _BandCard(
            width: AppDimens.welcomeExplainCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: AppDimens.welcomePhoto,
                  padding: EdgeInsetsDirectional.all(AppDimens.space3),
                  alignment: AlignmentDirectional.bottomStart,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.layerMilkCoffee,
                        AppColors.layerCoffee,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _menu.first,
                        style: AppTextStyles.forText(
                          _menu.first,
                          TextRole.headline,
                        ).copyWith(color: AppColors.onHeader),
                      ),
                      Text(
                        l10n.welcomeArtSaid,
                        style: _style(
                          context,
                          TextRole.caption,
                          AppColors.onHeaderMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.all(AppDimens.space3),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${l10n.welcomeArtMeans} ',
                          style: const TextStyle(
                            color: AppColors.bandAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: l10n.welcomeArtMeaning),
                      ],
                    ),
                    style: _style(
                      context,
                      TextRole.callout,
                      AppColors.bandCardInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The pronounce pill, playing, and the «طريقة التحضير» card with its cup.
class _HearArt extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppDimens.space2,
            AppDimens.space2,
            AppDimens.space4,
            AppDimens.space2,
          ),
          decoration: BoxDecoration(
            color: AppColors.bandChip,
            border: Border.all(color: AppColors.onHeaderFaint),
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppDimens.stepDot,
                height: AppDimens.stepDot,
                decoration: const BoxDecoration(
                  color: AppColors.selected,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIconsFill.speaker,
                  size: AppDimens.iconChip,
                  color: AppColors.onSelected,
                ),
              ),
              SizedBox(width: AppDimens.space3),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _affogato,
                      style: AppTextStyles.forText(
                        _affogato,
                        TextRole.cardTitle,
                      ).copyWith(color: AppColors.onHeader),
                    ),
                    Text(
                      '${l10n.welcomeArtAffogato} · ${l10n.pronounceBarista}',
                      style: _style(
                        context,
                        TextRole.caption,
                        AppColors.onHeaderMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppDimens.space3),
              const _Bars(),
            ],
          ),
        ),
        SizedBox(height: AppDimens.space4),
        _BandCard(
          child: Padding(
            padding: EdgeInsetsDirectional.all(AppDimens.space3),
            child: Row(
              children: [
                const RecipeCup(recipe: _flatWhite, semanticLabel: ''),
                SizedBox(width: AppDimens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.previewRecipe,
                        style: _style(
                          context,
                          TextRole.headline,
                          AppColors.bandCardInk,
                        ),
                      ),
                      SizedBox(height: AppDimens.space1),
                      Text(
                        l10n.welcomeArtRecipe,
                        style: _style(
                          context,
                          TextRole.caption,
                          AppColors.bandCardMuted,
                        ),
                      ),
                      SizedBox(height: AppDimens.space2),
                      _Pill(
                        label:
                            '${l10n.welcomeArtSteps(4)} · '
                            '${l10n.recipeMinutes(_flatWhite.minutes)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Taste chips, some chosen, and a drink «على ذوقك».
class _TasteArt extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = [
      (l10n.recipeCold, true),
      (l10n.recipeHot, false),
      (l10n.welcomeArtSweet, true),
      (l10n.welcomeArtMilk, true),
      (l10n.welcomeArtStrong, false),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppDimens.space2,
          runSpacing: AppDimens.space2,
          children: [
            for (final (label, on) in chips)
              Container(
                height: AppDimens.chipHeight,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space4,
                ),
                decoration: BoxDecoration(
                  color: on ? AppColors.selected : AppColors.bandChip,
                  border: on
                      ? null
                      : Border.all(color: AppColors.onHeaderFaint),
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: _style(
                      context,
                      TextRole.label,
                      on ? AppColors.onSelected : AppColors.onHeader,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppDimens.space4),
        _BandCard(
          child: Padding(
            padding: EdgeInsetsDirectional.all(AppDimens.space3),
            child: Row(
              children: [
                Container(
                  width: AppDimens.welcomeMatchPhotoWidth,
                  height: AppDimens.welcomeMatchPhotoHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.layerCondensed,
                        AppColors.layerMilkCoffee,
                      ],
                    ),
                  ),
                ),
                SizedBox(width: AppDimens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tasteForYou,
                        style: _style(
                          context,
                          TextRole.caption,
                          AppColors.bandAccent,
                        ),
                      ),
                      Text(
                        _match,
                        style: AppTextStyles.forText(
                          _match,
                          TextRole.headline,
                        ).copyWith(color: AppColors.bandCardInk),
                      ),
                      Text(
                        l10n.welcomeArtMatch,
                        style: _style(
                          context,
                          TextRole.caption,
                          AppColors.bandCardMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppIcons.heart,
                  color: AppColors.bandAccent,
                  size: AppDimens.icon,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A dark card on the band, like the app's cards in dark mode.
class _BandCard extends StatelessWidget {
  const new({required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.bandCard,
      border: Border.all(color: AppColors.bandCardLine),
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      boxShadow: const [
        BoxShadow(
          color: AppColors.photoScrim,
          blurRadius: 28,
          offset: Offset(0, 12),
          spreadRadius: -8,
        ),
      ],
    ),
    child: child,
  );
}

class _Pill extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsetsDirectional.symmetric(
      horizontal: AppDimens.space3,
      vertical: AppDimens.space1,
    ),
    decoration: BoxDecoration(
      color: AppColors.bandAccentFill,
      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
    ),
    child: Text(
      label,
      style: _style(context, TextRole.label, AppColors.bandAccent),
    ),
  );
}

/// A playing name's bars, standing still (the design's resting heights).
class _Bars extends StatelessWidget {
  const new();

  static const List<double> _heights = [0.5, 0.9, 0.6, 1, 0.4];

  @override
  Widget build(BuildContext context) {
    final height = AppDimens.space5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, h) in _heights.indexed) ...[
          if (i > 0) const SizedBox(width: AppDimens.soundBarGap),
          Container(
            width: AppDimens.soundBarWidth,
            height: height * h,
            decoration: BoxDecoration(
              color: AppColors.onHeaderMuted,
              borderRadius: BorderRadius.circular(AppDimens.soundBarGap),
            ),
          ),
        ],
      ],
    );
  }
}
