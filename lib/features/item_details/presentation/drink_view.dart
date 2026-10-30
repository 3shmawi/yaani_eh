import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:yaani_eh/core/text/bidi.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/widgets/trait_pills.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// One drink (Details artboard): the photo under the status bar, a
/// floating back button, and a sheet with the name, the plain
/// explanation, trait pills, the price and similar drinks.
class DrinkView extends StatelessWidget {
  const new({
    required this.item,
    required this.facts,
    required this.similar,
    required this.onBack,
    required this.onOpenDrink,
    super.key,
  });

  final CatalogItem item;
  final ItemFacts facts;
  final List<CatalogItem> similar;
  final VoidCallback onBack;
  final ValueChanged<CatalogItem> onOpenDrink;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final photoHeight = 452.h;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final explanation = arabic ? item.explanationAr : item.explanationEn;

    final sheet = Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.space4,
        AppDimens.space5,
        AppDimens.space4,
        AppDimens.space8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              item.menuName,
              style: AppTextStyles.forText(
                item.menuName,
                TextRole.title,
              ).copyWith(color: p.ink),
            ),
          ),
          Text(
            item.menuNameAr,
            style: AppTextStyles.forText(
              item.menuNameAr,
              TextRole.callout,
            ).copyWith(color: p.inkMuted),
          ),
          SizedBox(height: AppDimens.space3),
          Text(
            explanation,
            style: AppTextStyles.forText(
              explanation,
              TextRole.body,
            ).copyWith(color: p.ink),
          ),
          SizedBox(height: AppDimens.space4),
          TraitPills(facts: facts),
          SizedBox(height: AppDimens.space4),
          _PriceCard(facts: facts),
          if (similar.isNotEmpty) ...[
            SizedBox(height: AppDimens.space6),
            Semantics(
              header: true,
              child: Text(
                l10n.similarDrinks,
                style: context.text(TextRole.headline).copyWith(color: p.ink),
              ),
            ),
            SizedBox(height: AppDimens.space3),
            SizedBox(
              height: 176.r,
              child: ListView.separated(
                key: const Key('similar_drinks'),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: similar.length,
                separatorBuilder: (_, _) => SizedBox(width: AppDimens.space2),
                itemBuilder: (context, i) => SizedBox(
                  width: 132.r,
                  child: DrinkCard(
                    item: similar[i],
                    compact: true,
                    onTap: () => onOpenDrink(similar[i]),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: AppDimens.space6),
          Text(
            l10n.approximateNote,
            textAlign: TextAlign.center,
            style: context.text(TextRole.caption).copyWith(color: p.inkMuted),
          ),
        ],
      ),
    );

    return Material(
      color: p.surface,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            height: photoHeight,
            child: DrinkPhoto(
              name: item.menuName,
              imagePath: item.imagePath,
              size: PhotoSize.full,
            ),
          ),
          // Keeps the status bar and the back button readable.
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            height: 120.h + top,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.scrim, p.scrim.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          CustomScrollView(
            key: const Key('drink_scroll'),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: photoHeight - 48.h)),
              const SliverToBoxAdapter(child: OfflineBanner()),
              SliverToBoxAdapter(child: sheet),
            ],
          ),
          PositionedDirectional(
            top: top + AppDimens.space2,
            start: AppDimens.space4,
            child: AppIconButton(
              key: const Key('drink_back'),
              icon: AppIcons.back,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              tone: GlassTone.dark,
              onPressed: onBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const new({required this.facts});

  final ItemFacts facts;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final muted = context.text(TextRole.caption).copyWith(color: p.inkMuted);
    final min = facts.priceMin;
    final checked = facts.priceCheckedAt;
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space3,
      ),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: p.cardShadow,
      ),
      child: min == null
          ? Text(l10n.priceMissing, style: muted)
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.priceAtCafes, style: muted),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: Bidi.range(min, facts.priceMax ?? min),
                              style: AppTextStyles.latin(TextRole.title),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: l10n.currency,
                              style: context.text(TextRole.callout),
                            ),
                          ],
                        ),
                        style: TextStyle(color: p.ink),
                      ),
                    ],
                  ),
                ),
                if (checked != null) ...[
                  SizedBox(width: AppDimens.space3),
                  Flexible(
                    child: Text(
                      l10n.priceChecked(
                        // Month in words, year in Western digits (as menus).
                        '${DateFormat.MMMM(locale).format(checked)} '
                        '${checked.year}',
                      ),
                      style: muted,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// No such drink (old link, removed from the menu).
class DrinkMissingView extends StatelessWidget {
  const new({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      body: StateMessage(
        icon: AppIcons.coffee,
        title: l10n.drinkNotFoundTitle,
        message: l10n.drinkNotFoundBody,
        action: AppButton(label: l10n.notFoundGoHome, onPressed: onBack),
      ),
    );
  }
}

/// While the device copy loads (an instant, usually).
class DrinkLoadingView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      Material(color: context.palette.surface, child: const LoadingView());
}
