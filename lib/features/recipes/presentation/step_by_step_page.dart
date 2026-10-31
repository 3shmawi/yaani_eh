import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_controller.dart';
import 'package:yaani_eh/features/recipes/presentation/step_by_step_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// `/drink/:slug/steps`: wires a drink's recipe to [StepByStepView]. A
/// drink that's gone, or has no recipe yet, says so with a way back.
class StepByStepPage extends ConsumerStatefulWidget {
  const new({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<StepByStepPage> createState() => _StepByStepPageState();
}

class _StepByStepPageState extends ConsumerState<StepByStepPage> {
  bool _logged = false;

  /// Back to the drink page under this one; a deep link opened it too.
  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.drink(widget.slug));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final details = ref.watch(drinkDetailsProvider(widget.slug));
    final found = details is DrinkFound ? details : null;
    final recipe = found?.item.recipe;
    if (found == null || recipe == null) {
      return Material(
        color: context.palette.surface,
        child: SafeArea(
          child: details is DrinkLoading
              ? const LoadingView()
              : EmptyView(
                  key: const Key('steps_missing'),
                  icon: AppIcons.recipe,
                  title: l10n.recipeMissingTitle,
                  message: l10n.recipeMissingBody,
                  actionLabel: l10n.recipeClose,
                  onAction: _close,
                ),
        ),
      );
    }
    if (!_logged) {
      _logged = true;
      unawaited(
        Analytics.capture('recipe_step_mode_started', {
          'drink': found.item.slug,
        }),
      );
    }
    return StepByStepView(
      item: found.item,
      recipe: recipe,
      onClose: _close,
      onFinished: () {
        unawaited(HapticFeedback.mediumImpact());
        unawaited(
          Analytics.capture('recipe_finished', {'drink': found.item.slug}),
        );
        _close();
      },
    );
  }
}
