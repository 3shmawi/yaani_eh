import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Where «طريقة التحضير» was opened from (analytics).
enum RecipeSource { preview, drinkPage }

/// Opens «طريقة التحضير» for [item] in a glass sheet; «خطوة بخطوة» closes
/// it and opens `/drink/<slug>/steps`. Does nothing for a drink without a
/// recipe (callers hide the way in).
Future<void> showRecipeSheet(
  BuildContext context,
  CatalogItem item, {
  required RecipeSource from,
}) async {
  final recipe = item.recipe;
  if (recipe == null) return;
  unawaited(
    Analytics.capture('recipe_opened', {'drink': item.slug, 'from': from.name}),
  );
  final router = GoRouter.maybeOf(context);
  await showAppSheet(
    context,
    closeLabel: context.l10n.recipeClose,
    builder: (sheet) => RecipeView(
      item: item,
      recipe: recipe,
      onClose: () => Navigator.of(sheet).pop(),
      onStepByStep: () {
        Navigator.of(sheet).pop();
        if (router != null) {
          unawaited(router.push<void>(AppRoutes.drinkSteps(item.slug)));
        }
      },
    ),
  );
}
