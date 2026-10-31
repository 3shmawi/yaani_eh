import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/pronunciation/domain/usecases/clips_for.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronunciation_controller.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The long press on a drink card: what it is at a glance (photo, name,
/// spelling, «يعني» line, the start of the explanation), with «اسمع الاسم»
/// (when it has a clip), save / remove and «افتح المشروب».
Future<void> showDrinkPreview(
  BuildContext context,
  WidgetRef ref,
  CatalogItem item, {
  required VoidCallback onOpen,
}) {
  final l10n = context.l10n;
  final saved = ref.read(favoriteIdsProvider).contains(item.id);
  unawaited(Analytics.capture('drink_previewed', {'drink': item.slug}));
  return showAppPreviewMenu(
    context,
    closeLabel: l10n.previewClose,
    preview: DrinkPreview(item: item),
    actions: [
      if (const ClipsFor()(item).isNotEmpty)
        AppPreviewAction(
          key: const Key('preview_hear'),
          icon: AppIcons.speaker,
          label: l10n.previewHear,
          onSelected: () =>
              ref.read(pronunciationProvider.notifier).toggleFirst(item),
        ),
      AppPreviewAction(
        key: const Key('preview_save'),
        icon: saved ? AppIconsFill.heart : AppIcons.heart,
        label: saved ? l10n.previewUnsave : l10n.previewSave,
        onSelected: () => ref
            .read(favoritesControllerProvider)
            .toggle(item, FavoriteSource.preview),
      ),
      AppPreviewAction(
        key: const Key('preview_open'),
        icon: AppIcons.forward,
        label: l10n.previewOpen,
        onSelected: onOpen,
      ),
    ],
  );
}

/// The card inside the preview.
class DrinkPreview extends StatelessWidget {
  const new({required this.item, super.key});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final explanation = arabic ? item.explanationAr : item.explanationEn;
    return Column(
      key: const Key('drink_preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: AppDimens.previewPhotoRatio,
          child: DrinkPhoto(
            name: item.menuName,
            imagePath: item.imagePath,
            size: PhotoSize.thumbnail,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.all(AppDimens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.menuName,
                style: AppTextStyles.forText(
                  item.menuName,
                  TextRole.headline,
                ).copyWith(color: p.ink),
              ),
              Text(
                item.menuNameAr,
                style: AppTextStyles.forText(
                  item.menuNameAr,
                  TextRole.cardBody,
                ).copyWith(color: p.inkMuted),
              ),
              SizedBox(height: AppDimens.space2),
              DrinkMeaning(gist: item.gist(arabic: arabic), minLines: 1),
              SizedBox(height: AppDimens.space2),
              Text(
                explanation,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.forText(
                  explanation,
                  TextRole.cardBody,
                ).copyWith(color: p.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
