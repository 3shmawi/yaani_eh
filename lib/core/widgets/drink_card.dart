import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The browse unit (Design System → DrinkCard, "caption below"): the photo
/// is a clean 3:4 tile with its controls in clear glass, and the text sits
/// under it on the solid surface, where it always reads:
///
/// 1. the menu name, exactly as cafe menus print it (to find it),
/// 2. its Arabic spelling (to say it),
/// 3. the «يعني» line, what it is in everyday words (why the app exists).
///
/// No price here: the drink page has it.
class DrinkCard extends StatelessWidget {
  const new({
    required this.item,
    this.onTap,
    this.compact = false,
    this.action,
    this.hero = false,
    super.key,
  });

  final CatalogItem item;
  final VoidCallback? onTap;

  /// Small cards in a strip (similar drinks): name and spelling only; the
  /// photo takes the height that's left.
  final bool compact;

  /// A control over the photo's top-start corner (the play button); the
  /// top-end corner is the heart's. Not on compact cards.
  final Widget? action;

  /// The photo flies into the drink page ([heroTag]). Only one card per
  /// screen may do it for a drink, so only the Home grid turns it on.
  final bool hero;

  /// The drink page's photo uses the same tag.
  static Object heroTag(String itemId) => 'drink_photo_$itemId';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final gist = compact ? null : item.gist(arabic: arabic);
    final radius = AppDimens.radiusLg;

    Widget photo = DrinkPhoto(
      name: item.menuName,
      imagePath: item.imagePath,
      size: PhotoSize.thumbnail,
    );
    if (hero) photo = Hero(tag: heroTag(item.id), child: photo);
    photo = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: p.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: photo,
      ),
    );
    final action = this.action;
    if (!compact && action != null) {
      photo = Stack(
        fit: StackFit.expand,
        children: [
          photo,
          PositionedDirectional(
            top: AppDimens.space1,
            start: AppDimens.space1,
            child: action,
          ),
        ],
      );
    }

    final caption = Padding(
      padding: EdgeInsetsDirectional.only(
        top: AppDimens.space2,
        start: AppDimens.space1,
        end: AppDimens.space1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Text(
              item.menuName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.forText(
                item.menuName,
                TextRole.cardTitle,
              ).copyWith(color: p.ink),
            ),
          ),
          ExcludeSemantics(
            child: Text(
              item.menuNameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.forText(
                item.menuNameAr,
                TextRole.cardBody,
              ).copyWith(color: p.inkMuted, fontWeight: FontWeight.w500),
            ),
          ),
          if (gist != null) ...[
            SizedBox(height: AppDimens.space1),
            ExcludeSemantics(child: _Meaning(gist: gist)),
          ],
        ],
      ),
    );

    final body = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: photo),
              caption,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(aspectRatio: DrinkPhoto.aspectRatio, child: photo),
              caption,
            ],
          );

    // The play button keeps its own semantics; the card reads as one
    // button with the three lines.
    return Semantics(
      button: onTap != null,
      label: [
        item.menuName,
        item.menuNameAr,
        if (gist != null) context.l10n.cardMeaning(gist),
      ].join('، '),
      onTap: onTap,
      child: AppPressable(onTap: onTap, child: body),
    );
  }
}

/// «يعني ميلك شيك بالقهوة»: the lead word in `brand`, the meaning in ink.
/// Always takes two lines of space, so the cards in a row line up.
class _Meaning extends StatelessWidget {
  const new({required this.gist});

  final String gist;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final full = context.l10n.cardMeaning(gist);
    final at = full.indexOf(gist);
    final lead = at <= 0 ? '' : full.substring(0, at);
    final style = AppTextStyles.forText(
      full,
      TextRole.cardBody,
    ).copyWith(color: p.ink);
    final lines =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        style.height! *
        2;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: lines),
      child: Text.rich(
        TextSpan(
          children: [
            if (lead.isNotEmpty)
              TextSpan(
                text: lead,
                style: TextStyle(color: p.brand, fontWeight: FontWeight.w600),
              ),
            TextSpan(text: full.substring(at < 0 ? 0 : at)),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
