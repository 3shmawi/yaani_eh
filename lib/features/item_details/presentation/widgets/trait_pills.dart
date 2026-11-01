import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Short facts about a drink (Design System → TraitPills): calories with
/// the number in bold, the section's traits, and an outlined warning when
/// the price may be old (words and an icon, never color alone).
class TraitPills extends StatelessWidget {
  const new({required this.facts, super.key});

  final ItemFacts facts;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final style = context.text(TextRole.callout).copyWith(color: p.ink);
    final calories = facts.calories;
    return Wrap(
      spacing: AppDimens.space2,
      runSpacing: AppDimens.space2,
      children: [
        if (calories != null)
          _Pill(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$calories',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' ${l10n.kcal}'),
                ],
              ),
              style: style,
            ),
          ),
        for (final trait in facts.traits)
          _Pill(child: Text(trait, style: style)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space3,
        vertical: AppDimens.space1,
      ),
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: child,
    );
  }
}
