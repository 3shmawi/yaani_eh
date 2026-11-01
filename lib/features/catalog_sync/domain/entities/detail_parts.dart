import 'package:meta/meta.dart';

/// The two building blocks every kind of item details is made of:
/// [DetailStep]s (ordered: a recipe's steps, a story's events) and
/// [DetailSection]s (a title and short lines: causes, results, examples).

/// The picture of a step. Unknown (content newer than the app) → [other].
enum StepIcon {
  grind,
  shot,
  boil,
  steep,
  milk,
  steam,
  pour,
  ice,
  blend,
  stir,
  sweeten,
  top,
  squeeze,
  serve,
  other;

  static StepIcon parse(Object? value) => _byKey[value] ?? other;

  static final Map<String, StepIcon> _byKey = {
    for (final t in values) snakeCase(t.name): t,
  };
}

/// One step, in order: what happens, a short why or how, and optionally
/// how much (a recipe) or when (a story).
@immutable
class DetailStep {
  const new({
    required this.titleAr,
    required this.titleEn,
    this.icon,
    this.noteAr,
    this.noteEn,
    this.amountAr,
    this.amountEn,
    this.dateAr,
    this.dateEn,
  });

  /// null: the step has no picture (a story's event).
  final StepIcon? icon;
  final String titleAr;
  final String titleEn;
  final String? noteAr;
  final String? noteEn;
  final String? amountAr;
  final String? amountEn;

  /// When it happened, as text («٢٥ يناير ٢٠١١»): content decides the
  /// format, the app only shows it.
  final String? dateAr;
  final String? dateEn;

  String title({required bool arabic}) => arabic ? titleAr : titleEn;
  String? note({required bool arabic}) => arabic ? noteAr : noteEn;
  String? amount({required bool arabic}) => arabic ? amountAr : amountEn;
  String? date({required bool arabic}) => arabic ? dateAr : dateEn;

  @override
  bool operator ==(Object other) =>
      other is DetailStep &&
      other.icon == icon &&
      other.titleAr == titleAr &&
      other.titleEn == titleEn &&
      other.noteAr == noteAr &&
      other.noteEn == noteEn &&
      other.amountAr == amountAr &&
      other.amountEn == amountEn &&
      other.dateAr == dateAr &&
      other.dateEn == dateEn;

  @override
  int get hashCode => Object.hash(
    icon,
    titleAr,
    titleEn,
    noteAr,
    noteEn,
    amountAr,
    amountEn,
    dateAr,
    dateEn,
  );
}

/// A titled list of short lines: «الأسباب», «في جملة», «عكسها».
@immutable
class DetailSection {
  const new({
    required this.titleAr,
    required this.titleEn,
    required this.linesAr,
    required this.linesEn,
  });

  final String titleAr;
  final String titleEn;
  final List<String> linesAr;
  final List<String> linesEn;

  String title({required bool arabic}) => arabic ? titleAr : titleEn;
  List<String> lines({required bool arabic}) => arabic ? linesAr : linesEn;

  @override
  bool operator ==(Object other) =>
      other is DetailSection &&
      other.titleAr == titleAr &&
      other.titleEn == titleEn &&
      listEquals(other.linesAr, linesAr) &&
      listEquals(other.linesEn, linesEn);

  @override
  int get hashCode => Object.hash(
    titleAr,
    titleEn,
    Object.hashAll(linesAr),
    Object.hashAll(linesEn),
  );
}

/// `whiteChocolate` → `white_chocolate` (content keys).
String snakeCase(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
