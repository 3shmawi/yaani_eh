import 'package:meta/meta.dart';

/// What a cup layer is, for its colour. Content names the tone; a tone this
/// version doesn't know yet arrives as [other].
enum RecipeTone {
  espresso,
  coffee,
  foam,
  water,
  milk,
  condensed,
  chocolate,
  whiteChocolate,
  caramel,
  vanilla,
  cream,
  iceCream,
  ice,
  blendedCoffee,
  blendedCaramel,
  blendedChocolate,
  blendedVanilla,
  tea,
  greenTea,
  chai,
  matcha,
  hibiscus,
  mintTea,
  mango,
  strawberry,
  orange,
  lemon,
  fruit,
  berry,
  hotChocolate,
  sahlab,
  nuts,
  cookies,
  soda,
  other;

  /// `white_chocolate` → [whiteChocolate]; unknown → [other].
  static RecipeTone parse(Object? value) => _byKey[value] ?? other;

  static final Map<String, RecipeTone> _byKey = {
    for (final t in values) _snake(t.name): t,
  };
}

/// The picture of a step. Unknown → [other].
enum RecipeIcon {
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

  static RecipeIcon parse(Object? value) => _byKey[value] ?? other;

  static final Map<String, RecipeIcon> _byKey = {
    for (final t in values) _snake(t.name): t,
  };
}

String _snake(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// One layer of the cup, bottom to top.
@immutable
class RecipeLayer {
  const new({
    required this.tone,
    required this.ml,
    required this.nameAr,
    required this.nameEn,
  });

  final RecipeTone tone;
  final int ml;
  final String nameAr;
  final String nameEn;

  String name({required bool arabic}) => arabic ? nameAr : nameEn;

  @override
  bool operator ==(Object other) =>
      other is RecipeLayer &&
      other.tone == tone &&
      other.ml == ml &&
      other.nameAr == nameAr &&
      other.nameEn == nameEn;

  @override
  int get hashCode => Object.hash(tone, ml, nameAr, nameEn);
}

/// One step, in order: what to do, a short why or how, and how much.
@immutable
class RecipeStep {
  const new({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    this.noteAr,
    this.noteEn,
    this.amountAr,
    this.amountEn,
  });

  final RecipeIcon icon;
  final String titleAr;
  final String titleEn;
  final String? noteAr;
  final String? noteEn;
  final String? amountAr;
  final String? amountEn;

  String title({required bool arabic}) => arabic ? titleAr : titleEn;
  String? note({required bool arabic}) => arabic ? noteAr : noteEn;
  String? amount({required bool arabic}) => arabic ? amountAr : amountEn;

  @override
  bool operator ==(Object other) =>
      other is RecipeStep &&
      other.icon == icon &&
      other.titleAr == titleAr &&
      other.titleEn == titleEn &&
      other.noteAr == noteAr &&
      other.noteEn == noteEn &&
      other.amountAr == amountAr &&
      other.amountEn == amountEn;

  @override
  int get hashCode =>
      Object.hash(icon, titleAr, titleEn, noteAr, noteEn, amountAr, amountEn);
}

/// «طريقة التحضير»: the cup's layers to scale and the steps in order.
@immutable
class Recipe {
  const new({required this.minutes, required this.layers, required this.steps});

  /// Total time, from a minute (a shot) to a night (cold brew).
  final int minutes;
  final List<RecipeLayer> layers;
  final List<RecipeStep> steps;

  /// The cup, in ml: every layer added up.
  int get totalMl => layers.fold(0, (sum, l) => sum + l.ml);

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.minutes == minutes &&
      _listEquals(other.layers, layers) &&
      _listEquals(other.steps, steps);

  @override
  int get hashCode =>
      Object.hash(minutes, Object.hashAll(layers), Object.hashAll(steps));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
