import 'package:meta/meta.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/item_details.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/recipe.dart';

export 'package:yaani_eh/features/catalog_sync/domain/entities/item_details.dart';
export 'package:yaani_eh/features/catalog_sync/domain/entities/recipe.dart';

/// A section (root: Café, later Restaurants…) or a chip inside one
/// (Coffee, Frappés…). Content, not code: new ones arrive with a sync.
class CatalogCategory {
  const new({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    this.parentId,
    this.icon,
    this.traitSchema,
    this.detailKind,
    this.detailsTitleAr,
    this.detailsTitleEn,
    this.sortOrder = 0,
  });

  final String id;
  final String? parentId;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String? icon;

  /// Sections only: the traits its items show (raw JSON list).
  final List<Object?>? traitSchema;

  /// Sections only: the kind of details its items carry; null when it has
  /// none or the kind is newer than this app.
  final DetailKind? detailKind;

  /// Sections only: what the details are called here, e.g. «طريقة
  /// التحضير», «الحكاية»; null → the app's name for the kind.
  final String? detailsTitleAr;
  final String? detailsTitleEn;
  final int sortOrder;

  String? detailsTitle({required bool arabic}) =>
      arabic ? detailsTitleAr : detailsTitleEn;

  bool get isSection => parentId == null;
}

enum TermLang { ar, en, franco }

enum TermKind { name, ingredient, description }

/// An extra search word for an item.
@immutable
class ItemTerm {
  const new({required this.term, required this.lang, required this.kind});

  final String term;
  final TermLang lang;
  final TermKind kind;

  @override
  bool operator ==(Object other) =>
      other is ItemTerm &&
      other.term == term &&
      other.lang == lang &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(term, lang, kind);
}

/// One item of any section (a drink, a term, a moment in history): its
/// name as people see it, the Arabic name, «يعني …», a plain explanation,
/// and the one kind of [details] its section adds.
class CatalogItem {
  const new({
    required this.id,
    required this.categoryId,
    required this.slug,
    required this.menuName,
    required this.menuNameAr,
    required this.explanationAr,
    required this.explanationEn,
    this.gistAr,
    this.gistEn,
    this.imagePath,
    this.audioSpokenPath,
    this.audioOriginalPath,
    this.traits = const {},
    this.sortOrder = 0,
    this.terms = const [],
    this.details,
  });

  final String id;
  final String categoryId;
  final String slug;

  /// Exactly as menus print it (usually Latin), e.g. `Flat White`.
  final String menuName;

  /// The Arabic spelling, e.g. `فلات وايت`.
  final String menuNameAr;
  final String explanationAr;
  final String explanationEn;

  /// The «يعني» line: what it is in everyday words, e.g.
  /// `قهوة باللبن والتلج في الخلاط`.
  final String? gistAr;
  final String? gistEn;
  final String? imagePath;

  /// The name as people say it («زي ما بتتقال»; for drinks, the barista).
  final String? audioSpokenPath;
  final String? audioOriginalPath;

  /// Values for the section's traits, e.g. `{temp: hot, calories: 110}`.
  final Map<String, Object?> traits;
  final int sortOrder;
  final List<ItemTerm> terms;

  /// The section's kind of details; null when not written yet.
  final ItemDetails? details;

  /// Drinks: «طريقة التحضير», when written.
  Recipe? get recipe => switch (details) {
    RecipeDetails(:final recipe) => recipe,
    _ => null,
  };

  /// Approximate calories (drinks; a trait since they're section-specific).
  int? get calories => _intTrait('calories', 0, 3000);

  /// The cup, in ml (drinks).
  int? get sizeMl => _intTrait('size_ml', 1, 3000);

  /// A whole number in range, else null (content never breaks the item).
  int? _intTrait(String key, int min, int max) {
    final value = switch (traits[key]) {
      final int v => v,
      final double v when v.isFinite && v == v.roundToDouble() => v.toInt(),
      _ => null,
    };
    return value != null && value >= min && value <= max ? value : null;
  }

  /// The «يعني» line in one language; without one, the explanation's first
  /// sentence (cards keep it to two lines).
  String gist({required bool arabic}) {
    final gist = arabic ? gistAr : gistEn;
    if (gist != null) return gist;
    final explanation = arabic ? explanationAr : explanationEn;
    final end = explanation.indexOf(RegExp('[.!?؟]'));
    return end < 0 ? explanation : explanation.substring(0, end);
  }
}

/// How far the first download got.
@immutable
class SyncProgress {
  const new({required this.saved, required this.total});

  final int saved;
  final int total;

  /// 0…1; 0 while the total is unknown.
  double get fraction => total <= 0 ? 0 : (saved / total).clamp(0, 1);

  @override
  bool operator ==(Object other) =>
      other is SyncProgress && other.saved == saved && other.total == total;

  @override
  int get hashCode => Object.hash(saved, total);
}

/// What one sync changed.
class SyncReport {
  const new({
    required this.changed,
    required this.removed,
    required this.skipped,
    required this.firstSync,
  });

  /// Items added or updated.
  final int changed;

  /// Items and categories hidden or deleted on the server.
  final int removed;

  /// Rows that arrived in an unexpected shape and were ignored.
  final int skipped;
  final bool firstSync;
}
