import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_pattern.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_look.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// «خطوة بخطوة»: one step at a time in big text on the header band, for
/// making the drink at home. Swipe or tap «الخطوة الجاية»; a selection tick
/// is felt on every step. The last step's button is «خلصت، بالهنا».
class StepByStepView extends StatefulWidget {
  const new({
    required this.item,
    required this.recipe,
    required this.onClose,
    required this.onFinished,
    super.key,
  });

  final CatalogItem item;
  final Recipe recipe;
  final VoidCallback onClose;

  /// The last step's button.
  final VoidCallback onFinished;

  @override
  State<StepByStepView> createState() => _StepByStepViewState();
}

class _StepByStepViewState extends State<StepByStepView> {
  final _pages = PageController();
  var _index = 0;

  List<RecipeStep> get _steps => widget.recipe.steps;
  bool get _last => _index == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: AppMotion.step,
        curve: AppMotion.enter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flat = AppUi.isLite(context);
    return Material(
      key: const Key('step_by_step'),
      color: AppColors.espresso,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: flat
              ? null
              : const LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [AppColors.headerTop, AppColors.headerBottom],
                ),
        ),
        child: Stack(
          children: [
            if (!flat) const Positioned.fill(child: HeaderPattern()),
            SafeArea(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppDimens.space4,
                  AppDimens.space2,
                  AppDimens.space4,
                  AppDimens.space4,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Progress(
                            done: _index + 1,
                            total: _steps.length,
                          ),
                        ),
                        SizedBox(width: AppDimens.space3),
                        AppIconButton(
                          key: const Key('steps_close'),
                          icon: AppIcons.close,
                          tooltip: l10n.recipeClose,
                          tone: GlassTone.dark,
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    Expanded(
                      child: PageView.builder(
                        key: const Key('steps_pages'),
                        controller: _pages,
                        itemCount: _steps.length,
                        onPageChanged: (i) {
                          unawaited(HapticFeedback.selectionClick());
                          setState(() => _index = i);
                        },
                        itemBuilder: (context, i) => _StepPage(
                          key: Key('steps_page_$i'),
                          number: i + 1,
                          total: _steps.length,
                          step: _steps[i],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        AnimatedOpacity(
                          opacity: _index == 0 ? 0 : 1,
                          duration: AppMotion.select,
                          child: IgnorePointer(
                            ignoring: _index == 0,
                            child: ExcludeSemantics(
                              excluding: _index == 0,
                              child: AppIconButton(
                                key: const Key('steps_previous'),
                                icon: AppIcons.back,
                                tooltip: l10n.stepPrevious,
                                tone: GlassTone.dark,
                                onPressed: () => _go(_index - 1),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimens.space3),
                        Expanded(
                          child: AppButton(
                            key: const Key('steps_next'),
                            kind: AppButtonKind.band,
                            expand: true,
                            label: _last ? l10n.stepDone : l10n.stepNext,
                            onPressed: _last
                                ? widget.onFinished
                                : () => _go(_index + 1),
                          ),
                        ),
                      ],
                    ),
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

/// A segment per step; the ones done (and this one) in warm milk.
class _Progress extends StatelessWidget {
  const new({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.stepOf(done, total),
    liveRegion: true,
    excludeSemantics: true,
    child: Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: AppDimens.space1),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.select,
              height: AppDimens.progressHeight,
              decoration: BoxDecoration(
                color: i < done ? AppColors.selected : AppColors.onHeaderFaint,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _StepPage extends StatelessWidget {
  const new({
    required this.number,
    required this.total,
    required this.step,
    super.key,
  });

  final int number;
  final int total;
  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final note = step.note(arabic: arabic);
    final amount = step.amount(arabic: arabic);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppDimens.space2,
          vertical: AppDimens.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: AppDimens.stepArt,
                height: AppDimens.stepArt,
                decoration: const BoxDecoration(
                  color: AppColors.onHeaderFaint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stepIcon(step.icon),
                  size: AppDimens.stepArtIcon,
                  color: AppColors.selected,
                ),
              ),
            ),
            SizedBox(height: AppDimens.space5),
            Text(
              context.l10n.stepOf(number, total),
              style: context
                  .text(TextRole.label)
                  .copyWith(color: AppColors.onHeaderMuted),
            ),
            SizedBox(height: AppDimens.space2),
            Semantics(
              header: true,
              child: Text(
                step.title(arabic: arabic),
                textAlign: TextAlign.center,
                style: context
                    .text(TextRole.title)
                    .copyWith(color: AppColors.onHeader),
              ),
            ),
            if (note != null) ...[
              SizedBox(height: AppDimens.space3),
              Text(
                note,
                textAlign: TextAlign.center,
                style: context
                    .text(TextRole.body)
                    .copyWith(color: AppColors.onHeaderMuted),
              ),
            ],
            if (amount != null) ...[
              SizedBox(height: AppDimens.space4),
              AmountTag(amount: amount, onBand: true),
            ],
          ],
        ),
      ),
    );
  }
}
