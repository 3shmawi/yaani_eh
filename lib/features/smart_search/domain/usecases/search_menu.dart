import 'dart:math' as math;

import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/smart_search/domain/entities/search_text.dart';

/// Extra ranking signals (favorites, taste, recently viewed). Each returns
/// how much to boost an item, e.g. 0.5 for a favorite; the score is
/// `text × (1 + boost)`.
abstract interface class SearchBoosts {
  double boost(CatalogItem item);
}

class NoBoosts implements SearchBoosts {
  const new();

  @override
  double boost(CatalogItem item) => 0;
}

/// One result.
class SearchHit {
  const new({
    required this.item,
    required this.score,
    required this.byName,
    required this.matched,
  });

  final CatalogItem item;
  final double score;

  /// Matched through its name (vs. its description).
  final bool byName;

  /// Normalized words of the item that matched (to highlight them).
  final Set<String> matched;
}

/// What a query found.
class SearchResults {
  const new({
    required this.query,
    required this.hits,
    this.answer,
    this.suggestions = const [],
  });

  static const empty = SearchResults(query: '', hits: []);

  final String query;

  /// The drink the query names, if it names one (the AnswerCard).
  final SearchHit? answer;

  /// Everything else, best first.
  final List<SearchHit> hits;

  /// "Did you mean", when nothing matched every word.
  final List<CatalogItem> suggestions;

  bool get isEmpty => answer == null && hits.isEmpty;
}

/// Two-way, on-device search over the cached catalog: a name gets an
/// answer, a description ("milk and coffee", `laban w ahwa`) gets a ranked
/// list. Build once per catalog change; each query is cheap.
class SearchMenu {
  new(List<CatalogItem> items) : _entries = [for (final i in items) _Entry(i)];

  final List<_Entry> _entries;

  /// Longest query considered (characters) and words used.
  static const maxQueryLength = 60;
  static const maxWords = 8;

  SearchResults call(
    String query, {
    SearchBoosts boosts = const NoBoosts(),
    int limit = 40,
  }) {
    final trimmed = query.trim();
    final capped = trimmed.length > maxQueryLength
        ? trimmed.substring(0, maxQueryLength)
        : trimmed;
    final words = {...SearchText.tokens(capped)}.take(maxWords).toList();
    if (words.isEmpty) return SearchResults.empty;
    final phrase = SearchText.normalize(capped);

    final hits = <SearchHit>[];
    final partial = <(_Entry, double)>[];
    for (final entry in _entries) {
      final scored = entry.score(words, phrase);
      if (scored == null) continue;
      final (text, coverage, byName, matched) = scored;
      final needed = words.length <= 2 ? 1.0 : 0.6;
      if (coverage < needed) {
        if (coverage > 0) partial.add((entry, text));
        continue;
      }
      hits.add(
        SearchHit(
          item: entry.item,
          score: text * (1 + math.max(0, boosts.boost(entry.item))),
          byName: byName,
          matched: matched,
        ),
      );
    }
    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0
          ? byScore
          : a.item.sortOrder.compareTo(b.item.sortOrder);
    });

    // An answer: the query *is* a drink name (or one typo away).
    SearchHit? answer;
    for (final hit in hits) {
      if (_Entry.namesOf(hit.item).any((n) => _sameName(n, phrase))) {
        answer = hit;
        break;
      }
    }
    final rest = [
      for (final h in hits)
        if (!identical(h, answer)) h,
    ].take(limit).toList();

    final suggestions = hits.isEmpty
        ? ([...partial]..sort((a, b) => b.$2.compareTo(a.$2)))
              .take(3)
              .map((p) => p.$1.item)
              .toList()
        : const <CatalogItem>[];
    return SearchResults(
      query: capped,
      answer: answer,
      hits: rest,
      suggestions: suggestions,
    );
  }

  static bool _sameName(String name, String phrase) =>
      name == phrase ||
      (phrase.length >= 4 && SearchText.distance(name, phrase, max: 1) <= 1);
}

class _Entry {
  new(this.item)
    : _names = _tokens([
        item.menuName,
        item.menuNameAr,
        for (final t in item.terms)
          if (t.kind == TermKind.name || t.lang == TermLang.franco) t.term,
      ]),
      _descriptions = _tokens([
        item.explanationAr,
        item.explanationEn,
        for (final t in item.terms)
          if (t.kind != TermKind.name && t.lang != TermLang.franco) t.term,
      ]);

  final CatalogItem item;
  final Set<String> _names;
  final Set<String> _descriptions;

  /// Normalized full names (for "the query is a name").
  static Iterable<String> namesOf(CatalogItem item) => [
    SearchText.normalize(item.menuName),
    SearchText.normalize(item.menuNameAr),
    for (final t in item.terms)
      if (t.kind == TermKind.name) SearchText.normalize(t.term),
  ];

  /// Both the stemmed and the plain form of every word.
  static Set<String> _tokens(List<String> texts) => {
    for (final text in texts)
      for (final word in SearchText.normalize(text).split(' '))
        if (word.isNotEmpty) ...{word, SearchText.stem(word)},
  };

  /// (text score, share of words matched, matched by name, matched words),
  /// or null when nothing matched.
  (double, double, bool, Set<String>)? score(
    List<String> words,
    String phrase,
  ) {
    var total = 0.0;
    var hitWords = 0;
    var byName = false;
    final matched = <String>{};
    for (final word in words) {
      var best = 0.0;
      var bestIsName = false;
      String? bestToken;
      for (final token in _names) {
        final m = SearchText.match(word, token) * 3;
        if (m > best) {
          best = m;
          bestIsName = true;
          bestToken = token;
        }
      }
      for (final token in _descriptions) {
        final m = SearchText.match(word, token);
        if (m > best) {
          best = m;
          bestIsName = false;
          bestToken = token;
        }
        if (m > 0) matched.add(token);
      }
      if (best > 0) {
        hitWords++;
        total += best;
        byName |= bestIsName;
        if (bestToken != null) matched.add(bestToken);
      }
    }
    if (hitWords == 0) return null;
    final coverage = hitWords / words.length;
    var text = total / words.length * coverage;
    // The whole query starts a name: a strong signal.
    if (namesOf(item).any((n) => n.startsWith(phrase))) text += 2;
    return (text, coverage, byName, matched);
  }
}
