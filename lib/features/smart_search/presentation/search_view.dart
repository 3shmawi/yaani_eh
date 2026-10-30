import 'package:flutter/material.dart';
import 'package:yaani_eh/core/text/bidi.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/smart_search/domain/usecases/search_menu.dart';
import 'package:yaani_eh/features/smart_search/presentation/widgets/answer_card.dart';
import 'package:yaani_eh/features/smart_search/presentation/widgets/result_row.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// How a result was opened (for analytics).
enum OpenedFrom { answer, list, suggestion }

/// Search (SearchName / SearchDesc / SearchEmpty artboards): the field on
/// the espresso band, the AnswerCard when the query names a drink, then the
/// ranked list with matched words highlighted, or "did you mean".
class SearchView extends StatelessWidget {
  const new({
    required this.controller,
    required this.results,
    required this.onChanged,
    required this.onOpen,
    required this.onTry,
    required this.onBack,
    this.answerFacts,
    super.key,
  });

  final TextEditingController controller;

  /// Null while the device copy loads.
  final SearchResults? results;

  /// Facts for the AnswerCard's pills.
  final ItemFacts? answerFacts;
  final ValueChanged<String> onChanged;
  final void Function(CatalogItem item, OpenedFrom from, int position) onOpen;

  /// An example or suggestion was tapped.
  final ValueChanged<String> onTry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final results = this.results;
    final answer = results?.answer;
    final facts = answerFacts;

    final header = HeaderBand(
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIconButton(
                key: const Key('search_back'),
                icon: AppIcons.back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                tone: GlassTone.dark,
                onPressed: onBack,
              ),
              SizedBox(width: AppDimens.space2),
              Expanded(
                child: SearchField(
                  key: const Key('search_field'),
                  controller: controller,
                  autofocus: controller.text.isEmpty,
                  onChanged: onChanged,
                  onSubmitted: onChanged,
                ),
              ),
            ],
          ),
          if (answer != null && facts != null) ...[
            SizedBox(height: AppDimens.space4),
            AnswerCard(
              key: const Key('answer_card'),
              item: answer.item,
              facts: facts,
              query: results!.query,
              onOpen: () => onOpen(answer.item, OpenedFrom.answer, 0),
            ),
          ],
        ],
      ),
    );

    final List<Widget> body;
    if (results == null) {
      body = [const SliverFillRemaining(child: LoadingView())];
    } else if (results.query.isEmpty) {
      body = [SliverToBoxAdapter(child: _Idle(onTry: onTry))];
    } else if (results.isEmpty) {
      body = [
        SliverToBoxAdapter(
          child: _Nothing(
            query: results.query,
            suggestions: results.suggestions,
            onOpen: (item, i) => onOpen(item, OpenedFrom.suggestion, i),
          ),
        ),
      ];
    } else {
      final hits = results.hits;
      body = [
        if (hits.isNotEmpty)
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppDimens.space4,
              AppDimens.space4,
              AppDimens.space4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      answer != null
                          ? l10n.searchMoreWith(results.query)
                          : l10n.searchResults(hits.length, results.query),
                      style: context
                          .text(TextRole.headline)
                          .copyWith(color: p.ink),
                    ),
                  ),
                  Text(
                    l10n.searchRankHint,
                    style: context
                        .text(TextRole.caption)
                        .copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppDimens.space4,
            AppDimens.space3,
            AppDimens.space4,
            AppDimens.space8,
          ),
          sliver: SliverList.separated(
            itemCount: hits.length,
            separatorBuilder: (_, _) => SizedBox(height: AppDimens.space3),
            itemBuilder: (context, i) => ResultRow(
              item: hits[i].item,
              highlight: hits[i].matched,
              onTap: () => onOpen(hits[i].item, OpenedFrom.list, i + 1),
            ),
          ),
        ),
      ];
    }

    return Material(
      color: p.surface,
      child: CustomScrollView(
        key: const Key('search_scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: header),
          const SliverToBoxAdapter(child: OfflineBanner()),
          ...body,
        ],
      ),
    );
  }
}

/// Before typing: what search understands, with examples to tap.
class _Idle extends StatelessWidget {
  const new({required this.onTry});

  final ValueChanged<String> onTry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final examples = l10n.searchExamples.split('|');
    return Padding(
      padding: EdgeInsets.all(AppDimens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchIdleTitle,
            style: context.text(TextRole.headline).copyWith(color: p.ink),
          ),
          Text(
            l10n.searchIdleBody,
            style: context.text(TextRole.body).copyWith(color: p.inkMuted),
          ),
          SizedBox(height: AppDimens.space4),
          Text(
            l10n.searchTry,
            style: context.text(TextRole.label).copyWith(color: p.inkMuted),
          ),
          SizedBox(height: AppDimens.space2),
          Wrap(
            spacing: AppDimens.space2,
            runSpacing: AppDimens.space2,
            children: [
              for (final example in examples)
                _SolidChip(
                  key: Key('search_example_$example'),
                  label: example,
                  onTap: () => onTry(example),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// No drink matched every word (SearchEmpty artboard).
class _Nothing extends StatelessWidget {
  const new({
    required this.query,
    required this.suggestions,
    required this.onOpen,
  });

  final String query;
  final List<CatalogItem> suggestions;
  final void Function(CatalogItem item, int position) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StateMessage(
          icon: AppIcons.coffee,
          title: l10n.searchNothing(query),
          message: l10n.searchNothingBody,
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppDimens.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.didYouMean,
                  style: context
                      .text(TextRole.label)
                      .copyWith(color: p.inkMuted),
                ),
                SizedBox(height: AppDimens.space2),
                Wrap(
                  spacing: AppDimens.space2,
                  runSpacing: AppDimens.space2,
                  children: [
                    for (final (i, item) in suggestions.indexed)
                      _SolidChip(
                        label:
                            '${Bidi.ltr(item.menuName)} · ${item.menuNameAr}',
                        onTap: () => onOpen(item, i + 1),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A chip on a plain surface (CategoryChips `is-solid`).
class _SolidChip extends StatelessWidget {
  const new({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.touchTarget,
              minWidth: AppDimens.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Container(
                constraints: BoxConstraints(minHeight: AppDimens.chipHeight),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space4,
                  vertical: AppDimens.space1,
                ),
                decoration: BoxDecoration(
                  color: p.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  border: Border.all(color: p.lineStrong),
                ),
                child: Text(
                  label,
                  style: context.text(TextRole.label).copyWith(color: p.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
