import 'package:meta/meta.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/detail_parts.dart';

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
    for (final t in values) snakeCase(t.name): t,
  };
}

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

/// «طريقة التحضير»: the cup's layers to scale and the steps in order.
@immutable
class Recipe {
  const new({required this.minutes, required this.layers, required this.steps});

  /// Total time, from a minute (a shot) to a night (cold brew).
  final int minutes;
  final List<RecipeLayer> layers;
  final List<DetailStep> steps;

  /// The cup, in ml: every layer added up.
  int get totalMl => layers.fold(0, (sum, l) => sum + l.ml);

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.minutes == minutes &&
      listEquals(other.layers, layers) &&
      listEquals(other.steps, steps);

  @override
  int get hashCode =>
      Object.hash(minutes, Object.hashAll(layers), Object.hashAll(steps));
}
