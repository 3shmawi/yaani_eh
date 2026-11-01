import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/item_card.dart';
import 'package:yaani_eh/core/widgets/item_photo.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/widgets/trait_pills.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// One drink (Details artboard): the photo under the status bar, a
/// floating back button, and a sheet with the name, the plain
/// explanation, trait pills, «طريقة التحضير» and similar drinks.
class ItemView extends StatelessWidget {
  const new({
    required this.item,
    required this.facts,
    required this.similar,
    required this.onBack,
    required this.onOpenItem,
    this.pronounce,
    this.saveButton,
    this.detailsTitle,
    this.onOpenDetails,
    this.onUpdateApp,
    super.key,
  });

  final CatalogItem item;
  final ItemFacts facts;
  final List<CatalogItem> similar;
  final VoidCallback onBack;
  final ValueChanged<CatalogItem> onOpenItem;

  /// The heart at the top-end corner (feature `favorites`).
  final Widget? saveButton;

  /// The pronounce pill (feature `pronunciation`), on the photo just above
  /// the sheet; scrolls with it.
  final Widget? pronounce;

  /// What the section calls the item's details («طريقة التحضير»,
  /// «الحكاية»); null → the app's name for the kind.
  final String? detailsTitle;

  /// Opens the details (a recipe's sheet, a story's…); null hides the row.
  final VoidCallback? onOpenDetails;

  /// Details newer than the app: opens the store. null hides the row.
  final VoidCallback? onUpdateApp;

  /// The row for the item's kind of details, or null (none, or no way in).
  Widget? _detailsRow(BuildContext context) {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final open = onOpenDetails;
    String title(String fallback) => detailsTitle ?? fallback;
    String? firstSections() {
      final titles = [
        for (final s in item.details!.sections) s.title(arabic: arabic),
      ];
      return titles.isEmpty ? null : titles.take(3).join(' · ');
    }

    return switch (item.details) {
      null => null,
      RecipeDetails(:final recipe) when open != null => _DetailsRow(
        key: const Key('item_recipe'),
        icon: AppIcons.recipe,
        title: title(l10n.previewRecipe),
        subtitle: l10n.recipeSubtitle(recipe.totalMl),
        onTap: open,
      ),
      StoryDetails(:final steps) when open != null => _DetailsRow(
        key: const Key('item_details'),
        icon: AppIcons.detailsStory,
        title: title(l10n.detailsStory),
        subtitle: l10n.detailsEvents(steps.length),
        onTap: open,
      ),
      UsageDetails() when open != null => _DetailsRow(
        key: const Key('item_details'),
        icon: AppIcons.detailsUsage,
        title: title(l10n.detailsUsage),
        subtitle: firstSections(),
        onTap: open,
      ),
      UnknownDetails() when onUpdateApp != null => _DetailsRow(
        key: const Key('item_update'),
        icon: AppIcons.update,
        title: l10n.detailsNeedUpdate,
        subtitle: null,
        hint: l10n.detailsNeedUpdateHint,
        chevron: false,
        onTap: onUpdateApp!,
      ),
      _ => null,
    };
  }

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
          if (_detailsRow(context) case final row?) ...[
            SizedBox(height: AppDimens.space4),
            row,
          ],
          if (similar.isNotEmpty) ...[
            SizedBox(height: AppDimens.space6),
            Semantics(
              header: true,
              child: Text(
                l10n.similarItems,
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
                  child: ItemCard(
                    item: similar[i],
                    compact: true,
                    onTap: () => onOpenItem(similar[i]),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: AppDimens.space6),
          Text(
            l10n.approximateCalories,
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
            // The Home card's photo flies into this one.
            child: Hero(
              tag: ItemCard.heroTag(item.id),
              child: ItemPhoto(
                name: item.menuName,
                imagePath: item.imagePath,
                size: PhotoSize.full,
              ),
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
            key: const Key('item_scroll'),
            // On a tablet the photo stays full width; the text column is
            // readable width, centred.
            slivers: [
              for (final sliver in [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: photoHeight - 48.h,
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          AppDimens.space4,
                          0,
                          AppDimens.space4,
                          AppDimens.space6,
                        ),
                        child: pronounce,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: OfflineBanner()),
                SliverToBoxAdapter(child: sheet),
              ])
                SliverAppReadableWidth(sliver: sliver),
            ],
          ),
          PositionedDirectional(
            top: top + AppDimens.space2,
            start: AppDimens.space4,
            child: AppIconButton(
              key: const Key('item_back'),
              icon: AppIcons.back,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              tone: GlassTone.dark,
              onPressed: onBack,
            ),
          ),
          if (saveButton case final save?)
            PositionedDirectional(
              top: top + AppDimens.space2,
              end: AppDimens.space4,
              child: save,
            ),
        ],
      ),
    );
  }
}

/// No such drink (old link, removed from the menu).
class ItemMissingView extends StatelessWidget {
  const new({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      body: StateMessage(
        icon: AppIcons.coffee,
        title: l10n.itemNotFoundTitle,
        message: l10n.itemNotFoundBody,
        action: AppButton(label: l10n.notFoundGoHome, onPressed: onBack),
      ),
    );
  }
}

/// While the device copy loads (an instant, usually).
class ItemLoadingView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      Material(color: context.palette.surface, child: const LoadingView());
}

/// The way into an item's details: an icon, what they're called and a
/// short line about them, then a chevron (none for the update row).
class _DetailsRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.hint,
    this.chevron = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? hint;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: title,
      hint: hint ?? subtitle,
      excludeSemantics: true,
      child: AppPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimens.touchTarget),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space4,
            vertical: AppDimens.space3,
          ),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: p.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: AppDimens.icon, color: p.brand),
              SizedBox(width: AppDimens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.forText(
                        title,
                        TextRole.callout,
                      ).copyWith(color: p.ink, fontWeight: FontWeight.w600),
                    ),
                    if (subtitle case final subtitle?)
                      Text(
                        subtitle,
                        style: AppTextStyles.forText(
                          subtitle,
                          TextRole.caption,
                        ).copyWith(color: p.inkMuted),
                      ),
                  ],
                ),
              ),
              if (chevron)
                Icon(
                  AppIcons.forward,
                  size: AppDimens.iconChip,
                  color: p.inkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
