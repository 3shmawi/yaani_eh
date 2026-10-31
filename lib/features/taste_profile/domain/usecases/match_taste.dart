import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';

/// How close a drink is to someone's taste, and why.
class TasteMatch {
  const new({required this.item, required this.score, required this.why});

  final CatalogItem item;

  /// 0…1: the share of the answers the drink fits.
  final double score;

  /// The answers it fits, in order («ساقع»، «حلو»، «بلبن»): the line under
  /// the card that says why it's on the list.
  final List<TasteOption> why;
}

/// Scores drinks against a [TasteProfile]. Per answered trait:
/// - a choice fits when it's the same, or either side is «الاتنين» (`both`);
/// - a scale fits by distance (an exact match is 1, the far end is 0);
/// - yes / no fits when it's the same.
/// The score is the average over the answered traits; a drink without that
/// trait counts as half a fit. An answer «fits» for [TasteMatch.why] from
/// 2/3 up.
class MatchTaste {
  const new();

  static const String both = 'both';
  static const double _fits = 2 / 3;

  TasteMatch score(
    CatalogItem item,
    TasteProfile profile,
    List<TasteQuestion> questions,
  ) {
    var total = 0.0;
    var count = 0;
    final why = <TasteOption>[];
    for (final q in questions) {
      final answer = profile.answers[q.key];
      if (answer == null) continue;
      final fit = _fit(q, answer, item.traits[q.key]);
      total += fit;
      count++;
      if (fit >= _fits) {
        final option = q.optionFor(answer);
        if (option != null) why.add(option);
      }
    }
    return TasteMatch(
      item: item,
      score: count == 0 ? 0 : total / count,
      why: why,
    );
  }

  /// The drinks that fit best, best first; ties keep the menu's order.
  /// Only drinks fitting at least [minScore], at most [limit] of them.
  List<TasteMatch> rank(
    List<CatalogItem> items,
    TasteProfile profile,
    List<TasteQuestion> questions, {
    int limit = 8,
    double minScore = 0.6,
  }) {
    if (profile.isEmpty || questions.isEmpty) return const [];
    final scored =
        [
          for (final (i, item) in items.indexed)
            (i, score(item, profile, questions)),
        ]..sort((a, b) {
          final byScore = b.$2.score.compareTo(a.$2.score);
          return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
        });
    return [
      for (final (_, m) in scored)
        if (m.score >= minScore) m,
    ].take(limit).toList();
  }

  static double _fit(TasteQuestion q, Object answer, Object? trait) {
    if (trait == null) return 0.5;
    switch (q.kind) {
      case TasteKind.choice:
        if (answer == both || trait == both) return 1;
        return answer == trait ? 1 : 0;
      case TasteKind.scale:
        if (answer is! int || trait is! num) return 0.5;
        final values = q.options.map((o) => o.value as int);
        final range =
            values.reduce((a, b) => a > b ? a : b) -
            values.reduce((a, b) => a < b ? a : b);
        if (range == 0) return answer == trait ? 1 : 0;
        return (1 - (answer - trait).abs() / range).clamp(0.0, 1.0);
      case TasteKind.yesNo:
        return answer == trait ? 1 : 0;
    }
  }
}
