import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/widgets/item_card.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/browse_page.dart';
import 'package:yaani_eh/features/browse/presentation/widgets/section_tabs.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';

import '../../../helpers/fake_catalog_remote.dart';
import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/pump_app.dart';

final _day = DateTime(2026, 10, 30);
final List<CatalogCategory> _categories = [
  for (final r in sampleCategories()) CatalogRows.category(r)!,
];

/// [n] more sections from the backend after Drinks and Desserts.
List<CatalogCategory> _sections(int n) => [
  ..._categories,
  for (var i = 0; i < n; i++)
    CatalogCategory(
      id: fakeId(3000 + i),
      slug: 'extra_$i',
      nameAr: 'قسم $i',
      nameEn: 'Section $i',
      icon: 'book',
      sortOrder: 2 + i,
    ),
];

HubModel _hub({int more = 0}) =>
    const BuildHub()(items: sampleCatalogItems(), categories: _sections(more));

Future<void> _pumpHome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  ThemeMode mode = ThemeMode.light,
  List<CatalogItem>? items,
}) async {
  await tester.pumpApp(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(has: true, items: items),
        ),
        todayProvider.overrideWithValue(_day),
      ],
      child: const BrowsePage(),
    ),
    locale: locale,
    themeMode: mode,
  );
  await tester.pumpAndSettle();
}

Finder _tab(String label) => find.descendant(
  of: find.byKey(const Key('section_tabs')),
  matching: find.text(label),
);

void main() {
  group(SectionTabs, () {
    Future<void> pumpTabs(
      WidgetTester tester, {
      required HubModel hub,
      String? selected,
      ValueChanged<HubSection>? onSelected,
      Locale locale = const Locale('en'),
    }) => tester.pumpApp(
      SectionTabs(
        sections: hub.sections,
        selectedSlug: selected,
        onSelected: onSelected ?? (_) {},
      ),
      locale: locale,
    );

    testWidgets('a tab per section, the picked one selected', (tester) async {
      await pumpTabs(tester, hub: _hub(), selected: 'cafe');
      expect(find.text('Drinks'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Drinks')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(find.text('Desserts')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
    });

    testWidgets('tapping a tab reports its section, coming soon included', (
      tester,
    ) async {
      final picked = <String>[];
      await pumpTabs(
        tester,
        hub: _hub(),
        selected: 'cafe',
        onSelected: (s) => picked.add(s.section.slug),
      );
      await tester.tap(find.text('Desserts'));
      await tester.tap(find.text('Drinks'));
      expect(picked, ['desserts', 'cafe']);
    });

    testWidgets('eight sections scroll sideways, the last one is reachable', (
      tester,
    ) async {
      final picked = <String>[];
      await pumpTabs(
        tester,
        hub: _hub(more: 6),
        selected: 'cafe',
        onSelected: (s) => picked.add(s.section.slug),
      );
      expect(tester.takeException(), isNull);
      // Past the screen's edge: not even built until the row is dragged.
      expect(find.text('Section 5'), findsNothing);
      await tester.dragUntilVisible(
        find.text('Section 5'),
        find.byType(ListView),
        const Offset(-120, 0),
      );
      // Dragged on, clear of the screen's edge.
      await tester.drag(find.byType(ListView), const Offset(-100, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Section 5'));
      expect(picked, ['extra_5']);
    });

    testWidgets('Arabic: names in Arabic, the first tab at the right', (
      tester,
    ) async {
      await pumpTabs(
        tester,
        hub: _hub(),
        selected: 'cafe',
        locale: const Locale('ar'),
      );
      expect(find.text('مشروبات'), findsOneWidget);
      expect(find.text('حلويات'), findsOneWidget);
      expect(
        tester.getCenter(find.text('مشروبات')).dx,
        greaterThan(tester.getCenter(find.text('حلويات')).dx),
      );
    });
  });

  group(BrowsePage, () {
    testWidgets('loading, then the first section with items', (tester) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(has: true),
            ),
            todayProvider.overrideWithValue(_day),
          ],
          child: const BrowsePage(),
        ),
      );
      expect(find.bySemanticsLabel(l10nEn.loading), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(l10nEn.loading), findsNothing);
    });

    testWidgets('the band, the section tabs, then that section’s items', (
      tester,
    ) async {
      await _pumpHome(tester);
      expect(find.text(l10nEn.appEyebrow), findsOneWidget);
      expect(find.byKey(const Key('home_search')), findsOneWidget);
      // Both sections have a tab; Drinks (the first with items) is picked.
      expect(_tab('Drinks'), findsOneWidget);
      expect(_tab('Desserts'), findsOneWidget);
      expect(
        tester.getSemantics(_tab('Drinks')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      // The body is the section’s: item of the day, its chips and cards.
      expect(find.byKey(const Key('item_of_the_day')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('category_chips')),
          matching: find.text('Coffee'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ItemCard), findsWidgets);
      // Home has no back button.
      expect(find.byKey(const Key('section_back')), findsNothing);
      await tester.expectAccessible();
    });

    testWidgets('a coming-soon tab says so, and Drinks brings the items back', (
      tester,
    ) async {
      await _pumpHome(tester);
      await tester.tap(_tab('Desserts'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
      expect(find.byType(ItemCard), findsNothing);
      expect(find.byKey(const Key('item_of_the_day')), findsNothing);
      expect(find.byKey(const Key('section_back')), findsNothing);
      // The tabs stay, so there is always a way out.
      expect(_tab('Drinks'), findsOneWidget);
      expect(
        tester.getSemantics(_tab('Desserts')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      await tester.expectAccessible();

      await tester.tap(_tab('Drinks'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browse_coming_soon')), findsNothing);
      expect(find.byType(ItemCard), findsWidgets);
    });

    testWidgets('picking another section starts it again at the top', (
      tester,
    ) async {
      await _pumpHome(tester);
      final list = find.byKey(const Key('browse_list'));
      await tester.drag(list, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsOneWidget);

      // The tabs scrolled away with the band: scroll up to reach them.
      await tester.drag(list, const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tester.tap(_tab('Desserts'));
      await tester.pumpAndSettle();
      await tester.tap(_tab('Drinks'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsNothing);
      expect(find.byKey(const Key('item_of_the_day')), findsOneWidget);
    });

    testWidgets('a chip still scrolls to its category on Home', (tester) async {
      await _pumpHome(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('category_chips')),
          matching: find.text('Iced coffee'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsOneWidget);
      expect(find.byKey(const Key('section_back_pinned')), findsNothing);
      expect(find.byKey(const Key('section_search_pinned')), findsOneWidget);
    });

    testWidgets('nothing published yet: every section is coming soon', (
      tester,
    ) async {
      await _pumpHome(tester, items: const []);
      expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
      expect(find.byKey(const Key('item_of_the_day')), findsNothing);
      expect(_tab('Drinks'), findsOneWidget);
      expect(_tab('Desserts'), findsOneWidget);
    });

    for (final (name, locale, mode) in [
      ('Arabic', const Locale('ar'), ThemeMode.light),
      ('dark', const Locale('en'), ThemeMode.dark),
      ('Arabic dark', const Locale('ar'), ThemeMode.dark),
    ]) {
      testWidgets('works in $name', (tester) async {
        await _pumpHome(tester, locale: locale, mode: mode);
        expect(tester.takeException(), isNull);
        await tester.expectAccessible();
      });
    }

    testWidgets('Arabic: names in Arabic, RTL', (tester) async {
      await _pumpHome(tester, locale: const Locale('ar'));
      expect(_tab('مشروبات'), findsOneWidget);
      expect(_tab('حلويات'), findsOneWidget);
      expect(
        Directionality.of(tester.element(_tab('مشروبات'))),
        TextDirection.rtl,
      );
    });

    testWidgets('small phone with 1.6× text: no overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpHome(tester, locale: const Locale('ar'));
      tester.view.physicalSize = const Size(960, 1704); // 320×568
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.expectAccessible();
    });

    for (final (name, size) in [
      ('iPad portrait', const Size(1032, 1376)),
      ('iPad landscape', const Size(1376, 1032)),
    ]) {
      testWidgets('$name: no overflow, tabs and cards in view', (tester) async {
        await _pumpHome(tester);
        tester.view
          ..physicalSize = size * 2
          ..devicePixelRatio = 2;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_tab('Drinks'), findsOneWidget);
        expect(find.byType(ItemCard), findsWidgets);
      });
    }
  });
}
