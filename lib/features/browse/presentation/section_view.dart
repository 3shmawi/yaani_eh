import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/category_chips.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/item_grid.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
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
class SectionView extends StatefulWidget {
  const new({
    required this.state,
    required this.onBack,
    this.onJumpToCategory,
    this.onOpenItem,
    this.onOpenSearch,
    this.cardAction,
    this.cardTrailingAction,
    this.onPreviewItem,
    super.key,
  });

  final SectionState state;
  final VoidCallback onBack;

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

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_follow);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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

  void _follow() {
    final chips = _chips;
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

  Widget _backButton({Key? key}) => AppIconButton(
    key: key,
    icon: AppIcons.back,
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    tone: GlassTone.dark,
    onPressed: widget.onBack,
  );

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
    final active = _active ?? chips.firstOrNull?.id;

    Widget chipRow({Key? key}) => CategoryChips(
      key: key,
      options: [for (final c in chips) (id: c.id, label: name(c))],
      selectedId: active,
      onSelected: (id) => _jumpTo(chips.firstWhere((c) => c.id == id)),
    );

    final header = HeaderBand(
      key: const Key('section_header'),
      compact: true,
      leading: _backButton(key: const Key('section_back')),
      title: model == null ? null : name(model.section),
      subtitle: model == null || model.comingSoon
          ? null
          : l10n.sectionItemCount(model.count),
      trailing: _searchButton(key: const Key('section_search')),
      bottom: chips.isEmpty
          ? null
          : KeyedSubtree(
              key: _chipsKey,
              // Runs under the band's side padding, edge to edge.
              child: _EdgeToEdge(
                child: chipRow(key: const Key('category_chips')),
              ),
            ),
    );

    final Widget body;
    switch (widget.state) {
      case SectionLoading():
        body = const SliverFillRemaining(child: LoadingView());
      case SectionMissing():
        body = SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            key: const Key('section_missing'),
            icon: AppIcons.section,
            title: l10n.sectionMissingTitle,
            message: l10n.sectionMissingBody,
            actionLabel: l10n.notFoundGoHome,
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
            actionLabel: l10n.comingSoonAction,
            onAction: widget.onBack,
          ),
        );
      case SectionReady(:final model):
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
                for (final (i, section) in model.sections.indexed) ...[
                  KeyedSubtree(
                    key: _keyFor(section.category.id),
                    child: _CategoryHeader(title: name(section.category)),
                  ),
                  SizedBox(height: AppDimens.space3),
                  ItemGrid(
                    items: section.items,
                    // Card number on the screen, for the entry stagger.
                    firstIndex: model.sections
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
                child: Row(
                  children: [
                    SizedBox(width: AppDimens.space2),
                    _backButton(key: const Key('section_back_pinned')),
                    Expanded(
                      child: SizedBox(
                        height: AppDimens.touchTarget,
                        child: chipRow(key: const Key('category_chips_pinned')),
                      ),
                    ),
                    ?_searchButton(key: const Key('section_search_pinned')),
                    SizedBox(width: AppDimens.space2),
                  ],
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
