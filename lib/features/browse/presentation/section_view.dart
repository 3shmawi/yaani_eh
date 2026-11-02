import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/category_chips.dart';
import 'package:yaani_eh/core/widgets/expanding_search_bar.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/item_grid.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/widgets/item_of_the_day.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// One section's page (`/section/:slug`): the header band with back, the
/// section's name and count, search, and its category chips; then its
/// item of the day and every category's items, one after another. A chip
/// scrolls to its category, and the highlighted chip follows the list.
/// Once the band scrolls away, a slim bar stays at the top: back, the
/// chips and search. A section without items yet says it's coming soon.
///
/// Home is this same view with [home] on and the section [tabs] in the
/// band (docs/decisions/0006-home-section-tabs.md): the app's name and
/// search field instead of back, and no back button.
///
/// Items come a page at a time ([BrowseModel.pageSize]): the next page is
/// added as the list nears its end, or when a chip jumps past what is
/// built, so a section with hundreds of items opens as fast as one with a
/// few.
class SectionView extends StatefulWidget {
  const new({
    required this.state,
    this.onBack,
    this.home = false,
    this.tabs,
    this.selectedTab,
    this.onTabSelected,
    this.resetKey,
    this.onJumpToCategory,
    this.onOpenItem,
    this.onOpenSearch,
    this.cardAction,
    this.cardTrailingAction,
    this.onPreviewItem,
    super.key,
  });

  final SectionState state;

  /// Back (a section page). Null on Home, which has no back.
  final VoidCallback? onBack;

  /// Home: the app's name, tagline and search field in the band.
  final bool home;

  /// Home's section tabs: a row of their own above the chips.
  final List<ChipOption>? tabs;
  final String? selectedTab;
  final ValueChanged<String>? onTabSelected;

  /// When it changes (another section on Home) the list goes back to the
  /// top and its first page.
  final Object? resetKey;

  /// A chip was tapped (the list scrolls by itself; this is for analytics).
  final ValueChanged<CatalogCategory>? onJumpToCategory;

  /// Opening an item (item_details).
  final ValueChanged<CatalogItem>? onOpenItem;

  /// The search button opens the search screen.
  final VoidCallback? onOpenSearch;

  /// A control on each card and the item of the day (the play button,
  /// feature `pronunciation`).
  final Widget Function(CatalogItem item)? cardAction;

  /// The heart on each card's top-end corner (feature `favorites`).
  final Widget Function(CatalogItem item)? cardTrailingAction;

  /// A long press on a card: the quick preview (feature `favorites`).
  final ValueChanged<CatalogItem>? onPreviewItem;

  @override
  State<SectionView> createState() => _SectionViewState();
}

class _SectionViewState extends State<SectionView> {
  final _scroll = ScrollController();
  final GlobalKey _chipsKey = GlobalKey();
  final _sectionKeys = <String, GlobalKey>{};

  /// The highlighted chip: the category at the top of the list.
  String? _active;

  /// The band's chips have scrolled away, so the pinned bar shows.
  bool _pinned = false;

  /// How many items are built so far, across the section's categories.
  int _limit = BrowseModel.pageSize;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_follow);
  }

  @override
  void didUpdateWidget(SectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetKey != oldWidget.resetKey) {
      _limit = BrowseModel.pageSize;
      _active = null;
      _pinned = false;
      _sectionKeys.clear();
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  BrowseModel? get _model => switch (widget.state) {
    SectionReady(:final model) => model,
    _ => null,
  };

  List<CatalogCategory> get _chips => switch (widget.state) {
    SectionReady(:final model) => model.chips,
    _ => const [],
  };

  GlobalKey _keyFor(String categoryId) =>
      _sectionKeys.putIfAbsent(categoryId, GlobalKey.new);

  /// How far down the screen the pinned bar reaches.
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

  /// Builds the next page when the list is within a screen and a half of
  /// its end (or hasn't filled the screen yet).
  void _loadMore() {
    final model = _model;
    if (model == null || _limit >= model.count || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.extentAfter < position.viewportDimension * 1.5) {
      setState(() => _limit += BrowseModel.pageSize);
    }
  }

  void _follow() {
    _loadMore();
    final chips = _chips;
    if (chips.isEmpty || !_scroll.hasClients) return;
    final position = _scroll.position;
    final chipsAt = _offsetOf(_chipsKey);
    final pinned =
        chipsAt != null &&
        position.pixels >
            chipsAt + AppDimens.touchTarget - MediaQuery.paddingOf(context).top;

    var active = widget.home ? null : chips.first.id;
    if (position.pixels >= position.maxScrollExtent - 1 &&
        _limit >= (_model?.count ?? 0)) {
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
    // A category past the built pages: build up to it first, then jump.
    final model = _model;
    final needed = model?.limitFor(category.id) ?? _limit;
    if (needed - BrowseModel.pageSize >= _limit) {
      setState(() {
        _limit = needed;
        _active = category.id;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollTo(category);
      });
      return;
    }
    _scrollTo(category);
  }

  /// «الكل»: back to the top of the list.
  void _jumpToTop() {
    if (!_scroll.hasClients) return;
    setState(() => _active = null);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: AppMotion.jump, curve: AppMotion.enter);
    }
  }

  void _scrollTo(CatalogCategory category) {
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

  Widget? _backButton({Key? key}) => widget.onBack == null
      ? null
      : AppIconButton(
          key: key,
          icon: AppIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          tone: GlassTone.dark,
          onPressed: widget.onBack!,
        );

  /// The button before the tabs: every section in a list.
  void _showSections(List<ChipOption> tabs) {
    unawaited(
      showAppSheet(
        context,
        closeLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        builder: (sheet) => _SectionsList(
          title: context.l10n.allSections,
          tabs: tabs,
          selected: widget.selectedTab,
          onPick: (id) {
            Navigator.of(sheet).pop();
            widget.onTabSelected?.call(id);
          },
        ),
      ),
    );
  }

  Widget? _searchButton({Key? key}) => widget.onOpenSearch == null
      ? null
      : AppIconButton(
          key: key,
          icon: AppIcons.search,
          tooltip: context.l10n.searchLabel,
          tone: GlassTone.dark,
          onPressed: widget.onOpenSearch!,
        );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String name(CatalogCategory c) => arabic ? c.nameAr : c.nameEn;
    final chips = _chips;
    final model = switch (widget.state) {
      SectionReady(:final model) => model,
      _ => null,
    };
    // Home starts on «الكل» (the top of the list); a section page on its
    // first category.
    final active = _active ?? (widget.home ? null : chips.firstOrNull?.id);

    Widget chipRow({Key? key, ChipsStyle style = ChipsStyle.band}) =>
        CategoryChips(
          key: key,
          style: style,
          options: [
            if (widget.home) (id: null, label: l10n.chipAll),
            for (final c in chips) (id: c.id, label: name(c)),
          ],
          selectedId: active,
          onSelected: (id) => id == null
              ? _jumpToTop()
              : _jumpTo(chips.firstWhere((c) => c.id == id)),
        );

    final search = widget.onOpenSearch;
    final chipsInBand = chips.isEmpty
        ? null
        : KeyedSubtree(
            key: _chipsKey,
            // Runs under the band's side padding, edge to edge.
            child: _EdgeToEdge(
              child: chipRow(key: const Key('category_chips')),
            ),
          );
    final header = widget.home
        ? HeaderBand(
            key: const Key('home_header'),
            title: l10n.appEyebrow,
            subtitle: l10n.browseTagline,
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (search != null) ...[
                  SearchField(key: const Key('home_search'), onTap: search),
                  SizedBox(height: AppDimens.space2),
                ],
                // The sections: a grid button that lists them all, then the
                // tabs, in a row that scrolls sideways.
                if (widget.tabs case final tabs?)
                  _EdgeToEdge(
                    key: const Key('section_tabs'),
                    child: Row(
                      children: [
                        SizedBox(width: AppDimens.space4),
                        AppIconButton(
                          key: const Key('all_sections'),
                          icon: AppIcons.grid,
                          tooltip: l10n.allSections,
                          tone: GlassTone.dark,
                          onPressed: () => _showSections(tabs),
                        ),
                        Expanded(
                          child: CategoryChips(
                            options: tabs,
                            selectedId: widget.selectedTab,
                            height: AppDimens.controlHeight,
                            onSelected: (id) {
                              if (id != null) widget.onTabSelected?.call(id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
        : HeaderBand(
            key: const Key('section_header'),
            compact: true,
            leading: _backButton(key: const Key('section_back')),
            title: model == null ? null : name(model.section),
            subtitle: model == null || model.comingSoon
                ? null
                : l10n.sectionItemCount(model.count),
            trailing: _searchButton(key: const Key('section_search')),
            bottom: chipsInBand,
          );

    final Widget body;
    switch (widget.state) {
      case SectionLoading():
        body = const SliverFillRemaining(child: LoadingView());
      case SectionNone():
        body = SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(message: l10n.browseEmpty),
        );
      case SectionMissing():
        body = SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            key: const Key('section_missing'),
            icon: AppIcons.section,
            title: l10n.sectionMissingTitle,
            message: l10n.sectionMissingBody,
            actionLabel: widget.onBack == null ? null : l10n.notFoundGoHome,
            onAction: widget.onBack,
          ),
        );
      case SectionReady(:final model) when model.comingSoon:
        body = SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            key: const Key('browse_coming_soon'),
            icon: AppIcons.forSection(model.section.icon),
            title: l10n.comingSoonTitle(name(model.section)),
            message: l10n.comingSoonMessage,
            actionLabel: widget.onBack == null ? null : l10n.comingSoonAction,
            onAction: widget.onBack,
          ),
        );
      case SectionReady(:final model):
        // A page of items at a time; a chip past what is built builds up
        // to it (_jumpTo) and the highlight follows what is built.
        final shown = model.firstItems(_limit);
        if (_limit < model.count) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadMore();
          });
        }
        body = SliverToBoxAdapter(
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
                if (model.itemOfTheDay case final today?) ...[
                  ItemOfTheDay(
                    key: const Key('item_of_the_day'),
                    item: today,
                    onTap: widget.onOpenItem == null
                        ? null
                        : () => widget.onOpenItem!(today),
                    action: widget.cardAction?.call(today),
                  ),
                  SizedBox(height: AppDimens.space6),
                ],
                for (final (i, section) in shown.indexed) ...[
                  KeyedSubtree(
                    key: _keyFor(section.category.id),
                    child: _CategoryHeader(title: name(section.category)),
                  ),
                  SizedBox(height: AppDimens.space3),
                  ItemGrid(
                    items: section.items,
                    // Card number on the screen, for the entry stagger.
                    firstIndex: shown
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
                  l10n.approximateCalories,
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
              key: const Key('browse_list'),
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(child: header),
                const SliverToBoxAdapter(child: OfflineBanner()),
                // Home: the categories sit on the page, under the band.
                if (widget.home && chips.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        top: AppDimens.space3,
                      ),
                      child: KeyedSubtree(
                        key: _chipsKey,
                        child: chipRow(
                          key: const Key('category_chips'),
                          style: ChipsStyle.surface,
                        ),
                      ),
                    ),
                  ),
                body,
              ],
            ),
          ),
          if (_pinned && chips.isNotEmpty)
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: PinnedBar(
                key: const Key('section_pinned'),
                child: widget.onOpenSearch == null
                    ? Row(
                        children: [
                          SizedBox(width: AppDimens.space2),
                          ?_backButton(key: const Key('section_back_pinned')),
                          Expanded(
                            child: SizedBox(
                              height: AppDimens.touchTarget,
                              child: chipRow(
                                key: const Key('category_chips_pinned'),
                              ),
                            ),
                          ),
                          SizedBox(width: AppDimens.space2),
                        ],
                      )
                    // The search button grows into the field, like iOS.
                    : ExpandingSearchBar(
                        leading: _backButton(
                          key: const Key('section_back_pinned'),
                        ),
                        chips: SizedBox(
                          height: AppDimens.touchTarget,
                          child: chipRow(
                            key: const Key('category_chips_pinned'),
                          ),
                        ),
                        onOpen: widget.onOpenSearch!,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lets the chips run under the band's side padding.
class _EdgeToEdge extends StatelessWidget {
  const new({required this.child, super.key});

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

class _CategoryHeader extends StatelessWidget {
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

/// «كل الأقسام»: the sections as a list, the open one ticked.
class _SectionsList extends StatelessWidget {
  const new({
    required this.title,
    required this.tabs,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final List<ChipOption> tabs;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppDimens.space5,
            AppDimens.space2,
            AppDimens.space5,
            AppDimens.space2,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.text(TextRole.headline).copyWith(color: p.ink),
            ),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsetsDirectional.only(bottom: AppDimens.space4),
            children: [
              for (final tab in tabs)
                Semantics(
                  button: true,
                  selected: tab.id == selected,
                  label: tab.label,
                  onTap: () => onPick(tab.id!),
                  child: ExcludeSemantics(
                    child: InkWell(
                      key: Key('sections_${tab.id}'),
                      onTap: () => onPick(tab.id!),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppDimens.touchTarget,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: AppDimens.space5,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tab.label,
                                  style: AppTextStyles.forText(
                                    tab.label,
                                    TextRole.body,
                                  ).copyWith(color: p.ink),
                                ),
                              ),
                              if (tab.id == selected)
                                Icon(
                                  AppIcons.check,
                                  size: AppDimens.icon,
                                  color: p.brand,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
