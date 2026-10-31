import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/taste_profile/domain/usecases/match_taste.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// «على ذوقك» on Home (design: Row A). Before the quiz: an invite to take
/// it. After: the drinks that fit best as a row of cards, each with why
/// («ساقع · حلو · بلبن»), and «غيّر ذوقك». Pure UI: state comes in, taps go
/// out.
class TasteRowView extends StatelessWidget {
  const new({
    required this.matches,
    required this.onStart,
    this.taken = false,
    this.onOpenItem,
    this.onPreviewItem,
    this.cardTrailingAction,
    super.key,
  });

  /// Best first; empty before the quiz, or when nothing fits.
  final List<TasteMatch> matches;

  /// Whether the quiz was taken for this section.
  final bool taken;

  /// Opens the quiz (to take it, or to change it).
  final VoidCallback onStart;
  final void Function(CatalogItem item, int rank)? onOpenItem;
  final ValueChanged<CatalogItem>? onPreviewItem;
  final Widget Function(CatalogItem item)? cardTrailingAction;

  @override
  Widget build(BuildContext context) {
    if (!taken) return _Invite(onStart: onStart);
    final p = context.palette;
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      key: const Key('taste_row'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.tasteForYou,
                  style: context.text(TextRole.headline).copyWith(color: p.ink),
                ),
              ),
            ),
            AppButton(
              key: const Key('taste_change'),
              kind: AppButtonKind.text,
              label: l10n.tasteChange,
              onPressed: onStart,
            ),
          ],
        ),
        if (matches.isEmpty)
          Text(
            l10n.tasteNoMatches,
            style: context.text(TextRole.callout).copyWith(color: p.inkMuted),
          )
        else
          SingleChildScrollView(
            key: const Key('taste_matches'),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, m) in matches.indexed) ...[
                  if (i > 0) SizedBox(width: AppDimens.space3),
                  SizedBox(
                    width: AppDimens.tasteCardWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DrinkCard(
                          key: Key('taste_match_${m.item.slug}'),
                          item: m.item,
                          onTap: onOpenItem == null
                              ? null
                              : () => onOpenItem!(m.item, i + 1),
                          onLongPress: onPreviewItem == null
                              ? null
                              : () => onPreviewItem!(m.item),
                          trailingAction: cardTrailingAction?.call(m.item),
                        ),
                        if (m.why.isNotEmpty) ...[
                          SizedBox(height: AppDimens.space1),
                          Semantics(
                            label: l10n.tasteWhyLabel(_why(m, arabic: arabic)),
                            excludeSemantics: true,
                            child: Text(
                              _why(m, arabic: arabic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context
                                  .text(TextRole.caption)
                                  .copyWith(color: p.inkMuted),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static String _why(TasteMatch m, {required bool arabic}) =>
      m.why.map((o) => o.label(arabic: arabic)).join(' · ');
}

/// Before the quiz: what it is, and the way in.
class _Invite extends StatelessWidget {
  const new({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    return Container(
      key: const Key('taste_invite'),
      padding: EdgeInsetsDirectional.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimens.touchTarget,
            height: AppDimens.touchTarget,
            decoration: BoxDecoration(
              color: p.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.taste, size: AppDimens.icon, color: p.brand),
          ),
          SizedBox(width: AppDimens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tastePromptTitle,
                  style: context
                      .text(TextRole.callout)
                      .copyWith(color: p.ink, fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.tastePromptBody,
                  style: context
                      .text(TextRole.caption)
                      .copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimens.space2),
          AppButton(
            key: const Key('taste_start'),
            label: l10n.tastePromptAction,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
