import 'package:flutter/material.dart';
import 'package:yaani_eh/core/widgets/category_chips.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';

/// Home's sections as a row of tabs that scrolls sideways, so any number of
/// sections fit (docs/decisions/0006-home-section-tabs.md). A section is
/// data from the backend: a new one is a new tab with no code change, and
/// one without items yet still has its tab (it says «جاي قريب»).
class SectionTabs extends StatelessWidget {
  const new({
    required this.sections,
    required this.selectedSlug,
    required this.onSelected,
    super.key,
  });

  final List<HubSection> sections;
  final String? selectedSlug;
  final ValueChanged<HubSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return CategoryChips(
      options: [
        for (final s in sections)
          (
            id: s.section.slug,
            label: arabic ? s.section.nameAr : s.section.nameEn,
          ),
      ],
      selectedId: selectedSlug,
      onSelected: (slug) =>
          onSelected(sections.firstWhere((s) => s.section.slug == slug)),
    );
  }
}
