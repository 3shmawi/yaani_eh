import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/category_chips.dart';
import 'package:yaani_eh/core/widgets/drink_grid.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/browse_menu/domain/usecases/build_menu.dart';
import 'package:yaani_eh/features/browse_menu/presentation/widgets/drink_of_the_day.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Home (the Main artboard): the header band with the app's name, the
/// sections switch («مشروبات | حلويات») and the open section's category
/// chips; then the drink of the day and every category's drinks, one after
/// another. A chip scrolls to its category, and the highlighted chip
/// follows the list. Once the band scrolls away, the chips stay pinned at
/// the top. A section without drinks yet says it's coming soon.
class MenuView extends StatefulWidget {
  const new({
    required this.menu,
    required this.onSelectTab,
    required this.onOpenSettings,
    this.onJumpToCategory,
    this.onOpenItem,
    this.onOpenSearch,
    this.cardAction,
    this.cardTrailingAction,
    this.onPreviewItem,
    super.key,
  });

  /// Null while loading from the device.
  final MenuModel? menu;
  final ValueChanged<MenuTab> onSelectTab;
  final VoidCallback onOpenSettings;

  /// A chip was tapped (the list scrolls by itself; this is for analytics).
  final ValueChanged<CatalogCategory>? onJumpToCategory;

  /// Opening a drink (item_details).
  final ValueChanged<CatalogItem>? onOpenItem;

  /// The search field in the header opens the search screen.
  final VoidCallback? onOpenSearch;

  /// A control on each card and the drink of the day (the play button,
  /// feature `pronunciation`).
  final Widget Function(CatalogItem item)? cardAction;

  /// The heart on each card's top-end corner (feature `favorites`).
  final Widget Function(CatalogItem item)? cardTrailingAction;

  /// A long press on a card: the quick preview (feature `favorites`).
  final ValueChanged<CatalogItem>? onPreviewItem;

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  final _scroll = ScrollController();
  final GlobalKey _chipsKey = GlobalKey();
  final _sectionKeys = <String, GlobalKey>{};

  /// The highlighted chip: the category at the top of the list.
  String? _active;

  /// The band's chips have scrolled away, so the pinned copy shows.
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_follow);
  }

  @override
  void didUpdateWidget(MenuView old) {
    super.didUpdateWidget(old);
    if (old.menu?.selectedTabId != widget.menu?.selectedTabId) {
      // Another section: start it from the top.
      _active = null;
      _pinned = false;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String categoryId) =>
      _sectionKeys.putIfAbsent(categoryId, GlobalKey.new);

  /// How far down the screen the pinned chips reach.
  double get _pinnedBottom =>
      MediaQuery.paddingOf(context).top +
      AppDimens.touchTarget +
      AppDimens.space2 * 2;

  /// The scroll offset at which [key]'s top reaches the top of the list.
  /// Asked of the viewport, so it's right even when [key] is off screen.
  double? _offsetOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box == null || !box.attached) return null;
    return RenderAbstractViewport.maybeOf(box)
        ?.getOffsetToReveal(box, 0)
        .offset;
  }

  void _follow() {
    final chips = widget.menu?.chips ?? const <CatalogCategory>[];
    if (chips.isEmpty || !_scroll.hasClients) return;
    final position = _scroll.position;
    final chipsAt = _offsetOf(_chipsKey);
    final pinned =
        chipsAt != null &&
        position.pixels >
            chipsAt + AppDimens.touchTarget - MediaQuery.paddingOf(context).top;

    var active = chips.first.id;
    if (position.pixels >= position.maxScrollExtent - 1) {
      // The last categories may never reach the top: at the end, it's
      // the last one.
      active = chips.last.id;
    } else {
      for (final c in chips) {
        final at = _offsetOf(_keyFor(c.id));
        if (at != null &&
            at - position.pixels <= _pinnedBottom + AppDimens.space3) {
          active = c.id;
        }
      }
    }
    if (pinned != _pinned || active != _active) {
      setState(() {
        _pinned = pinned;
        _active = active;
      });
    }
  }

  void _jumpTo(CatalogCategory category) {
    widget.onJumpToCategory?.call(category);
    final at = _offsetOf(_keyFor(category.id));
    if (at == null || !_scroll.hasClients) return;
    setState(() => _active = category.id);
    final position = _scroll.position;
    final target = (at - _pinnedBottom - AppDimens.space2).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: AppMotion.jump,
        curve: AppMotion.enter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final menu = widget.menu;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String name(CatalogCategory c) => arabic ? c.nameAr : c.nameEn;
    final chips = menu?.chips ?? const <CatalogCategory>[];
    final tabs = menu?.tabs ?? const <MenuTab>[];
    final active = _active ?? chips.firstOrNull?.id;

    Widget chipRow({Key? key}) => CategoryChips(
      key: key,
      options: [for (final c in chips) (id: c.id, label: name(c))],
      selectedId: active,
      onSelected: (id) => _jumpTo(chips.firstWhere((c) => c.id == id)),
    );

    final header = HeaderBand(
      title: l10n.appEyebrow,
      subtitle: l10n.menuTagline,
      trailing: AppIconButton(
        key: const Key('home_settings_button'),
        icon: AppIcons.settings,
        tooltip: l10n.settingsTitle,
        tone: GlassTone.dark,
        onPressed: widget.onOpenSettings,
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search first (what most people came for), then the section,
          // then its categories.
          if (widget.onOpenSearch != null) ...[
            SearchField(onTap: widget.onOpenSearch),
            SizedBox(height: AppDimens.space3),
          ],
          if (tabs.length > 1) ...[
            AppSegmentedControl(
              key: const Key('menu_sections'),
              segments: [
                for (final t in tabs)
                  (
                    id: t.section.id,
                    label: name(t.section),
                    badge: t.hasItems ? null : l10n.comingSoonBadge,
                  ),
              ],
              selectedId: menu?.selectedTabId,
              onSelected: (id) => widget.onSelectTab(
                tabs.firstWhere((t) => t.section.id == id),
              ),
            ),
            SizedBox(height: AppDimens.space3),
          ],
          if (chips.isNotEmpty)
            KeyedSubtree(
              key: _chipsKey,
              // Runs under the band's side padding, edge to edge.
              child: _EdgeToEdge(
                child: chipRow(key: const Key('category_chips')),
              ),
            ),
        ],
      ),
    );

    final Widget body;
    if (menu == null) {
      body = const SliverFillRemaining(child: LoadingView());
    } else if (menu.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(message: l10n.menuEmpty),
      );
    } else if (menu.comingSoon) {
      final open = tabs.where((t) => t.hasItems).firstOrNull;
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          key: const Key('menu_coming_soon'),
          icon: AppIcons.cake,
          title: l10n.comingSoonTitle(name(menu.selectedTab!.section)),
          message: l10n.comingSoonMessage,
          actionLabel: open == null ? null : l10n.comingSoonAction,
          onAction: open == null ? null : () => widget.onSelectTab(open),
        ),
      );
    } else {
      body = SliverToBoxAdapter(
        // Built at once (not lazily) so a chip can scroll to any category
        // and the highlight can follow them all; a section is ~40 cards.
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppDimens.space4,
            AppDimens.space4,
            AppDimens.space4,
            // Clear of the floating tab bar.
            AppDimens.tabBarHeight + AppDimens.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (menu.drinkOfTheDay case final today?) ...[
                DrinkOfTheDay(
                  key: const Key('drink_of_the_day'),
                  item: today,
                  onTap: widget.onOpenItem == null
                      ? null
                      : () => widget.onOpenItem!(today),
                  action: widget.cardAction?.call(today),
                ),
                SizedBox(height: AppDimens.space6),
              ],
              for (final (i, section) in menu.sections.indexed) ...[
                KeyedSubtree(
                  key: _keyFor(section.category.id),
                  child: _SectionHeader(title: name(section.category)),
                ),
                SizedBox(height: AppDimens.space3),
                DrinkGrid(
                  items: section.items,
                  // Card number on the screen, for the entry stagger.
                  firstIndex: menu.sections
                      .take(i)
                      .fold(0, (n, s) => n + s.items.length),
                  onOpenItem: widget.onOpenItem,
                  onPreviewItem: widget.onPreviewItem,
                  cardAction: widget.cardAction,
                  cardTrailingAction: widget.cardTrailingAction,
                ),
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
        ),
      );
    }

    return Material(
      color: context.palette.surface,
      child: Stack(
        children: [
          HeaderOverscroll(
            child: CustomScrollView(
              key: const Key('menu_list'),
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(child: header),
                const SliverToBoxAdapter(child: OfflineBanner()),
                body,
              ],
            ),
          ),
          if (_pinned && chips.isNotEmpty)
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: _PinnedChips(
                // Already full width: the chips keep their own side padding.
                child: SizedBox(
                  height: AppDimens.touchTarget,
                  child: chipRow(key: const Key('category_chips_pinned')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The chips at the top of the screen once the band has scrolled away: a
/// slim espresso strip under the status bar, like the band's own bottom.
class _PinnedChips extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.espresso,
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(AppDimens.radiusLg),
      ),
      boxShadow: context.palette.glassShadow,
    ),
    child: Padding(
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.paddingOf(context).top + AppDimens.space2,
        bottom: AppDimens.space2,
      ),
      child: child,
    ),
  );
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
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: AppTextStyles.forText(
        title,
        TextRole.headline,
      ).copyWith(color: context.palette.ink),
    ),
  );
}
