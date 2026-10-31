import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The browse unit (Design System → DrinkCard): a 3:4 photo tile with its
/// controls in clear glass and, at its bottom, over a soft shadow (no box),
///
/// 1. the menu name, exactly as cafe menus print it (to find it),
/// 2. its Arabic spelling (to say it);
///
/// then, under the photo on the solid surface,
///
/// 3. the «يعني» line, what it is in everyday words (why the app exists).
///    Never cut: lines are short (≤ 60 characters in the database), so it
///    shows whole; it always takes at least two lines so a row lines up.
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

  /// Small cards in a strip (similar drinks): the photo with its name and
  /// spelling only, filling the strip's height.
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
    // The shadow gets darker where text must read with Reduce
    // Transparency / Increase Contrast.
    final scrim = AppUi.isLite(context)
        ? AppColors.photoScrimStrong
        : AppColors.photoScrim;

    Widget picture = DrinkPhoto(
      name: item.menuName,
      imagePath: item.imagePath,
      size: PhotoSize.thumbnail,
    );
    if (hero) picture = Hero(tag: heroTag(item.id), child: picture);

    final names = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.space3,
        AppDimens.space6,
        AppDimens.space3,
        AppDimens.space3,
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
              TextRole.cardTitle,
            ).copyWith(color: AppColors.onHeader, shadows: _textShadow),
          ),
          Text(
            item.menuNameAr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.forText(item.menuNameAr, TextRole.cardBody)
                .copyWith(
                  color: AppColors.onHeaderMuted,
                  fontWeight: FontWeight.w500,
                  shadows: _textShadow,
                ),
          ),
        ],
      ),
    );

    final action = this.action;
    Widget photo = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: p.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            picture,
            // A soft shadow from the middle down, so the name reads on any
            // photo without a box around it.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scrim.withValues(alpha: 0), scrim],
                  stops: const [0.45, 1],
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: ExcludeSemantics(child: names),
            ),
            if (!compact && action != null)
              PositionedDirectional(
                top: AppDimens.space1,
                start: AppDimens.space1,
                child: action,
              ),
          ],
        ),
      ),
    );
    if (!compact) {
      photo = AspectRatio(aspectRatio: DrinkPhoto.aspectRatio, child: photo);
    }

    final body = gist == null
        ? photo
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              photo,
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: AppDimens.space2,
                  start: AppDimens.space1,
                  end: AppDimens.space1,
                ),
                child: ExcludeSemantics(child: _Meaning(gist: gist)),
              ),
            ],
          );

    // The play button keeps its own semantics; the card reads as one
    // button with its three lines.
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

  /// Lifts the name off bright spots of a photo.
  static const _textShadow = [
    Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1)),
  ];
}

/// «يعني ميلك شيك بالقهوة»: the lead word in `brand`, the meaning in ink.
/// Takes at least two lines of space, so the cards in a row line up, and
/// shows whole however long it is.
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
        style: style,
      ),
    );
  }
}
