import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/browse/presentation/widgets/item_of_the_day.dart';
import 'package:yaani_eh/features/browse/presentation/widgets/section_card.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Home, a hub (docs/decisions/0004-home-header.md): a short header band
/// (the app's name, tagline and search, its one action), the item of the
/// day from any section, then one card per section from the backend.
/// A card opens its section's page (`/section/:slug`). Once the band
/// scrolls away, search stays pinned at the top.
class BrowseView extends StatefulWidget {
  const new({
    required this.hub,
    required this.onOpenSection,
    this.onOpenSearch,
    this.onOpenItem,
    this.cardAction,
    super.key,
  });

  /// Null while loading from the device.
  final HubModel? hub;
  final ValueChanged<HubSection> onOpenSection;

  /// The search field opens the search screen.
  final VoidCallback? onOpenSearch;

  /// The item of the day opens its page (item_details).
  final ValueChanged<CatalogItem>? onOpenItem;

  /// A control on the item of the day (the play button, `pronunciation`).
  final Widget Function(CatalogItem item)? cardAction;

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  final _scroll = ScrollController();
  final GlobalKey _searchKey = GlobalKey();

  /// The band's search field has scrolled away, so the pinned one shows.
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

  void _follow() {
    final box = _searchKey.currentContext?.findRenderObject();
    if (box == null || !box.attached || !_scroll.hasClients) return;
    final at = RenderAbstractViewport.maybeOf(box)
        ?.getOffsetToReveal(box, 0)
        .offset;
    if (at == null) return;
    final pinned =
        _scroll.position.pixels >
        at + AppDimens.searchHeight - MediaQuery.paddingOf(context).top;
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hub = widget.hub;
    final search = widget.onOpenSearch;

    final header = HeaderBand(
      title: l10n.appEyebrow,
      subtitle: l10n.browseTagline,
      readable: true,
      bottom: search == null
          ? null
          : KeyedSubtree(
              key: _searchKey,
              child: SearchField(key: const Key('home_search'), onTap: search),
            ),
    );

    final Widget body;
    if (hub == null) {
      body = const SliverFillRemaining(child: LoadingView());
    } else if (hub.sections.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(message: l10n.browseEmpty),
      );
    } else {
      body = SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppDimens.space4,
            AppDimens.space4,
            AppDimens.space4,
            // Clear of the floating tab bar.
            AppDimens.tabBarHeight + AppDimens.space8,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimens.hubMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hub.itemOfTheDay case final today?) ...[
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
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.hubSectionsTitle,
                      style: context
                          .text(TextRole.headline)
                          .copyWith(color: context.palette.ink),
                    ),
                  ),
                  SizedBox(height: AppDimens.space3),
                  _SectionGrid(
                    sections: hub.sections,
                    onOpen: widget.onOpenSection,
                  ),
                ],
              ),
            ),
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
              key: const Key('home_list'),
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(child: header),
                const SliverToBoxAdapter(child: OfflineBanner()),
                body,
              ],
            ),
          ),
          if (_pinned && search != null)
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: PinnedBar(
                key: const Key('home_search_pinned'),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppDimens.space4,
                  ),
                  child: AppReadableWidth(child: SearchField(onTap: search)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section cards: one column on a phone, more where each still gets
/// [AppDimens.sectionCardMinWidth] (2 on an iPad in portrait, 3 in
/// landscape). Cards in a row share their height.
class _SectionGrid extends StatelessWidget {
  const new({required this.sections, required this.onOpen});

  final List<HubSection> sections;
  final ValueChanged<HubSection> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final gap = AppDimens.space3;
      final columns =
          ((box.maxWidth + gap) / (AppDimens.sectionCardMinWidth + gap))
              .floor()
              .clamp(1, 3);
      final rows = <List<HubSection>>[
        for (var i = 0; i < sections.length; i += columns)
          sections.sublist(i, (i + columns).clamp(0, sections.length)),
      ];
      Widget card(HubSection s) => SectionCard(
        key: Key('section_${s.section.slug}'),
        section: s,
        onTap: () => onOpen(s),
      );
      if (columns == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, s) in sections.indexed) ...[
              if (i > 0) SizedBox(height: gap),
              card(s),
            ],
          ],
        );
      }
      return Column(
        children: [
          for (final (r, row) in rows.indexed) ...[
            if (r > 0) SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) SizedBox(width: gap),
                    Expanded(
                      child: c < row.length
                          ? card(row[c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
