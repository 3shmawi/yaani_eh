import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yaani_eh/core/text/bidi.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The browse unit (Design System → DrinkCard): the photo fills a 3:4 card,
/// a frosted label holds the menu name, its Arabic spelling and the price
/// range (or calories while prices aren't checked yet).
class DrinkCard extends StatelessWidget {
  const new({required this.item, this.onTap, super.key});

  final CatalogItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final meta = drinkMeta(context, item);
    final radius = AppDimens.radiusLg;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DrinkPhoto(name: item.menuName, imagePath: item.imagePath),
          PositionedDirectional(
            start: AppDimens.space2,
            end: AppDimens.space2,
            bottom: AppDimens.space2,
            child: AppGlass(
              minimal: true,
              radius: radius - 8,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space3,
                vertical: AppDimens.space2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.menuName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.forText(
                      item.menuName,
                      TextRole.headline,
                    ).copyWith(fontSize: 15.sp, height: 20 / 15),
                  ),
                  Text(
                    item.menuNameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.forText(
                      item.menuNameAr,
                      TextRole.caption,
                    ).copyWith(color: p.inkMutedGlass),
                  ),
                  if (meta != null)
                    Text(
                      meta,
                      maxLines: 1,
                      style: context
                          .text(TextRole.caption)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      label: [item.menuName, item.menuNameAr, ?meta].join('، '),
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: AspectRatio(aspectRatio: 3 / 4, child: card),
        ),
      ),
    );
  }
}

/// "70–150 EGP" when prices are known, else "190 kcal", else null.
String? drinkMeta(BuildContext context, CatalogItem item) {
  final l10n = context.l10n;
  final min = item.priceMinEgp;
  final max = item.priceMaxEgp ?? min;
  if (min != null && max != null) {
    return l10n.priceRange(Bidi.range(min, max));
  }
  final calories = item.calories;
  return calories == null ? null : l10n.calories(calories);
}
