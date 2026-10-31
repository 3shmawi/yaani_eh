import 'package:meta/meta.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/recipe.dart';

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
    this.sortOrder = 0,
  });

  final String id;
  final String? parentId;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String? icon;

  /// Sections only: the traits the taste quiz asks about (raw JSON list).
  final List<Object?>? traitSchema;
  final int sortOrder;

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

/// One drink (later: dish or dessert), as menus print it plus a plain
/// explanation. Calories and prices are approximate.
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
    this.calories,
    this.sizeMl,
    this.priceMinEgp,
    this.priceMaxEgp,
    this.priceUpdatedAt,
    this.imagePath,
    this.audioBaristaPath,
    this.audioOriginalPath,
    this.traits = const {},
    this.sortOrder = 0,
    this.terms = const [],
    this.recipe,
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
  final int? calories;
  final int? sizeMl;
  final int? priceMinEgp;
  final int? priceMaxEgp;
  final DateTime? priceUpdatedAt;
  final String? imagePath;
  final String? audioBaristaPath;
  final String? audioOriginalPath;

  /// Values for the section's traits, e.g. `{temp: hot, sweetness: 0}`.
  final Map<String, Object?> traits;
  final int sortOrder;
  final List<ItemTerm> terms;

  /// «طريقة التحضير»; null when it hasn't been written yet.
  final Recipe? recipe;

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
