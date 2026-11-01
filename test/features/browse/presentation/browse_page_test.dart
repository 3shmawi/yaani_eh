import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/browse_page.dart';
import 'package:yaani_eh/features/browse/presentation/browse_view.dart';
import 'package:yaani_eh/features/browse/presentation/widgets/section_card.dart';
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

/// Two more sections from the backend, so the grid has something to lay out.
const _terms = CatalogCategory(
  id: '00000000-0000-4000-8000-0000000c0010',
  slug: 'terms',
  nameAr: 'مصطلحات',
  nameEn: 'Terms',
  icon: 'book',
  sortOrder: 2,
);
const _history = CatalogCategory(
  id: '00000000-0000-4000-8000-0000000c0011',
  slug: 'history',
  nameAr: 'تاريخ',
  nameEn: 'History',
  icon: 'history',
  sortOrder: 3,
);

HubModel _hub({List<CatalogItem>? items, bool more = false}) =>
    const BuildHub()(
      items: items ?? sampleCatalogItems(),
      categories: [
        ..._categories,
        if (more) ...[_terms, _history],
      ],
      today: _day,
    );

void main() {
  group(BrowseView, () {
    Future<void> pumpView(
      WidgetTester tester, {
      HubModel? hub,
      Locale locale = const Locale('en'),
      ThemeMode mode = ThemeMode.light,
      ValueChanged<HubSection>? onOpen,
      VoidCallback? onSearch,
    }) => tester.pumpApp(
      BrowseView(
        hub: hub,
        onOpenSection: onOpen ?? (_) {},
        onOpenSearch: onSearch ?? () {},
      ),
      locale: locale,
      themeMode: mode,
    );

    testWidgets('a short band with search, then a card per section', (
      tester,
    ) async {
      await pumpView(tester, hub: _hub());
      expect(find.text(l10nEn.appEyebrow), findsOneWidget);
      expect(find.byKey(const Key('home_search')), findsOneWidget);
      // Search is the band's one action: no settings button, no switch.
      expect(find.byKey(const Key('home_settings_button')), findsNothing);
      expect(find.byKey(const Key('browse_sections')), findsNothing);
      expect(find.byKey(const Key('item_of_the_day')), findsOneWidget);
      expect(find.text(l10nEn.hubSectionsTitle), findsOneWidget);
      expect(find.byType(SectionCard), findsNWidgets(2));
      expect(find.text('Drinks'), findsOneWidget);
      expect(find.text(l10nEn.sectionItemCount(12)), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('an empty section says «coming soon» and still opens', (
      tester,
    ) async {
      final opened = <String>[];
      await pumpView(
        tester,
        hub: _hub(),
        onOpen: (s) => opened.add(s.section.slug),
      );
      final desserts = find.byKey(const Key('section_desserts'));
      await tester.ensureVisible(desserts);
      expect(
        find.descendant(
          of: desserts,
          matching: find.text(l10nEn.comingSoonBadge),
        ),
        findsOneWidget,
      );
      await tester.tap(desserts);
      await tester.tap(find.byKey(const Key('section_cafe')));
      expect(opened, ['desserts', 'cafe']);
    });

    testWidgets('the whole card takes the tap, padding included', (
      tester,
    ) async {
      final opened = <String>[];
      await pumpView(
        tester,
        hub: _hub(),
        onOpen: (s) => opened.add(s.section.slug),
      );
      final card = find.byKey(const Key('section_cafe'));
      // Just inside the top-start corner: no text or icon there.
      await tester.tapAt(tester.getTopRight(card) + const Offset(-3, 3));
      await tester.tapAt(tester.getBottomLeft(card) + const Offset(3, -3));
      expect(opened, ['cafe', 'cafe']);
    });

    testWidgets('a card reads as one button: name and count', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpView(tester, hub: _hub());
      expect(
        find.bySemanticsLabel(
          l10nEn.sectionCardLabel('Drinks', l10nEn.sectionItemCount(12)),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          l10nEn.sectionCardLabel('Desserts', l10nEn.comingSoonBadge),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('search opens; it stays pinned on top when scrolled', (
      tester,
    ) async {
      var searches = 0;
      await pumpView(tester, hub: _hub(more: true), onSearch: () => searches++);
      await tester.tap(find.byKey(const Key('home_search')));
      expect(searches, 1);

      final list = find.byKey(const Key('home_list'));
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
      final pinned = find.byKey(const Key('home_search_pinned'));
      expect(pinned, findsOneWidget);
      await tester.tap(
        find.descendant(of: pinned, matching: find.byType(SearchField)),
      );
      expect(searches, 2);

      await tester.drag(list, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(pinned, findsNothing);
    });

    testWidgets('loading, and no sections at all', (tester) async {
      await pumpView(tester);
      expect(find.bySemanticsLabel(l10nEn.loading), findsOneWidget);

      await pumpView(
        tester,
        hub: const BuildHub()(
          items: const [],
          categories: const [],
          today: _day,
        ),
      );
      expect(find.text(l10nEn.browseEmpty), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('nothing published yet: every section is coming soon', (
      tester,
    ) async {
      await pumpView(tester, hub: _hub(items: const []));
      expect(find.byKey(const Key('item_of_the_day')), findsNothing);
      expect(find.byKey(const Key('section_soon_badge')), findsNWidgets(2));
    });

    for (final (name, locale, mode) in [
      ('Arabic', const Locale('ar'), ThemeMode.light),
      ('dark', const Locale('en'), ThemeMode.dark),
      ('Arabic dark', const Locale('ar'), ThemeMode.dark),
    ]) {
      testWidgets('works in $name', (tester) async {
        await pumpView(
          tester,
          hub: _hub(more: true),
          locale: locale,
          mode: mode,
        );
        expect(tester.takeException(), isNull);
        await tester.expectAccessible();
      });
    }

    testWidgets('Arabic: names in Arabic, RTL, «جاي قريب»', (tester) async {
      await pumpView(tester, hub: _hub(), locale: const Locale('ar'));
      expect(find.text('مشروبات'), findsOneWidget);
      expect(find.text('جاي قريب'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('مشروبات'))),
        TextDirection.rtl,
      );
      // The card's picture is at the start: the right edge in Arabic.
      final card = find.byKey(const Key('section_cafe'));
      expect(
        tester.getCenter(find.text('مشروبات')).dx,
        lessThan(tester.getCenter(card).dx + tester.getSize(card).width / 2),
      );
    });

    testWidgets('small phone with 1.6× text: no overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpView(tester, hub: _hub(more: true), locale: const Locale('ar'));
      tester.view.physicalSize = const Size(960, 1704); // 320×568
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Cards stack in one column on a phone.
      final cafe = tester.getTopLeft(find.byKey(const Key('section_cafe')));
      final desserts = tester.getTopLeft(
        find.byKey(const Key('section_desserts')),
      );
      expect(desserts.dy, greaterThan(cafe.dy));
      await tester.expectAccessible();
    });

    for (final (name, size, columns) in [
      ('iPad portrait', const Size(1032, 1376), 2),
      ('iPad landscape', const Size(1376, 1032), 3),
    ]) {
      testWidgets('$name: $columns columns, search at a readable width', (
        tester,
      ) async {
        await pumpView(tester, hub: _hub(more: true));
        tester.view
          ..physicalSize = size * 2
          ..devicePixelRatio = 2;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final tops = {
          for (final slug in ['cafe', 'desserts', 'terms'])
            tester.getTopLeft(find.byKey(Key('section_$slug'))).dy,
        };
        // Cards in one row share a top: 2 columns → 2 rows for 3 cards.
        expect(tops, hasLength(columns == 2 ? 2 : 1));
        expect(
          tester.getSize(find.byKey(const Key('home_search'))).width,
          lessThanOrEqualTo(AppDimens.readableWidth),
        );
      });
    }
  });

  group(BrowsePage, () {
    testWidgets('reads the sections from the device', (tester) async {
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
      await tester.pumpAndSettle();
      expect(find.byType(SectionCard), findsNWidgets(2));
      expect(find.text(l10nEn.sectionItemCount(12)), findsOneWidget);
    });
  });
}
