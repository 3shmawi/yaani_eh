import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show NotifierProviderFamily, ProviderFamily;
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/smart_search/domain/usecases/search_menu.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/repositories/taste_repository.dart';
import 'package:yaani_eh/features/taste_profile/domain/usecases/match_taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/usecases/taste_questions.dart';

/// Override in tests: `tasteRepositoryProvider.overrideWithValue(fake)`.
final tasteRepositoryProvider = Provider<TasteRepository>(
  (ref) => Dependencies.tasteRepository,
);

/// The sections (root categories) by slug.
final _sectionsProvider = Provider<Map<String, CatalogCategory>>((ref) {
  final categories = ref.watch(catalogCategoriesProvider).value ?? const [];
  return {
    for (final c in categories)
      if (c.isSection) c.slug: c,
  };
});

/// The first section that has taste questions (the drinks), for `/taste`
/// without a section.
final defaultTasteSectionProvider = Provider<String?>((ref) {
  final sections = ref.watch(_sectionsProvider).values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return sections
      .where((s) => const TasteQuestions()(s.traitSchema).isNotEmpty)
      .firstOrNull
      ?.slug;
});

/// The questions of «ذوقي» for a section; empty when it has none.
final ProviderFamily<List<TasteQuestion>, String> tasteQuestionsProvider =
    Provider.family<List<TasteQuestion>, String>(
      (ref, section) => const TasteQuestions()(
        ref.watch(_sectionsProvider)[section]?.traitSchema,
      ),
    );

/// Someone's taste for a section, null until the quiz is taken there.
final NotifierProviderFamily<TasteNotifier, TasteProfile?, String>
tasteProvider = NotifierProvider.family<TasteNotifier, TasteProfile?, String>(
  TasteNotifier.new,
);

class TasteNotifier extends Notifier<TasteProfile?> {
  new(this.section);

  final String section;

  @override
  TasteProfile? build() => ref.watch(tasteRepositoryProvider).load(section);

  /// Saves the quiz's answers; false when the phone couldn't store them.
  Future<bool> save(TasteProfile profile) async {
    final result = await ref
        .read(tasteRepositoryProvider)
        .save(section, profile);
    if (result is Failed) return false;
    state = profile;
    unawaited(
      Analytics.capture('taste_quiz_completed', {
        'section': section,
        'answered': profile.answers.length,
      }),
    );
    return true;
  }
}

/// The section a drink is in (walks up from its category).
CatalogCategory? sectionOf(
  CatalogItem item,
  Map<String, CatalogCategory> byId,
) {
  var category = byId[item.categoryId];
  for (
    var hops = 0;
    category != null && !category.isSection && hops < 4;
    hops++
  ) {
    category = byId[category.parentId];
  }
  return category;
}

/// The drinks of a section that fit its taste best, best first; empty
/// until the quiz is taken.
final ProviderFamily<List<TasteMatch>, String> tasteMatchesProvider =
    Provider.family<List<TasteMatch>, String>((ref, section) {
      final profile = ref.watch(tasteProvider(section));
      final questions = ref.watch(tasteQuestionsProvider(section));
      if (profile == null || questions.isEmpty) return const [];
      final items = ref.watch(catalogItemsProvider).value ?? const [];
      final categories = ref.watch(catalogCategoriesProvider).value ?? const [];
      final byId = {for (final c in categories) c.id: c};
      return const MatchTaste().rank(
        [
          for (final i in items)
            if (sectionOf(i, byId)?.slug == section) i,
        ],
        profile,
        questions,
      );
    });

/// Search ranks drinks close to someone's taste higher: up to +50% for a
/// perfect fit, nothing before the quiz.
final tasteBoostsProvider = Provider<SearchBoosts>((ref) {
  final categories = ref.watch(catalogCategoriesProvider).value ?? const [];
  final byId = {for (final c in categories) c.id: c};
  final cache = <String, (TasteProfile?, List<TasteQuestion>)>{};
  for (final s in categories.where((c) => c.isSection)) {
    cache[s.id] = (
      ref.watch(tasteProvider(s.slug)),
      ref.watch(tasteQuestionsProvider(s.slug)),
    );
  }
  if (cache.values.every((v) => v.$1 == null)) return const NoBoosts();
  return _TasteBoosts(byId, cache);
});

class _TasteBoosts implements SearchBoosts {
  const new(this._byId, this._taste);

  final Map<String, CatalogCategory> _byId;
  final Map<String, (TasteProfile?, List<TasteQuestion>)> _taste;

  static const _weight = 0.5;

  @override
  double boost(CatalogItem item) {
    final section = sectionOf(item, _byId);
    final (profile, questions) =
        _taste[section?.id] ?? (null, const <TasteQuestion>[]);
    if (profile == null || profile.isEmpty) return 0;
    return _weight * const MatchTaste().score(item, profile, questions).score;
  }
}
