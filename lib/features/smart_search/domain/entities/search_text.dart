/// Text matching for search: normalization, tokens with their positions,
/// and edit distance. Pure Dart, no Flutter.
abstract final class SearchText {
  static final _diacritics = RegExp('[\u064B-\u065F\u0670\u0640]');
  static final _separators = RegExp(r'[\s\p{P}\p{S}]+', unicode: true);
  static final _word = RegExp(r'[^\s\p{P}\p{S}]+', unicode: true);

  static const _letters = {
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و', //
    'ئ': 'ي', 'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i',
    'ï': 'i', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ù': 'u',
    'ú': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
  };

  /// Lowercase, no diacritics or tatweel, one spelling per Arabic letter
  /// family, no Latin accents. Franco digits (2ahwa, 3asir) stay.
  static String normalize(String text) {
    final lower = text.toLowerCase().replaceAll(_diacritics, '');
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      out.write(_letters[char] ?? char);
    }
    return out.toString().replaceAll(_separators, ' ').trim();
  }

  /// Normalized words, with light Arabic prefix stripping: «القهوة» →
  /// «قهوه», «وقهوة» → «قهوه», «بالتلج» → «تلج».
  static List<String> tokens(String text) => [
    for (final word in normalize(text).split(' '))
      if (word.isNotEmpty) stem(word),
  ];

  /// Strips «و», «ال», «بال», «بـ», «لل» from the start of longer Arabic
  /// words; everything else is unchanged.
  static String stem(String word) {
    var w = word;
    if (w.length >= 4 && w.startsWith('و')) w = w.substring(1);
    for (final prefix in const ['بال', 'لل', 'ال']) {
      if (w.length >= prefix.length + 2 && w.startsWith(prefix)) {
        return w.substring(prefix.length);
      }
    }
    if (w.length >= 4 && w.startsWith('ب')) return w.substring(1);
    return w;
  }

  /// Words of [text] with where they are in it (for highlighting).
  static List<({int start, int end, String token})> words(String text) => [
    for (final m in _word.allMatches(text))
      (start: m.start, end: m.end, token: stem(normalize(m[0]!))),
  ];

  /// Levenshtein distance, stopping early once it exceeds [max].
  static int distance(String a, String b, {int max = 2}) {
    if ((a.length - b.length).abs() > max) return max + 1;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      var best = current[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = [
          previous[j] + 1,
          current[j - 1] + 1,
          previous[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
        if (current[j] < best) best = current[j];
      }
      if (best > max) return max + 1;
      previous = current;
    }
    return previous[b.length];
  }

  /// How well a query word matches a text word: 1 exact, 0.8 prefix,
  /// 0.6 one typo (words of 4+ letters), 0 otherwise.
  static double match(String query, String word) {
    if (query.isEmpty || word.isEmpty) return 0;
    if (query == word) return 1;
    if (query.length >= 2 && word.startsWith(query)) return 0.8;
    if (query.length >= 4 &&
        word.length >= 4 &&
        distance(query, word, max: 1) <= 1) {
      return 0.6;
    }
    return 0;
  }
}
