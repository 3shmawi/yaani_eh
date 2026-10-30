import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// The facts a details screen shows about one drink, in one language.
class ItemFacts {
  const new({
    required this.traits,
    required this.priceIsStale,
    this.calories,
    this.priceMin,
    this.priceMax,
    this.priceCheckedAt,
  });

  /// Trait pills, already in the reader's language ("سخن", "فيه لبن"…).
  final List<String> traits;
  final int? calories;
  final int? priceMin;
  final int? priceMax;
  final DateTime? priceCheckedAt;

  /// Checked more than [DescribeItem.staleAfter] ago (or never dated).
  final bool priceIsStale;

  bool get hasPrice => priceMin != null;
}

/// Turns an item and its section's `trait_schema` into display facts.
/// The schema is content: a new section (desserts…) brings its own traits
/// and labels, with no code change. Unknown trait types are skipped.
class DescribeItem {
  const new();

  static const staleAfter = Duration(days: 90);

  ItemFacts call({
    required CatalogItem item,
    required List<Object?>? traitSchema,
    required String lang,
    required DateTime now,
  }) {
    final traits = <String>[];
    for (final entry in traitSchema ?? const <Object?>[]) {
      if (entry is! Map) continue;
      final label = _label(entry, item.traits[entry['key']], lang);
      if (label != null && label.isNotEmpty) traits.add(label);
    }
    final checked = item.priceUpdatedAt;
    final min = item.priceMinEgp;
    return ItemFacts(
      traits: traits,
      calories: item.calories,
      priceMin: min,
      priceMax: item.priceMaxEgp ?? min,
      priceCheckedAt: checked,
      priceIsStale:
          min != null &&
          (checked == null || now.difference(checked) > staleAfter),
    );
  }

  static String? _label(
    Map<dynamic, dynamic> trait,
    Object? value,
    String lang,
  ) {
    if (value == null) return null;
    switch (trait['type']) {
      case 'enum':
        final options = trait['options'];
        if (options is! List) return null;
        for (final o in options) {
          if (o is Map && o['value'] == value) return _text(o[lang]);
        }
        return null;
      case 'scale':
        final labels = trait['labels'];
        final list = labels is Map ? labels[lang] : null;
        if (value is! int || list is! List || value < 0) return null;
        return value < list.length ? _text(list[value]) : null;
      case 'bool':
        final labels = trait['labels'];
        final list = labels is Map ? labels[lang] : null;
        if (value is! bool || list is! List || list.length < 2) return null;
        return _text(list[value ? 1 : 0]);
      default:
        return null;
    }
  }

  static String? _text(Object? value) =>
      value is String && value.length <= 40 ? value : null;
}

/// Drinks like this one: same category first, then the closest taste
/// (temperature, sweetness, milk, caffeine), never the drink itself.
class SimilarItems {
  const new();

  List<CatalogItem> call(
    CatalogItem item,
    List<CatalogItem> all, {
    int max = 6,
  }) {
    double distance(CatalogItem other) {
      var d = other.categoryId == item.categoryId ? 0.0 : 3.0;
      final a = item.traits;
      final b = other.traits;
      if (a['temp'] != b['temp'] &&
          a['temp'] != 'both' &&
          b['temp'] != 'both') {
        d += 1.5;
      }
      if (a['milk'] != b['milk']) d += 1;
      for (final key in const ['sweetness', 'caffeine']) {
        final x = a[key];
        final y = b[key];
        if (x is int && y is int) d += (x - y).abs() * 0.5;
      }
      return d;
    }

    final others =
        [
          for (final other in all)
            if (other.id != item.id) other,
        ]..sort((x, y) {
          final byDistance = distance(x).compareTo(distance(y));
          return byDistance != 0
              ? byDistance
              : x.sortOrder.compareTo(y.sortOrder);
        });
    return others.take(max).toList();
  }
}
