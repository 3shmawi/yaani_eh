import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The wide card at the top of Home: one drink a day, with its explanation
/// right on the card (Home artboard).
class DrinkOfTheDay extends StatelessWidget {
  const new({required this.item, this.onTap, super.key});

  final CatalogItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final explanation = arabic ? item.explanationAr : item.explanationEn;
    final radius = AppDimens.radiusLg;
    return Semantics(
      button: onTap != null,
      label:
          '${l10n.drinkOfTheDay}: ${item.menuName}، ${item.menuNameAr}. '
          '$explanation',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 190.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DrinkPhoto(
                      name: item.menuName,
                      imagePath: item.imagePath,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.all(AppDimens.space3),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppGlass(
                            kind: GlassKind.clear,
                            tone: GlassTone.dark,
                            radius: AppDimens.radiusPill,
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: AppDimens.space3,
                              vertical: AppDimens.space1,
                            ),
                            child: Text(
                              l10n.drinkOfTheDay,
                              style: context
                                  .text(TextRole.caption)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 56.h),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          AppDimens.space2,
                          0,
                          AppDimens.space2,
                          AppDimens.space2,
                        ),
                        child: AppGlass(
                          radius: AppDimens.radiusMd,
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: AppDimens.space3,
                            vertical: AppDimens.space2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AppDimens.space2,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  Text(
                                    item.menuName,
                                    style: AppTextStyles.forText(
                                      item.menuName,
                                      TextRole.headline,
                                    ),
                                  ),
                                  Text(
                                    item.menuNameAr,
                                    style: AppTextStyles.forText(
                                      item.menuNameAr,
                                      TextRole.caption,
                                    ).copyWith(color: p.inkMutedGlass),
                                  ),
                                ],
                              ),
                              Text(
                                explanation,
                                style: AppTextStyles.forText(
                                  explanation,
                                  TextRole.callout,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
