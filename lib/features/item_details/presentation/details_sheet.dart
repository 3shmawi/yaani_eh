import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/presentation/details_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Opens a story's or a term's details in a glass sheet (a recipe opens
/// `showRecipeSheet`, with its cup). «خطوة بخطوة» closes it and opens
/// `/item/<slug>/steps`.
Future<void> showDetailsSheet(
  BuildContext context,
  CatalogItem item, {
  required String title,
}) async {
  final details = item.details;
  if (details == null || details is UnknownDetails) return;
  unawaited(
    Analytics.capture('details_opened', {
      'item': item.slug,
      'kind': switch (details) {
        RecipeDetails() => 'recipe',
        StoryDetails() => 'story',
        UsageDetails() => 'usage',
        UnknownDetails() => 'unknown',
      },
    }),
  );
  final router = GoRouter.maybeOf(context);
  await showAppSheet(
    context,
    closeLabel: context.l10n.recipeClose,
    builder: (sheet) => DetailsView(
      item: item,
      details: details,
      title: title,
      onClose: () => Navigator.of(sheet).pop(),
      onStepByStep: details.steps.isEmpty
          ? null
          : () {
              Navigator.of(sheet).pop();
              if (router != null) {
                unawaited(router.push<void>(AppRoutes.itemSteps(item.slug)));
              }
            },
    ),
  );
}
