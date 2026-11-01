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
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/presentation/item_controller.dart';
import 'package:yaani_eh/features/recipes/presentation/step_by_step_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// `/item/:slug/steps`: wires an item's steps (a recipe, a story) to
/// [StepByStepView]. An item that's gone, or has no steps, says so with a
/// way back.
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
      context.go(AppRoutes.item(widget.slug));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final details = ref.watch(itemStateProvider(widget.slug));
    final found = details is ItemFound ? details : null;
    final steps = found?.item.details?.steps ?? const <DetailStep>[];
    if (found == null || steps.isEmpty) {
      return Material(
        color: context.palette.surface,
        child: SafeArea(
          child: details is ItemLoading
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
          'item': found.item.slug,
        }),
      );
    }
    return StepByStepView(
      item: found.item,
      steps: steps,
      doneLabel: found.item.recipe == null ? l10n.stepsDone : null,
      onClose: _close,
      onFinished: () {
        unawaited(HapticFeedback.mediumImpact());
        unawaited(
          Analytics.capture('recipe_finished', {'item': found.item.slug}),
        );
        _close();
      },
    );
  }
}
