import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/widgets/trait_pills.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// "What is this?" in one glance (Design System → AnswerCard): shown when
/// the query names a drink. Frosted glass over the search band, sliding up
/// 12px as it appears (a fade only with Reduce Motion).
class AnswerCard extends StatelessWidget {
  const new({
    required this.item,
    required this.facts,
    required this.query,
    required this.onOpen,
    super.key,
  });

  final CatalogItem item;
  final ItemFacts facts;
  final String query;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final explanation = arabic ? item.explanationAr : item.explanationEn;
    final still = MediaQuery.disableAnimationsOf(context);
    final card = AppGlass(
      padding: EdgeInsets.all(AppDimens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppDimens.space2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: p.brandSoft,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            ),
            child: Text(
              l10n.youTyped(query),
              style: context
                  .text(TextRole.caption)
                  .copyWith(color: p.brand, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: AppDimens.space2),
          Wrap(
            spacing: AppDimens.space2,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Semantics(
                header: true,
                child: Text(
                  item.menuName,
                  style: AppTextStyles.forText(item.menuName, TextRole.title),
                ),
              ),
              Text(
                item.menuNameAr,
                style: AppTextStyles.forText(
                  item.menuNameAr,
                  TextRole.callout,
                ).copyWith(color: p.inkMutedGlass),
              ),
            ],
          ),
          SizedBox(height: AppDimens.space2),
          Text(
            explanation,
            style: AppTextStyles.forText(explanation, TextRole.body),
          ),
          SizedBox(height: AppDimens.space3),
          TraitPills(facts: facts),
          SizedBox(height: AppDimens.space4),
          AppButton(
            key: const Key('answer_details'),
            label: l10n.seeDetails,
            onPressed: onOpen,
          ),
        ],
      ),
    );
    return TweenAnimationBuilder<double>(
      key: ValueKey(item.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: still ? 150 : 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, still ? 0 : 12 * (1 - t)),
          child: child,
        ),
      ),
      child: card,
    );
  }
}
