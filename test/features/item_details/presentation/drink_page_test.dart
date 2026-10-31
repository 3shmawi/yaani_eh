import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_controller.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_controller.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_page.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_view.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/pronounce_pill.dart';

import '../../../helpers/fake_catalog_remote.dart';
import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_pronunciation.dart';
import '../../../helpers/pump_app.dart';

final _now = DateTime(2026, 10, 30);

CatalogItem _flatWhite({
  int? min = 70,
  int? max = 150,
  String? checked = '2026-10-01',
}) => CatalogRows.item({
  ...sampleItems()[2],
  'price_min_egp': min,
  'price_max_egp': max,
  'price_updated_at': checked,
  'traits': {'temp': 'hot', 'sweetness': 0, 'milk': true, 'caffeine': 3},
})!;

void main() {
  group(DrinkView, () {
    Future<void> pumpView(
      WidgetTester tester, {
      CatalogItem? item,
      Locale locale = const Locale('en'),
      ThemeMode mode = ThemeMode.light,
      VoidCallback? onBack,
      ValueChanged<CatalogItem>? onOpen,
    }) {
      final drink = item ?? _flatWhite();
      return tester.pumpApp(
        DrinkView(
          item: drink,
          facts: const DescribeItem()(
            item: drink,
            traitSchema: cafeTraitSchema,
            lang: locale.languageCode,
            now: _now,
          ),
          similar: sampleCatalogItems()
              .where((i) => i.slug != 'flat_white')
              .take(4)
              .toList(),
          onBack: onBack ?? () {},
          onOpenDrink: onOpen ?? (_) {},
        ),
        locale: locale,
        themeMode: mode,
      );
    }

    testWidgets('name, explanation, pills, price and similar drinks', (
      tester,
    ) async {
      await pumpView(tester);
      expect(find.text('Flat White'), findsOneWidget);
      expect(find.text('فلات وايت'), findsOneWidget);
      expect(
        find.text(
          'A double espresso with a little silky milk. Stronger than a latte.',
        ),
        findsOneWidget,
      );
      expect(find.text('Hot'), findsOneWidget);
      expect(find.text('With milk'), findsOneWidget);
      expect(find.text(l10nEn.priceAtCafes), findsOneWidget);
      expect(find.text(l10nEn.priceChecked('October 2026')), findsOneWidget);
      expect(find.text(l10nEn.priceStale), findsNothing);
      expect(find.text(l10nEn.similarDrinks), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('Arabic explanation and labels', (tester) async {
      await pumpView(tester, locale: const Locale('ar'));
      expect(
        find.text('إسبريسو دوبل بلبن ناعم قليل. أقوى من اللاتيه.'),
        findsOneWidget,
      );
      expect(find.text('سخن'), findsOneWidget);
      expect(find.text('بلبن'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('Flat White'))),
        TextDirection.rtl,
      );
      await tester.expectAccessible();
    });

    testWidgets('an old price gets a warning in words', (tester) async {
      await pumpView(tester, item: _flatWhite(checked: '2026-05-01'));
      expect(find.text(l10nEn.priceStale), findsOneWidget);
    });

    testWidgets('no price yet says so', (tester) async {
      await pumpView(tester, item: _flatWhite(min: null, max: null));
      expect(find.text(l10nEn.priceMissing), findsOneWidget);
      expect(find.text(l10nEn.priceAtCafes), findsNothing);
    });

    testWidgets('back and similar drinks are tappable', (tester) async {
      var back = 0;
      final opened = <String>[];
      await pumpView(
        tester,
        onBack: () => back++,
        onOpen: (i) => opened.add(i.slug),
      );
      await tester.tap(find.byKey(const Key('drink_back')));
      expect(back, 1);
      await tester.ensureVisible(find.byType(DrinkCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DrinkCard).first);
      expect(opened, hasLength(1));
    });

    for (final (name, locale, mode) in [
      ('dark', const Locale('en'), ThemeMode.dark),
      ('Arabic dark', const Locale('ar'), ThemeMode.dark),
    ]) {
      testWidgets('works in $name', (tester) async {
        await pumpView(tester, locale: locale, mode: mode);
        expect(tester.takeException(), isNull);
        await tester.expectAccessible();
      });
    }

    testWidgets('small phone with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpView(tester, locale: const Locale('ar'));
      tester.view.physicalSize = const Size(960, 1704);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group(DrinkPage, () {
    Future<void> pumpPage(WidgetTester tester, String slug) => tester.pumpApp(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(has: true),
          ),
          todayProvider.overrideWithValue(_now),
        ],
        child: DrinkPage(slug: slug),
      ),
    );

    testWidgets('shows a drink from the device copy', (tester) async {
      await pumpPage(tester, 'cortado');
      await tester.pumpAndSettle();
      expect(find.byType(DrinkView), findsOneWidget);
      expect(find.text('Cortado'), findsWidgets);
    });

    testWidgets('a drink with clips: the pronounce pill on the photo, clips '
        'prefetched, a tap plays', (tester) async {
      final repo = FakePronunciationRepository();
      final player = FakeClipPlayer();
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(
                has: true,
                items: sampleCatalogItems(withAudio: true),
              ),
            ),
            todayProvider.overrideWithValue(_now),
            ...pronunciationOverrides(repo, player),
          ],
          child: const DrinkPage(slug: 'flat_white'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PronouncePill), findsOneWidget);
      expect(repo.prefetched, [
        'flat_white.barista.m4a',
        'flat_white.original.m4a',
      ]);
      // On the photo, above the sheet with the name.
      expect(
        tester.getBottomLeft(find.byType(PronouncePill)).dy,
        lessThan(tester.getTopLeft(find.text('Flat White').last).dy),
      );

      await tester.tap(find.byKey(const Key('pronounce_barista')));
      await tester.pump();
      expect(player.played.single.file, '/clips/flat_white.barista.m4a');
      player.finish();
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });

    testWidgets("«how it's made» opens the recipe sheet", (tester) async {
      await pumpPage(tester, 'flat_white');
      await tester.pumpAndSettle();
      final row = find.byKey(const Key('drink_recipe'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(find.text("How it's made · 180 ml"), findsOneWidget);
      await tester.expectAccessible();

      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe_view')), findsOneWidget);
    });

    testWidgets("no recipe yet, no «how it's made»", (tester) async {
      await pumpPage(tester, 'cortado');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drink_recipe')), findsNothing);
    });

    testWidgets('a drink without clips has no pill', (tester) async {
      await pumpPage(tester, 'cortado');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pronounce_barista')), findsNothing);
    });

    testWidgets('an unknown drink shows a friendly message', (tester) async {
      await pumpPage(tester, 'unicorn_latte');
      await tester.pumpAndSettle();
      expect(find.byType(DrinkMissingView), findsOneWidget);
      expect(find.text(l10nEn.drinkNotFoundTitle), findsOneWidget);
      await tester.expectAccessible();
    });

    test('details walk up to the section for the trait schema', () async {
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(has: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
        ..listen(catalogItemsProvider, (_, _) {})
        ..listen(catalogCategoriesProvider, (_, _) {});
      await container.read(catalogItemsProvider.future);
      await container.read(catalogCategoriesProvider.future);
      final details = container.read(drinkDetailsProvider('latte'));
      expect(details, isA<DrinkFound>());
      expect((details as DrinkFound).traitSchema, cafeTraitSchema);
      expect(details.similar, isNotEmpty);
    });
  });
}
