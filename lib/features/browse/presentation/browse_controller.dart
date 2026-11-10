import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';

/// A section tab on Home was tapped. Slug only, no personal data.
void trackSectionOpened(HubSection section) => unawaited(
  Analytics.capture('browse_section_opened', {
    'section': section.section.slug,
    'coming_soon': !section.hasItems,
  }),
);

/// A category chip was tapped (the list scrolls to it). Slug only, no
/// personal data.
void trackCategoryJump(CatalogCategory category) => unawaited(
  Analytics.capture('browse_category_selected', {'category': category.slug}),
);

/// Overridable clock, so "item of the day" is testable.
final todayProvider = Provider<DateTime>((ref) => Dependencies.clock());

/// Home's section tabs, rebuilt whenever the catalog syncs. Null while
/// the device copy is still loading.
final hubProvider = Provider<HubModel?>((ref) {
  final items = ref.watch(catalogItemsProvider).value;
  final categories = ref.watch(catalogCategoriesProvider).value;
  if (items == null || categories == null) return null;
  return const BuildHub()(items: items, categories: categories);
});

/// The section tab picked on Home, by slug; null until one is tapped.
final homePickedSectionProvider = NotifierProvider<HomePickedSection, String?>(
  HomePickedSection.new,
);

class HomePickedSection extends Notifier<String?> {
  @override
  String? build() => null;

  void pick(String slug) {
    if (state != slug) state = slug;
  }
}

/// The section Home shows: the one picked, else the first with items, else
/// the first. Null while loading, or when the catalog has no sections.
final homeSectionSlugProvider = Provider<String?>((ref) {
  final hub = ref.watch(hubProvider);
  if (hub == null) return null;
  final picked = ref.watch(homePickedSectionProvider);
  if (picked != null && hub.sections.any((s) => s.section.slug == picked)) {
    return picked;
  }
  final first =
      hub.sections.where((s) => s.hasItems).firstOrNull ??
      hub.sections.firstOrNull;
  return first?.section.slug;
});

/// What a section page shows, by the section's slug.
sealed class SectionState {
  const new();
}

/// The device copy is still loading.
final class SectionLoading extends SectionState {
  const new();
}

/// No section has that slug (an old or crafted link).
final class SectionMissing extends SectionState {
  const new();
}

/// The catalog has no sections at all (Home only).
final class SectionNone extends SectionState {
  const new();
}

final class SectionReady extends SectionState {
  const new(this.model);

  final BrowseModel model;
}

final ProviderFamily<SectionState, String> sectionProvider =
    Provider.family<SectionState, String>((ref, slug) {
      final items = ref.watch(catalogItemsProvider).value;
      final categories = ref.watch(catalogCategoriesProvider).value;
      if (items == null || categories == null) return const SectionLoading();
      final model = const BuildBrowse()(
        slug: slug,
        items: items,
        categories: categories,
        today: ref.watch(todayProvider),
      );
      return model == null ? const SectionMissing() : SectionReady(model);
    });
