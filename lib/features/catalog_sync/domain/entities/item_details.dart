import 'package:meta/meta.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/detail_parts.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/recipe.dart';

export 'package:yaani_eh/features/catalog_sync/domain/entities/detail_parts.dart';

/// The kind of details a section's items carry (`categories.detail_kind`).
/// A new kind ships in an app update; content can add sections of a kind
/// the app knows without one.
enum DetailKind {
  /// Drinks: how it's made (the cup + steps).
  recipe,

  /// History: what happened, in order, then causes and results.
  story,

  /// Terms: used in a sentence, its opposite, related words.
  usage;

  /// `null` for anything else (a kind newer than this app).
  static DetailKind? parse(Object? value) => values.asNameMap()[value];
}

/// The one kind of details an item adds to the shared core (name, «يعني»,
/// explanation…). Every kind is built from [steps] and [sections].
@immutable
sealed class ItemDetails {
  const new();

  /// In order; step by step works for any of them.
  List<DetailStep> get steps;
  List<DetailSection> get sections;
}

/// «طريقة التحضير»: the cup to scale and the steps.
final class RecipeDetails extends ItemDetails {
  const new(this.recipe);

  final Recipe recipe;

  @override
  List<DetailStep> get steps => recipe.steps;

  @override
  List<DetailSection> get sections => const [];

  @override
  bool operator ==(Object other) =>
      other is RecipeDetails && other.recipe == recipe;

  @override
  int get hashCode => recipe.hashCode;
}

/// «الحكاية»: events in order, then sections (causes, results…).
final class StoryDetails extends ItemDetails {
  const new({required this.steps, this.sections = const []});

  @override
  final List<DetailStep> steps;

  @override
  final List<DetailSection> sections;

  @override
  bool operator ==(Object other) =>
      other is StoryDetails &&
      listEquals(other.steps, steps) &&
      listEquals(other.sections, sections);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(steps), Object.hashAll(sections));
}

/// «إزاي تستخدمها»: sections only (in a sentence, opposite, related).
final class UsageDetails extends ItemDetails {
  const new({required this.sections});

  @override
  List<DetailStep> get steps => const [];

  @override
  final List<DetailSection> sections;

  @override
  bool operator ==(Object other) =>
      other is UsageDetails && listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hashAll(sections);
}

/// Details of a kind this app doesn't know yet (content is newer than the
/// app): the page asks to update instead of hiding them.
final class UnknownDetails extends ItemDetails {
  const new(this.kind);

  final String kind;

  @override
  List<DetailStep> get steps => const [];

  @override
  List<DetailSection> get sections => const [];

  @override
  bool operator ==(Object other) =>
      other is UnknownDetails && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}
