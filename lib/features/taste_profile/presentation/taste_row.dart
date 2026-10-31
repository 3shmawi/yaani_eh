import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/presentation/drink_preview.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_controller.dart';
import 'package:yaani_eh/features/taste_profile/presentation/widgets/taste_row.dart';

/// Wires «على ذوقك» for one section to [TasteRowView]. Nothing for a
/// section without taste questions (desserts, for now).
class TasteRow extends ConsumerWidget {
  const new({required this.section, required this.onOpenItem, super.key});

  /// The section's slug.
  final String section;
  final ValueChanged<CatalogItem> onOpenItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(tasteQuestionsProvider(section)).isEmpty) {
      return const SizedBox.shrink();
    }
    return TasteRowView(
      taken: ref.watch(tasteProvider(section)) != null,
      matches: ref.watch(tasteMatchesProvider(section)),
      onStart: () => unawaited(context.push<void>(AppRoutes.tasteFor(section))),
      onOpenItem: (item, rank) {
        unawaited(
          Analytics.capture('taste_match_opened', {
            'drink': item.slug,
            'rank': rank,
          }),
        );
        onOpenItem(item);
      },
      onPreviewItem: (item) => unawaited(
        showDrinkPreview(context, ref, item, onOpen: () => onOpenItem(item)),
      ),
      cardTrailingAction: (item) =>
          FavoriteButton(item: item, from: FavoriteSource.card),
    );
  }
}
