import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_look.dart';
import 'package:yaani_eh/features/recipes/presentation/widgets/recipe_cup.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// «طريقة التحضير» (the recipe sheet): the name with the cup's size, the
/// cup drawn to scale next to what's in it, hot or iced and how long, the
/// numbered steps with their amounts, and «خطوة بخطوة».
class RecipeView extends StatelessWidget {
  const new({
    required this.item,
    required this.recipe,
    required this.onClose,
    required this.onStepByStep,
    super.key,
  });

  final CatalogItem item;
  final Recipe recipe;
  final VoidCallback onClose;
  final VoidCallback onStepByStep;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return SingleChildScrollView(
      key: const Key('recipe_view'),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.space4,
        0,
        AppDimens.space4,
        AppDimens.space6 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      l10n.recipeSubtitle(recipe.totalMl),
                      style: context
                          .text(TextRole.callout)
                          .copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                key: const Key('recipe_close'),
                icon: AppIcons.close,
                tooltip: l10n.recipeClose,
                onPressed: onClose,
              ),
            ],
          ),
          SizedBox(height: AppDimens.space4),
          _Build(recipe: recipe, arabic: arabic),
          SizedBox(height: AppDimens.space3),
          _Facts(item: item, recipe: recipe),
          SizedBox(height: AppDimens.space6),
          Semantics(
            header: true,
            child: Text(
              l10n.recipeSteps,
              style: context.text(TextRole.headline).copyWith(color: p.ink),
            ),
          ),
          SizedBox(height: AppDimens.space3),
          for (final (i, step) in recipe.steps.indexed)
            AppReveal(
              index: i,
              child: RecipeStepRow(
                key: Key('recipe_step_$i'),
                number: i + 1,
                step: step,
                arabic: arabic,
                last: i == recipe.steps.length - 1,
              ),
            ),
          SizedBox(height: AppDimens.space4),
          Center(
            child: AppButton(
              key: const Key('recipe_step_by_step'),
              label: l10n.recipeStepByStep,
              icon: AppIcons.play,
              onPressed: onStepByStep,
            ),
          ),
        ],
      ),
    );
  }
}

/// The cup and, next to it, each layer top to bottom (as the eye reads the
/// drawing) with its colour and amount.
class _Build extends StatelessWidget {
  const new({required this.recipe, required this.arabic});

  final Recipe recipe;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final topDown = recipe.layers.reversed.toList();
    return Container(
      padding: EdgeInsetsDirectional.all(AppDimens.space3),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          RecipeCup(
            key: const Key('recipe_cup'),
            recipe: recipe,
            semanticLabel: l10n.recipeCupLabel(
              [
                for (final l in recipe.layers)
                  '${l.name(arabic: arabic)} ${l10n.recipeLayerMl(l.ml)}',
              ].join(arabic ? '، ' : ', '),
            ),
          ),
          SizedBox(width: AppDimens.space3),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, layer) in topDown.indexed) ...[
                    if (i > 0) SizedBox(height: AppDimens.space2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: AppDimens.space1,
                          ),
                          child: Container(
                            width: AppDimens.legendSwatch,
                            height: AppDimens.legendSwatch,
                            decoration: BoxDecoration(
                              color: layerColor(layer.tone),
                              borderRadius: BorderRadius.circular(
                                AppDimens.space1,
                              ),
                              border: Border.all(color: p.line),
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimens.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                layer.name(arabic: arabic),
                                style: context
                                    .text(TextRole.label)
                                    .copyWith(color: p.ink),
                              ),
                              Text(
                                l10n.recipeLayerMl(layer.ml),
                                style: context
                                    .text(TextRole.caption)
                                    .copyWith(color: p.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hot or iced, and how long it takes.
class _Facts extends StatelessWidget {
  const new({required this.item, required this.recipe});

  final CatalogItem item;
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final temp = switch (item.traits['temp']) {
      'hot' => (AppIcons.hot, l10n.recipeHot),
      'cold' => (AppIcons.cold, l10n.recipeCold),
      'both' => (AppIcons.hot, l10n.recipeHotOrCold),
      _ => null,
    };
    final minutes = recipe.minutes;
    final time = minutes >= 60
        ? l10n.recipeHours((minutes / 60).round())
        : l10n.recipeMinutes(minutes);
    return Wrap(
      spacing: AppDimens.space2,
      runSpacing: AppDimens.space2,
      children: [
        if (temp != null) _Fact(icon: temp.$1, label: temp.$2),
        _Fact(icon: AppIcons.time, label: time),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const new({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.text(TextRole.label).copyWith(color: p.brand);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space3,
        vertical: AppDimens.space1,
      ),
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: AppDimens.iconChip, color: p.brand),
          ),
          SizedBox(width: AppDimens.space1),
          Flexible(child: Text(label, style: style)),
        ],
      ),
    );
  }
}

/// One numbered step: a dot with its number, joined to the next by a line
/// (the order matters), then what to do, why or how, and how much.
class RecipeStepRow extends StatelessWidget {
  const new({
    required this.number,
    required this.step,
    required this.arabic,
    required this.last,
    super.key,
  });

  final int number;
  final RecipeStep step;
  final bool arabic;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final title = step.title(arabic: arabic);
    final note = step.note(arabic: arabic);
    final amount = step.amount(arabic: arabic);
    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Semantics(
                  label: l10n.recipeStepNumber(number),
                  excludeSemantics: true,
                  child: Container(
                    width: AppDimens.stepDot,
                    height: AppDimens.stepDot,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.surfaceRaised,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.brand, width: 1.5),
                    ),
                    child: Text(
                      '$number',
                      style: context
                          .text(TextRole.label)
                          .copyWith(color: p.brand),
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: AppDimens.stepLine, color: p.line),
                  ),
              ],
            ),
            SizedBox(width: AppDimens.space3),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: AppDimens.space1,
                  bottom: last ? 0 : AppDimens.space4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context
                          .text(TextRole.callout)
                          .copyWith(color: p.ink, fontWeight: FontWeight.w600),
                    ),
                    if (note != null) ...[
                      SizedBox(height: AppDimens.space1),
                      Text(
                        note,
                        style: context
                            .text(TextRole.cardBody)
                            .copyWith(color: p.inkMuted),
                      ),
                    ],
                    if (amount != null) ...[
                      SizedBox(height: AppDimens.space2),
                      AmountTag(amount: amount),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How much, in a small outlined tag («18 جرام بن»). [onBand] on the
/// header band (step by step).
class AmountTag extends StatelessWidget {
  const new({required this.amount, this.onBand = false, super.key});

  final String amount;
  final bool onBand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space2,
        vertical: onBand ? AppDimens.space1 : 0,
      ),
      decoration: BoxDecoration(
        color: onBand ? AppColors.onHeaderFaint : p.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: onBand ? null : Border.all(color: p.line),
      ),
      child: Text(
        amount,
        style: context
            .text(onBand ? TextRole.callout : TextRole.caption)
            .copyWith(color: onBand ? AppColors.onHeader : p.ink),
      ),
    );
  }
}
