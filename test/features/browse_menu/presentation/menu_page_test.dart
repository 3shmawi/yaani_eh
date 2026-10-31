import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/features/browse_menu/domain/usecases/build_menu.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_controller.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_page.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_view.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/play_name_button.dart';

import '../../../helpers/fake_catalog_remote.dart';
import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_pronunciation.dart';
import '../../../helpers/pump_app.dart';

final _day = DateTime(2026, 10, 30);
final List<CatalogCategory> _categories = [
  for (final r in sampleCategories()) CatalogRows.category(r)!,
];

MenuModel _menu({String? selected, List<CatalogItem>? items}) =>
    const BuildMenu()(
      items: items ?? sampleCatalogItems(),
      categories: _categories,
      today: _day,
      selectedCategoryId: selected,
    );

void main() {
  group(MenuView, () {
    Future<void> pumpView(
      WidgetTester tester, {
      MenuModel? menu,
      Locale locale = const Locale('en'),
      ThemeMode mode = ThemeMode.light,
      void Function(CatalogCategory?)? onSelect,
      VoidCallback? onSettings,
    }) => tester.pumpApp(
      MenuView(
        menu: menu,
        onSelectCategory: onSelect ?? (_) {},
        onOpenSettings: onSettings ?? () {},
      ),
      locale: locale,
      themeMode: mode,
    );

    testWidgets('header, chips, drink of the day and glass cards', (
      tester,
    ) async {
      await pumpView(tester, menu: _menu());
      expect(find.text(l10nEn.menuTitle), findsOneWidget);
      expect(find.text(l10nEn.chipAll), findsOneWidget);
      expect(find.text('Coffee'), findsWidgets); // chip + section
      expect(find.byKey(const Key('drink_of_the_day')), findsOneWidget);
      expect(find.text(l10nEn.drinkOfTheDay), findsOneWidget);
      expect(find.byType(DrinkCard), findsWidgets);
      await tester.expectAccessible();
    });

    testWidgets('chips and "see all" select a category', (tester) async {
      final picked = <String?>[];
      await pumpView(
        tester,
        menu: _menu(),
        onSelect: (c) => picked.add(c?.slug),
      );

      await tester.tap(find.text('Iced coffee').first);
      await tester.tap(find.text(l10nEn.seeAll).first);
      await tester.tap(find.text(l10nEn.chipAll));
      expect(picked, ['iced_coffee', 'coffee', null]);
    });

    testWidgets('a selected category shows only its drinks', (tester) async {
      await pumpView(tester, menu: _menu(selected: coldId));
      expect(find.byKey(const Key('drink_of_the_day')), findsNothing);
      expect(find.text(l10nEn.seeAll), findsNothing);
      expect(find.text('Cold Brew'), findsOneWidget);
      expect(find.text('Espresso'), findsNothing);
      await tester.expectAccessible();
    });

    testWidgets('loading and empty states', (tester) async {
      await pumpView(tester);
      expect(find.bySemanticsLabel(l10nEn.loading), findsOneWidget);

      await pumpView(tester, menu: _menu(items: const []));
      expect(find.text(l10nEn.menuEmpty), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('settings stays one tap away', (tester) async {
      var opened = 0;
      await pumpView(tester, menu: _menu(), onSettings: () => opened++);
      await tester.tap(find.byKey(const Key('home_settings_button')));
      expect(opened, 1);
    });

    for (final (name, locale, mode) in [
      ('Arabic', const Locale('ar'), ThemeMode.light),
      ('dark', const Locale('en'), ThemeMode.dark),
      ('Arabic dark', const Locale('ar'), ThemeMode.dark),
    ]) {
      testWidgets('works in $name', (tester) async {
        await pumpView(tester, menu: _menu(), locale: locale, mode: mode);
        expect(tester.takeException(), isNull);
        await tester.expectAccessible();
      });
    }

    testWidgets('Arabic: categories and explanations in Arabic, RTL', (
      tester,
    ) async {
      await pumpView(tester, menu: _menu(), locale: const Locale('ar'));
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('قهوة'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.text('الكل'))),
        TextDirection.rtl,
      );
    });

    testWidgets('the first cards rise in one after another, then rest', (
      tester,
    ) async {
      await pumpView(tester, menu: _menu());
      final reveals = find.byType(AppReveal);
      double opacity(int i) => tester
          .widget<Opacity>(
            find.descendant(of: reveals.at(i), matching: find.byType(Opacity)),
          )
          .opacity;
      // The first card leads, the second follows…
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(0), greaterThan(opacity(1)));
      // …then every card rests fully shown, and nothing keeps animating.
      await tester.pumpAndSettle();
      expect(opacity(0), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(opacity(1), 1);
    });

    testWidgets('Reduce Motion: cards show at once', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpView(tester, menu: _menu());
      expect(
        find.descendant(
          of: find.byType(AppReveal),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('small phone with large text, and a tablet', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpView(tester, menu: _menu(), locale: const Locale('ar'));
      tester.view.physicalSize = const Size(960, 1704); // 320×568
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(2048, 2732); // iPad
      tester.view.devicePixelRatio = 2;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group(DrinkCard, () {
    Future<void> pumpCard(
      WidgetTester tester,
      CatalogItem item, {
      Locale locale = const Locale('en'),
    }) => tester.pumpApp(
      Center(
        child: SizedBox(width: 170, child: DrinkCard(item: item)),
      ),
      locale: locale,
    );

    testWidgets('name, spelling and the «يعني» line, in Arabic', (
      tester,
    ) async {
      await pumpCard(
        tester,
        sampleCatalogItems().first,
        locale: const Locale('ar'),
      );
      expect(find.text('Espresso'), findsOneWidget);
      expect(find.text('إسبريسو'), findsOneWidget);
      expect(find.text('يعني فنجان قهوة صغير ومركّز'), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('English shows the meaning alone', (tester) async {
      await pumpCard(tester, sampleCatalogItems().first);
      expect(find.text('A tiny, strong cup of coffee'), findsOneWidget);
    });

    testWidgets('no «يعني» line yet: the first sentence of the explanation', (
      tester,
    ) async {
      final latte = sampleCatalogItems().firstWhere((i) => i.gistAr == null);
      await pumpCard(tester, latte, locale: const Locale('ar'));
      final sentence = latte.explanationAr.split('.').first;
      expect(find.text('يعني $sentence'), findsOneWidget);
    });

    testWidgets('no price or calories on the card', (tester) async {
      final item = CatalogRows.item({
        ...sampleItems().first,
        'price_min_egp': 70,
        'price_max_egp': 150,
      })!;
      await pumpCard(tester, item, locale: const Locale('ar'));
      expect(find.textContaining('ج.م'), findsNothing);
      expect(find.textContaining('سعر حراري'), findsNothing);
    });

    testWidgets('cards in a row line up: the meaning takes two lines', (
      tester,
    ) async {
      final items = sampleCatalogItems();
      await tester.pumpApp(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Two real «يعني» lines: one line long, two lines long.
            for (final item in items.where((i) => i.gistEn != null))
              SizedBox(width: 170, child: DrinkCard(item: item)),
          ],
        ),
      );
      final heights = [
        for (final card in find.byType(DrinkCard).evaluate())
          tester.getSize(find.byWidget(card.widget)).height,
      ];
      expect(heights.toSet(), hasLength(1));
    });

    testWidgets('a long «يعني» line shows whole: small phone, large text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final long = '${'ق' * 20} ${'ب' * 20} ${'ن' * 18}'; // 60 chars
      final item = CatalogRows.item({...sampleItems().first, 'gist_ar': long})!;
      await tester.pumpApp(
        Center(
          child: SizedBox(width: 138, child: DrinkCard(item: item)),
        ),
        locale: const Locale('ar'),
      );
      tester.view.physicalSize = const Size(960, 1704); // 320×568
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text('يعني $long'));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('pressing shrinks the card, still with Reduce Motion', (
      tester,
    ) async {
      Future<double> pressedScale() async {
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(DrinkCard)),
        );
        await tester.pumpAndSettle();
        final scale = tester
            .widget<AnimatedScale>(
              find.descendant(
                of: find.byType(DrinkCard),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale;
        await gesture.up();
        await tester.pumpAndSettle();
        return scale;
      }

      final item = sampleCatalogItems().first;
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 170,
            child: DrinkCard(item: item, onTap: () {}),
          ),
        ),
      );
      expect(await pressedScale(), lessThan(1));

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      expect(await pressedScale(), 1);
    });

    testWidgets('one label for screen readers, tappable when wired', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 170,
            child: DrinkCard(
              item: sampleCatalogItems().first,
              onTap: () => opened++,
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('^Espresso، إسبريسو')),
        findsOneWidget,
      );
      await tester.tap(find.byType(DrinkCard));
      expect(opened, 1);
      handle.dispose();
    });
  });

  group(MenuPage, () {
    testWidgets('reads the menu from the device and filters by chip', (
      tester,
    ) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(has: true),
            ),
            todayProvider.overrideWithValue(_day),
          ],
          child: const MenuPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Flat White'), findsWidgets);

      await tester.tap(find.text('Iced coffee').first);
      await tester.pumpAndSettle();
      expect(find.text('Flat White'), findsNothing);
      expect(find.text('Cold Brew'), findsWidgets);
    });

    testWidgets('drinks with clips get a play button on their card and the '
        'drink of the day; it plays without opening the drink', (tester) async {
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
            todayProvider.overrideWithValue(_day),
            ...pronunciationOverrides(repo, player),
          ],
          child: const MenuPage(),
        ),
      );
      await tester.pumpAndSettle();
      final today = find.byKey(const Key('drink_of_the_day'));
      expect(
        find.descendant(of: today, matching: find.byType(PlayNameButton)),
        findsOneWidget,
      );
      // Affogato and Iced Mocha have no clips.
      expect(find.byKey(const Key('play_affogato')), findsNothing);

      final card = find.widgetWithText(DrinkCard, 'Flat White');
      await tester.dragUntilVisible(
        card,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      final play = find.descendant(
        of: card,
        matching: find.byKey(const Key('play_flat_white')),
      );
      // Top-start corner of the card (the heart will take top-end).
      expect(
        tester.getTopLeft(play).dx - tester.getTopLeft(card).dx,
        lessThan(10),
      );
      await tester.tap(play);
      await tester.pump();
      expect(player.played.single.file, '/clips/flat_white.barista.m4a');
      // Still on Home.
      expect(find.byType(MenuView), findsOneWidget);
      player.finish();
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });
  });
}
