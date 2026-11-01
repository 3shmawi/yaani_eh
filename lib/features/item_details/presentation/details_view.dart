import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// An item's details that aren't a recipe (a recipe has its cup:
/// `RecipeView`): the title the section gives them («الحكاية», «إزاي
/// تستخدمها»), the steps in order with their dates, then each section as
/// a title and short lines. «خطوة بخطوة» when there are steps.
class DetailsView extends StatelessWidget {
  const new({
    required this.item,
    required this.details,
    required this.title,
    required this.onClose,
    this.onStepByStep,
    super.key,
  });

  final CatalogItem item;
  final ItemDetails details;

  /// From the section (content), e.g. «الحكاية».
  final String title;
  final VoidCallback onClose;

  /// null hides «خطوة بخطوة» (no steps).
  final VoidCallback? onStepByStep;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final steps = details.steps;
    return SingleChildScrollView(
      key: const Key('details_view'),
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
                      title,
                      style: AppTextStyles.forText(
                        title,
                        TextRole.callout,
                      ).copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                key: const Key('details_close'),
                icon: AppIcons.close,
                tooltip: l10n.recipeClose,
                onPressed: onClose,
              ),
            ],
          ),
          SizedBox(height: AppDimens.space4),
          for (final (i, step) in steps.indexed)
            AppReveal(
              index: i,
              child: RecipeStepRow(
                key: Key('details_step_$i'),
                number: i + 1,
                step: step,
                arabic: arabic,
                last: i == steps.length - 1,
              ),
            ),
          if (steps.isNotEmpty && onStepByStep != null) ...[
            SizedBox(height: AppDimens.space4),
            Center(
              child: AppButton(
                key: const Key('details_step_by_step'),
                label: l10n.recipeStepByStep,
                icon: AppIcons.play,
                onPressed: onStepByStep,
              ),
            ),
          ],
          for (final (i, section) in details.sections.indexed) ...[
            SizedBox(height: AppDimens.space6),
            DetailSectionBlock(
              key: Key('details_section_$i'),
              section: section,
              arabic: arabic,
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled list of short lines: «في جملة», «الأسباب».
class DetailSectionBlock extends StatelessWidget {
  const new({required this.section, required this.arabic, super.key});

  final DetailSection section;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final title = section.title(arabic: arabic);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppTextStyles.forText(
              title,
              TextRole.headline,
            ).copyWith(color: p.ink),
          ),
        ),
        SizedBox(height: AppDimens.space2),
        for (final line in section.lines(arabic: arabic))
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: AppDimens.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: AppDimens.space2,
                      end: AppDimens.space3,
                    ),
                    child: Container(
                      width: AppDimens.space2,
                      height: AppDimens.space2,
                      decoration: BoxDecoration(
                        color: p.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: AppTextStyles.forText(
                      line,
                      TextRole.body,
                    ).copyWith(color: p.ink),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
