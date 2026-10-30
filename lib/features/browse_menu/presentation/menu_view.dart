import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/category_chips.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/browse_menu/domain/usecases/build_menu.dart';
import 'package:yaani_eh/features/browse_menu/presentation/widgets/drink_of_the_day.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Home (the Main artboard): the header band with category chips, the
/// drink of the day, then each category's drinks as glass cards.
class MenuView extends StatelessWidget {
  const new({
    required this.menu,
    required this.onSelectCategory,
    required this.onOpenSettings,
    this.onOpenItem,
    super.key,
  });

  /// Null while loading from the device.
  final MenuModel? menu;
  final void Function(CatalogCategory? category) onSelectCategory;
  final VoidCallback onOpenSettings;

  /// Opening a drink (item_details); null until that screen exists.
  final ValueChanged<CatalogItem>? onOpenItem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final menu = this.menu;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String name(CatalogCategory c) => arabic ? c.nameAr : c.nameEn;

    final header = HeaderBand(
      eyebrow: l10n.appEyebrow,
      title: l10n.menuTitle,
      subtitle: l10n.menuTagline,
      trailing: AppIconButton(
        key: const Key('home_settings_button'),
        icon: AppIcons.settings,
        tooltip: l10n.settingsTitle,
        tone: GlassTone.dark,
        onPressed: onOpenSettings,
      ),
      bottom: menu == null || menu.chips.isEmpty
          ? null
          : _EdgeToEdge(
              // The chips scroll edge to edge, past the band's gutter.
              child: CategoryChips(
                key: const Key('category_chips'),
                options: [
                  (id: null, label: l10n.chipAll),
                  for (final c in menu.chips) (id: c.id, label: name(c)),
                ],
                selectedId: menu.selectedCategoryId,
                onSelected: (id) => onSelectCategory(
                  id == null ? null : menu.chips.firstWhere((c) => c.id == id),
                ),
              ),
            ),
    );

    final Widget body;
    if (menu == null) {
      body = const SliverFillRemaining(child: LoadingView());
    } else if (menu.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          message: menu.selectedCategoryId == null
              ? l10n.menuEmpty
              : l10n.categoryEmpty,
        ),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppDimens.space4,
          AppDimens.space4,
          AppDimens.space4,
          AppDimens.space8,
        ),
        sliver: SliverList.list(
          children: [
            if (menu.drinkOfTheDay case final today?) ...[
              DrinkOfTheDay(
                key: const Key('drink_of_the_day'),
                item: today,
                onTap: onOpenItem == null ? null : () => onOpenItem!(today),
              ),
              SizedBox(height: AppDimens.space6),
            ],
            for (final section in menu.sections) ...[
              _SectionHeader(
                title: name(section.category),
                // On "All", jump to the category; inside it, no need.
                seeAll: menu.selectedCategoryId == null
                    ? () => onSelectCategory(section.category)
                    : null,
              ),
              SizedBox(height: AppDimens.space3),
              _Grid(items: section.items, onOpenItem: onOpenItem),
              SizedBox(height: AppDimens.space6),
            ],
            Text(
              l10n.approximateNote,
              textAlign: TextAlign.center,
              style: context
                  .text(TextRole.caption)
                  .copyWith(color: context.palette.inkMuted),
            ),
          ],
        ),
      );
    }

    return Material(
      color: context.palette.surface,
      child: CustomScrollView(
        key: const Key('menu_list'),
        slivers: [
          SliverToBoxAdapter(child: header),
          const SliverToBoxAdapter(child: OfflineBanner()),
          body,
        ],
      ),
    );
  }
}

/// Lets the chips run under the band's side padding.
class _EdgeToEdge extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppDimens.touchTarget,
    child: LayoutBuilder(
      builder: (context, constraints) => OverflowBox(
        maxWidth: constraints.maxWidth + AppDimens.space4 * 2,
        minWidth: constraints.maxWidth + AppDimens.space4 * 2,
        child: child,
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const new({required this.title, this.seeAll});

  final String title;
  final VoidCallback? seeAll;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppTextStyles.forText(
                title,
                TextRole.headline,
              ).copyWith(color: p.ink),
            ),
          ),
        ),
        if (seeAll != null)
          Semantics(
            label: context.l10n.seeAllIn(title),
            button: true,
            child: ExcludeSemantics(
              child: AppButton(
                label: context.l10n.seeAll,
                kind: AppButtonKind.text,
                onPressed: seeAll,
              ),
            ),
          ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const new({required this.items, required this.onOpenItem});

  final List<CatalogItem> items;
  final ValueChanged<CatalogItem>? onOpenItem;

  @override
  Widget build(BuildContext context) {
    final gap = AppDimens.space3;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on phones, more on tablets (cards stay ~170 wide).
        final columns = (constraints.maxWidth / 200).floor().clamp(2, 5);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: DrinkCard(
                  item: item,
                  onTap: onOpenItem == null ? null : () => onOpenItem!(item),
                ),
              ),
          ],
        );
      },
    );
  }
}
