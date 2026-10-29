/// Script detection and bidi isolates for mixed Arabic/Latin text.
///
/// Arabic layouts must keep Latin names and number ranges left-to-right:
/// without an isolate, `70–150` inside RTL text renders as `150–70`.
abstract final class Bidi {
  static const _lri = '\u2066'; // left-to-right isolate
  static const _pdi = '\u2069'; // pop directional isolate

  static final _arabic = RegExp(
    '[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  /// Whether [text] contains any Arabic letter.
  static bool hasArabic(String text) => _arabic.hasMatch(text);

  /// Wraps [text] in a left-to-right isolate (ranges, `0.75×`, Latin names).
  static String ltr(String text) => '$_lri$text$_pdi';

  /// A number range as menus print it, kept left-to-right: `70–150`.
  static String range(int min, int max) =>
      min == max ? ltr('$min') : ltr('$min–$max');
}
