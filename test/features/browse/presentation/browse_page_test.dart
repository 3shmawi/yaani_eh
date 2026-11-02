import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/widgets/item_card.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/browse_page.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/pump_app.dart';

final _day = DateTime(2026, 10, 30);

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
      // One row with the section tabs: the categories are further along it.
      final iced = find.descendant(
        of: find.byKey(const Key('category_chips')),
        matching: find.text('Iced coffee'),
      );
      await tester.dragUntilVisible(
        iced,
        find.byKey(const Key('category_chips')),
        const Offset(-120, 0),
      );
      await tester.ensureVisible(iced);
      await tester.pumpAndSettle();
      await tester.tap(iced);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsOneWidget);
      expect(find.byKey(const Key('section_back_pinned')), findsNothing);
      expect(find.byKey(const Key('section_search_pinned')), findsOneWidget);
    });

    testWidgets('the categories are a row of their own, under the band', (
      tester,
    ) async {
      await _pumpHome(tester);
      final chips = find.byKey(const Key('category_chips'));
      // Not inside the sections row, and below it.
      expect(
        find.descendant(
          of: find.byKey(const Key('section_tabs')),
          matching: find.text('Coffee'),
        ),
        findsNothing,
      );
      expect(
        tester.getTopLeft(chips).dy,
        greaterThan(
          tester.getBottomLeft(find.byKey(const Key('section_tabs'))).dy,
        ),
      );
      // «All» first, then the section's categories.
      expect(
        find.descendant(of: chips, matching: find.text(l10nEn.chipAll)),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(
              find.descendant(of: chips, matching: find.text(l10nEn.chipAll)),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      // On the page, not on the band: outlined chips.
      expect(
        find.descendant(
          of: find.byKey(const Key('home_header')),
          matching: find.text('Coffee'),
        ),
        findsNothing,
      );
    });

    testWidgets('«All» takes the list back to the top', (tester) async {
      await _pumpHome(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('category_chips')),
          matching: find.text('Iced coffee'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('category_chips_pinned')),
          matching: find.text(l10nEn.chipAll),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsNothing);
      expect(find.byKey(const Key('item_of_the_day')), findsOneWidget);
    });

    testWidgets('the grid button lists every section; picking one opens it', (
      tester,
    ) async {
      await _pumpHome(tester);
      await tester.tap(find.byKey(const Key('all_sections')));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.allSections), findsOneWidget);
      expect(find.byKey(const Key('sections_cafe')), findsOneWidget);
      expect(find.byKey(const Key('sections_desserts')), findsOneWidget);
      await tester.expectAccessible();

      await tester.tap(find.byKey(const Key('sections_desserts')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sections_cafe')), findsNothing);
      expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
      expect(
        tester.getSemantics(_tab('Desserts')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
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
