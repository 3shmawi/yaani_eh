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
      detailKind: parent == null ? DetailKind.parse(row['detail_kind']) : null,
      detailsTitleAr: parent == null
          ? _text(row['details_title_ar'], 40)
          : null,
      detailsTitleEn: parent == null
          ? _text(row['details_title_en'], 40)
          : null,
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
      imagePath: _path(row['image_path']),
      audioSpokenPath: _path(row['audio_spoken_path']),
      audioOriginalPath: _path(row['audio_original_path']),
      traits: traits == null
          ? const {}
          : {
              for (final e in (traits as Map).entries)
                if (e.key is String) e.key as String: e.value,
            },
      sortOrder: _int(row['sort_order']) ?? 0,
      // Broken details hide the details, never the item.
      details: details(row['details']),
    );
  }

  /// An item's details from `items.details` (`{kind, …}`), or null when
  /// missing or anything in it is off. A kind this app doesn't know is
  /// [UnknownDetails], so the page can ask for an update.
  static ItemDetails? details(Object? value) {
    if (value is! Map) return null;
    final kind = value['kind'];
    if (kind is! String || !_kind.hasMatch(kind)) return null;
    switch (DetailKind.parse(kind)) {
      case DetailKind.recipe:
        final parsed = recipe(value);
        return parsed == null ? null : RecipeDetails(parsed);
      case DetailKind.story:
        final steps = _steps(value['steps'], icons: false);
        final sections = _sections(value['sections'], optional: true);
        if (steps == null || steps.isEmpty || sections == null) return null;
        return StoryDetails(steps: steps, sections: sections);
      case DetailKind.usage:
        final sections = _sections(value['sections']);
        if (sections == null || sections.isEmpty) return null;
        return UsageDetails(sections: sections);
      case null:
        return UnknownDetails(kind);
    }
  }

  static final _kind = RegExp(r'^[a-z_]{1,20}$');

  /// Steps in order (at most 12), or null when anything is off.
  static List<DetailStep>? _steps(Object? value, {required bool icons}) {
    if (value is! List || value.length > 12) return null;
    final steps = <DetailStep>[];
    for (final s in value) {
      if (s is! Map) return null;
      final titleAr = _text(s['title_ar'], 60);
      final titleEn = _text(s['title_en'], 60);
      if (titleAr == null || titleEn == null) return null;
      steps.add(
        DetailStep(
          icon: icons || s['icon'] != null ? StepIcon.parse(s['icon']) : null,
          titleAr: titleAr,
          titleEn: titleEn,
          noteAr: _text(s['note_ar'], 160),
          noteEn: _text(s['note_en'], 160),
          amountAr: _text(s['amount_ar'], 40),
          amountEn: _text(s['amount_en'], 40),
          dateAr: _text(s['date_ar'], 40),
          dateEn: _text(s['date_en'], 40),
        ),
      );
    }
    return steps;
  }

  /// Titled sections (at most 6, each 1–8 lines), or null when anything is
  /// off. [optional]: a missing list is an empty one.
  static List<DetailSection>? _sections(
    Object? value, {
    bool optional = false,
  }) {
    if (value == null && optional) return const [];
    if (value is! List || value.length > 6) return null;
    final sections = <DetailSection>[];
    for (final s in value) {
      if (s is! Map) return null;
      final titleAr = _text(s['title_ar'], 40);
      final titleEn = _text(s['title_en'], 40);
      final linesAr = _lines(s['lines_ar']);
      final linesEn = _lines(s['lines_en']);
      if (titleAr == null || titleEn == null) return null;
      if (linesAr == null || linesEn == null) return null;
      sections.add(
        DetailSection(
          titleAr: titleAr,
          titleEn: titleEn,
          linesAr: linesAr,
          linesEn: linesEn,
        ),
      );
    }
    return sections;
  }

  static List<String>? _lines(Object? value) {
    if (value is! List || value.isEmpty || value.length > 8) return null;
    final lines = <String>[];
    for (final l in value) {
      final line = _text(l, 200);
      if (line == null) return null;
      lines.add(line);
    }
    return lines;
  }

  /// Details in the server's shape, for local storage ([details] reads it
  /// back). Unknown details keep only their kind: the page asks for an
  /// update, and the next sync after it brings the rest.
  static Map<String, Object?> detailsJson(ItemDetails details) =>
      switch (details) {
        RecipeDetails(:final recipe) => {
          'kind': 'recipe',
          ...recipeJson(recipe),
        },
        StoryDetails(:final steps, :final sections) => {
          'kind': 'story',
          'steps': [for (final s in steps) _stepJson(s)],
          'sections': [for (final s in sections) _sectionJson(s)],
        },
        UsageDetails(:final sections) => {
          'kind': 'usage',
          'sections': [for (final s in sections) _sectionJson(s)],
        },
        UnknownDetails(:final kind) => {'kind': kind},
      };

  static Map<String, Object?> _stepJson(DetailStep s) => {
    if (s.icon case final icon?) 'icon': snakeCase(icon.name),
    'title_ar': s.titleAr,
    'title_en': s.titleEn,
    'note_ar': ?s.noteAr,
    'note_en': ?s.noteEn,
    'amount_ar': ?s.amountAr,
    'amount_en': ?s.amountEn,
    'date_ar': ?s.dateAr,
    'date_en': ?s.dateEn,
  };

  static Map<String, Object?> _sectionJson(DetailSection s) => {
    'title_ar': s.titleAr,
    'title_en': s.titleEn,
    'lines_ar': s.linesAr,
    'lines_en': s.linesEn,
  };

  /// «طريقة التحضير» from a recipe's details, or null when it's missing or
  /// anything in it is off (the sheet would draw it wrong).
  static Recipe? recipe(Object? value) {
    if (value is! Map) return null;
    final minutes = _int(value['minutes']);
    final layers = value['layers'];
    final steps = value['steps'];
    if (minutes == null || minutes < 1 || minutes > 1440) return null;
    if (layers is! List || layers.isEmpty || layers.length > 6) return null;
    if (steps is! List || steps.isEmpty || steps.length > 8) return null;
    final parsedSteps = _steps(steps, icons: true);
    if (parsedSteps == null) return null;
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
    return Recipe(minutes: minutes, layers: parsedLayers, steps: parsedSteps);
  }

  /// A recipe in the server's shape, for local storage ([recipe] reads it
  /// back).
  static Map<String, Object?> recipeJson(Recipe recipe) => {
    'minutes': recipe.minutes,
    'layers': [
      for (final l in recipe.layers)
        {
          'tone': snakeCase(l.tone.name),
          'ml': l.ml,
          'ar': l.nameAr,
          'en': l.nameEn,
        },
    ],
    'steps': [for (final s in recipe.steps) _stepJson(s)],
  };

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

  static DateTime? _timestamp(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
