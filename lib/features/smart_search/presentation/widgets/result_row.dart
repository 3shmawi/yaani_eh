import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/smart_search/domain/entities/search_text.dart';

/// One search result (Design System → ResultRow): the photo fills the
/// row's height at the start edge, then the name, Arabic spelling, the
/// explanation with matched words in bold `brand`, and calories / price.
class ResultRow extends StatelessWidget {
  const new({
    required this.item,
    this.highlight = const {},
    this.onTap,
    super.key,
  });

  final CatalogItem item;

  /// Normalized words to highlight (from the search).
  final Set<String> highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final explanation = arabic ? item.explanationAr : item.explanationEn;
    final meta = drinkMeta(context, item);
    final radius = BorderRadius.circular(AppDimens.radiusLg);
    return Semantics(
      button: onTap != null,
      label: [item.menuName, item.menuNameAr, explanation, ?meta].join('، '),
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: radius,
              boxShadow: p.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: AppDimens.rowMinHeight),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: AppDimens.rowImage,
                        child: DrinkPhoto(
                          name: item.menuName,
                          imagePath: item.imagePath,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(AppDimens.space3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.menuName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.forText(
                                  item.menuName,
                                  TextRole.headline,
                                ).copyWith(color: p.ink),
                              ),
                              Text(
                                item.menuNameAr,
                                style: AppTextStyles.forText(
                                  item.menuNameAr,
                                  TextRole.caption,
                                ).copyWith(color: p.inkMuted),
                              ),
                              SizedBox(height: AppDimens.space1),
                              Text.rich(
                                highlighted(context, explanation, highlight),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.forText(
                                  explanation,
                                  TextRole.callout,
                                ).copyWith(color: p.ink),
                              ),
                              if (meta != null)
                                Text(
                                  meta,
                                  style: context
                                      .text(TextRole.caption)
                                      .copyWith(color: p.inkMuted),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [text] with the words in [highlight] in bold `brand`.
TextSpan highlighted(BuildContext context, String text, Set<String> highlight) {
  if (highlight.isEmpty) return TextSpan(text: text);
  final p = context.palette;
  final spans = <InlineSpan>[];
  var at = 0;
  for (final word in SearchText.words(text)) {
    final raw = SearchText.normalize(text.substring(word.start, word.end));
    if (!highlight.contains(word.token) && !highlight.contains(raw)) continue;
    if (word.start > at) {
      spans.add(TextSpan(text: text.substring(at, word.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(word.start, word.end),
        style: TextStyle(color: p.brand, fontWeight: FontWeight.w700),
      ),
    );
    at = word.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(children: spans);
}
