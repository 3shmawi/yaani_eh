import 'dart:convert';

import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// Turns server rows (JSON maps from Supabase) into entities.
///
/// The server already validates content, but the app never trusts it: a
/// row with a missing field, a wrong type or an absurd value is rejected
/// (returns null) and the sync skips it instead of crashing.
abstract final class CatalogRows {
  static final _slug = RegExp(r'^[a-z0-9_]{1,60}$');

  static CatalogCategory? category(Object? row) {
    if (row is! Map) return null;
    final id = _id(row['id']);
    final slug = _text(row['slug'], 60);
    final nameAr = _text(row['name_ar'], 60);
    final nameEn = _text(row['name_en'], 60);
    if (id == null || slug == null || !_slug.hasMatch(slug)) return null;
    if (nameAr == null || nameEn == null) return null;
    final parent = row['parent_id'];
    if (parent != null && _id(parent) == null) return null;
    final schema = row['trait_schema'];
    if (schema != null && schema is! List) return null;
    return CatalogCategory(
      id: id,
      parentId: parent == null ? null : _id(parent),
      slug: slug,
      nameAr: nameAr,
      nameEn: nameEn,
      icon: _text(row['icon'], 40),
      traitSchema: schema == null ? null : List<Object?>.of(schema as List),
      sortOrder: _int(row['sort_order']) ?? 0,
    );
  }

  static CatalogItem? item(Object? row) {
    if (row is! Map) return null;
    final id = _id(row['id']);
    final categoryId = _id(row['category_id']);
    final slug = _text(row['slug'], 60);
    final menuName = _text(row['menu_name'], 80);
    final menuNameAr = _text(row['menu_name_ar'], 80);
    final explanationAr = _text(row['explanation_ar'], 300);
    final explanationEn = _text(row['explanation_en'], 300);
    if (id == null || categoryId == null) return null;
    if (slug == null || !_slug.hasMatch(slug)) return null;
    if (menuName == null || menuNameAr == null) return null;
    if (explanationAr == null || explanationEn == null) return null;

    final calories = _optionalInt(row, 'calories', 0, 3000);
    final sizeMl = _optionalInt(row, 'size_ml', 1, 3000);
    final priceMin = _optionalInt(row, 'price_min_egp', 0, 100000);
    final priceMax = _optionalInt(row, 'price_max_egp', 0, 100000);
    if ([calories, sizeMl, priceMin, priceMax].contains(_invalid)) return null;
    if (priceMin != null && priceMax != null && priceMax < priceMin) {
      return null;
    }
    final traits = row['traits'];
    if (traits != null && traits is! Map) return null;

    return CatalogItem(
      id: id,
      categoryId: categoryId,
      slug: slug,
      menuName: menuName,
      menuNameAr: menuNameAr,
      explanationAr: explanationAr,
      explanationEn: explanationEn,
      gistAr: _text(row['gist_ar'], 60),
      gistEn: _text(row['gist_en'], 60),
      calories: calories,
      sizeMl: sizeMl,
      priceMinEgp: priceMin,
      priceMaxEgp: priceMax,
      priceUpdatedAt: _date(row['price_updated_at']),
      imagePath: _path(row['image_path']),
      audioBaristaPath: _path(row['audio_barista_path']),
      audioOriginalPath: _path(row['audio_original_path']),
      traits: traits == null
          ? const {}
          : {
              for (final e in (traits as Map).entries)
                if (e.key is String) e.key as String: e.value,
            },
      sortOrder: _int(row['sort_order']) ?? 0,
      // A broken recipe hides «طريقة التحضير», never the drink.
      recipe: recipe(row['recipe']),
    );
  }

  /// «طريقة التحضير» from `items.recipe`, or null when it's missing or
  /// anything in it is off (the sheet would draw it wrong).
  static Recipe? recipe(Object? value) {
    if (value is! Map) return null;
    final minutes = _int(value['minutes']);
    final layers = value['layers'];
    final steps = value['steps'];
    if (minutes == null || minutes < 1 || minutes > 1440) return null;
    if (layers is! List || layers.isEmpty || layers.length > 6) return null;
    if (steps is! List || steps.isEmpty || steps.length > 8) return null;
    final parsedLayers = <RecipeLayer>[];
    for (final l in layers) {
      if (l is! Map) return null;
      final ml = _int(l['ml']);
      final ar = _text(l['ar'], 40);
      final en = _text(l['en'], 40);
      if (ml == null || ml < 1 || ml > 3000 || ar == null || en == null) {
        return null;
      }
      parsedLayers.add(
        RecipeLayer(
          tone: RecipeTone.parse(l['tone']),
          ml: ml,
          nameAr: ar,
          nameEn: en,
        ),
      );
    }
    final parsedSteps = <RecipeStep>[];
    for (final s in steps) {
      if (s is! Map) return null;
      final titleAr = _text(s['title_ar'], 60);
      final titleEn = _text(s['title_en'], 60);
      if (titleAr == null || titleEn == null) return null;
      parsedSteps.add(
        RecipeStep(
          icon: RecipeIcon.parse(s['icon']),
          titleAr: titleAr,
          titleEn: titleEn,
          noteAr: _text(s['note_ar'], 160),
          noteEn: _text(s['note_en'], 160),
          amountAr: _text(s['amount_ar'], 40),
          amountEn: _text(s['amount_en'], 40),
        ),
      );
    }
    return Recipe(minutes: minutes, layers: parsedLayers, steps: parsedSteps);
  }

  /// A recipe in the server's shape, for local storage ([recipe] reads it
  /// back).
  static Map<String, Object?> recipeJson(Recipe recipe) => {
    'minutes': recipe.minutes,
    'layers': [
      for (final l in recipe.layers)
        {
          'tone': _snakeName(l.tone.name),
          'ml': l.ml,
          'ar': l.nameAr,
          'en': l.nameEn,
        },
    ],
    'steps': [
      for (final s in recipe.steps)
        {
          'icon': _snakeName(s.icon.name),
          'title_ar': s.titleAr,
          'title_en': s.titleEn,
          'note_ar': ?s.noteAr,
          'note_en': ?s.noteEn,
          'amount_ar': ?s.amountAr,
          'amount_en': ?s.amountEn,
        },
    ],
  };

  static String _snakeName(String camel) =>
      camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  /// A search term with the id of its item, or null.
  static (String itemId, ItemTerm term)? term(Object? row) {
    if (row is! Map) return null;
    final itemId = _id(row['item_id']);
    final term = _text(row['term'], 60);
    final lang = TermLang.values.asNameMap()[row['lang']];
    final kind = TermKind.values.asNameMap()[row['kind'] ?? 'name'];
    if (itemId == null || term == null || lang == null || kind == null) {
      return null;
    }
    return (itemId, ItemTerm(term: term, lang: lang, kind: kind));
  }

  /// A removed category or item from `catalog_removed_since`.
  static ({String kind, String id})? removed(Object? row) {
    if (row is! Map) return null;
    final kind = row['kind'];
    final id = _id(row['id']);
    if ((kind != 'category' && kind != 'item') || id == null) return null;
    return (kind: kind as String, id: id);
  }

  /// The row's `updated_at`, for the sync cursor.
  static DateTime? updatedAt(Object? row) =>
      row is Map ? _timestamp(row['updated_at']) : null;

  /// Encodes traits / trait schemas for local storage.
  static String encode(Object? value) => jsonEncode(value);

  static Object? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  static const int _invalid = -1 << 40;

  static final _uuid = RegExp(
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String? _id(Object? value) =>
      value is String && _uuid.hasMatch(value) ? value.toLowerCase() : null;

  static String? _text(Object? value, int max) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty || text.length > max ? null : text;
  }

  static String? _path(Object? value) {
    final path = _text(value, 300);
    if (path == null || path.contains('..') || path.startsWith('/')) {
      return null;
    }
    return path;
  }

  static int? _int(Object? value) => switch (value) {
    final int v => v,
    final double v when v == v.roundToDouble() && v.isFinite => v.toInt(),
    _ => null,
  };

  /// null when absent, [_invalid] when present but wrong.
  static int? _optionalInt(
    Map<dynamic, dynamic> row,
    String key,
    int min,
    int max,
  ) {
    final value = row[key];
    if (value == null) return null;
    final number = _int(value);
    if (number == null || number < min || number > max) return _invalid;
    return number;
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static DateTime? _timestamp(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
