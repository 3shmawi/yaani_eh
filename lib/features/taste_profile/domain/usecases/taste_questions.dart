import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';

/// The questions of «ذوقي» from a section's `trait_schema` (raw JSON from
/// the catalog). Content is untrusted: an entry that's malformed, an
/// unknown type or a missing label is skipped, never a crash.
class TasteQuestions {
  const new();

  static const _maxQuestions = 8;
  static const _maxOptions = 6;

  List<TasteQuestion> call(List<Object?>? schema) {
    final out = <TasteQuestion>[];
    for (final entry in schema ?? const <Object?>[]) {
      if (out.length == _maxQuestions) break;
      if (entry is! Map) continue;
      final question = _question(entry);
      if (question != null) out.add(question);
    }
    return out;
  }

  static TasteQuestion? _question(Map<dynamic, dynamic> entry) {
    final key = entry['key'];
    final q = entry['question'];
    if (key is! String || key.isEmpty || key.length > 40) return null;
    if (q is! Map) return null;
    final ar = _text(q['ar']);
    final en = _text(q['en']);
    if (ar == null || en == null) return null;
    final (kind, options) = switch (entry['type']) {
      'enum' => (TasteKind.choice, _choices(entry['options'])),
      'scale' => (TasteKind.scale, _scale(entry)),
      'bool' => (TasteKind.yesNo, _yesNo(entry['labels'])),
      _ => (TasteKind.choice, const <TasteOption>[]),
    };
    if (options.length < 2 || options.length > _maxOptions) return null;
    return TasteQuestion(
      key: key,
      kind: kind,
      questionAr: ar,
      questionEn: en,
      options: options,
    );
  }

  static List<TasteOption> _choices(Object? options) => [
    if (options is List)
      for (final o in options)
        if (o is Map &&
            o['value'] is String &&
            _text(o['ar']) != null &&
            _text(o['en']) != null)
          TasteOption(
            value: o['value'] as String,
            ar: _text(o['ar'])!,
            en: _text(o['en'])!,
          ),
  ];

  static List<TasteOption> _scale(Map<dynamic, dynamic> entry) {
    final labels = entry['labels'];
    // Scales start at 0 unless the schema says otherwise.
    final min = entry['min'] ?? 0;
    if (labels is! Map || min is! int) return const [];
    final ar = labels['ar'];
    final en = labels['en'];
    if (ar is! List || en is! List || ar.length != en.length) return const [];
    return [
      for (var i = 0; i < ar.length; i++)
        if (_text(ar[i]) != null && _text(en[i]) != null)
          TasteOption(value: min + i, ar: _text(ar[i])!, en: _text(en[i])!),
    ];
  }

  /// `labels: {ar: [no, yes]}`: yes first, the way people say it.
  static List<TasteOption> _yesNo(Object? labels) {
    if (labels is! Map) return const [];
    final ar = labels['ar'];
    final en = labels['en'];
    if (ar is! List || en is! List || ar.length != 2 || en.length != 2) {
      return const [];
    }
    final no = (_text(ar[0]), _text(en[0]));
    final yes = (_text(ar[1]), _text(en[1]));
    if (no.$1 == null || no.$2 == null || yes.$1 == null || yes.$2 == null) {
      return const [];
    }
    return [
      TasteOption(value: true, ar: yes.$1!, en: yes.$2!),
      TasteOption(value: false, ar: no.$1!, en: no.$2!),
    ];
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty || text.length > 80 ? null : text;
  }
}
