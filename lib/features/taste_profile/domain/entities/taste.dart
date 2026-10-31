import 'package:meta/meta.dart';

/// How a section's trait is answered: one of a few values (hot / iced),
/// a point on a scale (sweetness 0–3) or yes / no (milk).
enum TasteKind { choice, scale, yesNo }

/// One answer to a [TasteQuestion], in both languages.
@immutable
class TasteOption {
  const new({required this.value, required this.ar, required this.en});

  /// What's stored and compared with a drink's trait: a string (choice),
  /// an int (scale) or a bool (yes / no).
  final Object value;
  final String ar;
  final String en;

  String label({required bool arabic}) => arabic ? ar : en;

  @override
  bool operator ==(Object other) =>
      other is TasteOption &&
      other.value == value &&
      other.ar == ar &&
      other.en == en;

  @override
  int get hashCode => Object.hash(value, ar, en);
}

/// One question of «ذوقي», read from the section's `trait_schema` (content,
/// so desserts can bring their own).
@immutable
class TasteQuestion {
  const new({
    required this.key,
    required this.kind,
    required this.questionAr,
    required this.questionEn,
    required this.options,
  });

  /// The trait it asks about (`temp`, `sweetness`…), as on each drink.
  final String key;
  final TasteKind kind;
  final String questionAr;
  final String questionEn;
  final List<TasteOption> options;

  String question({required bool arabic}) => arabic ? questionAr : questionEn;

  /// The option for a stored [value], if any.
  TasteOption? optionFor(Object? value) =>
      options.where((o) => o.value == value).firstOrNull;
}

/// What someone likes, for one section: an answer per trait key. A trait
/// left out means «مش فارقة معايا».
@immutable
class TasteProfile {
  const new(this.answers);

  final Map<String, Object> answers;

  bool get isEmpty => answers.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is TasteProfile &&
      other.answers.length == answers.length &&
      answers.entries.every((e) => other.answers[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    answers.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
