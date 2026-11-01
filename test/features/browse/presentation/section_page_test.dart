import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/item_card.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/section_page.dart';
import 'package:yaani_eh/features/browse/presentation/section_view.dart';
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

SectionState _menu({String slug = 'cafe', List<CatalogItem>? items}) =>
    SectionReady(
      const BuildBrowse()(
        slug: slug,
        items: items ?? sampleCatalogItems(),
        categories: _categories,
        today: _day,
      )!,
    );

void main() {
  group(SectionView, () {
    Future<void> pumpView(
      WidgetTester tester, {
      SectionState menu = const SectionLoading(),
      Locale locale = const Locale('en'),
      ThemeMode mode = ThemeMode.light,
      ValueChanged<CatalogCategory>? onJump,
      VoidCallback? onBack,
      VoidCallback? onSearch,
    }) => tester.pumpApp(
      SectionView(
        state: menu,
        onBack: onBack ?? () {},
        onJumpToCategory: onJump,
        onOpenSearch: onSearch ?? () {},
      ),
      locale: locale,
      themeMode: mode,
    );

    testWidgets('header, chips, drink of the day and cards', (tester) async {
      await pumpView(tester, menu: _menu());
      // The section's name and count, back and search; no other sections.
      expect(find.text('Drinks'), findsOneWidget);
      expect(find.text(l10nEn.sectionItemCount(12)), findsOneWidget);
      expect(find.byKey(const Key('section_back')), findsOneWidget);
      expect(find.byKey(const Key('section_search')), findsOneWidget);
      expect(find.textContaining('Desserts'), findsNothing);
      expect(find.text('All'), findsNothing);
      expect(find.text('Coffee'), findsWidgets); // chip + section
      expect(find.byKey(const Key('item_of_the_day')), findsOneWidget);
      expect(find.byType(ItemCard), findsWidgets);
      await tester.expectAccessible();
    });

    testWidgets('every category of the section is on the list', (tester) async {
      await pumpView(tester, menu: _menu());
      final list = find.byKey(const Key('browse_list'));
      await tester.dragUntilVisible(
        find.text('Cold Brew'),
        list,
        const Offset(0, -300),
      );
      expect(find.text('Cold Brew'), findsOneWidget);
    });

    testWidgets('a chip scrolls to its category and lights up', (tester) async {
      final jumped = <String>[];
      await pumpView(tester, menu: _menu(), onJump: (c) => jumped.add(c.slug));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('category_chips')),
          matching: find.text('Iced coffee'),
        ),
      );
      await tester.pumpAndSettle();
      expect(jumped, ['iced_coffee']);
      // The band scrolled away: the chips are pinned at the top, with
      // «Iced coffee» selected, and its heading sits just under them.
      final pinned = find.byKey(const Key('category_chips_pinned'));
      expect(pinned, findsOneWidget);
      // Back and search stay in the pinned bar.
      final bar = find.byKey(const Key('section_pinned'));
      expect(
        find.descendant(of: bar, matching: find.byType(AppIconButton)),
        findsNWidgets(2),
      );
      final selected = tester.getSemantics(
        find.descendant(of: pinned, matching: find.text('Iced coffee')),
      );
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      final heading = find.descendant(
        of: find.byKey(const Key('browse_list')),
        matching: find.text('Iced coffee'),
      );
      expect(
        tester.getTopLeft(heading.last).dy,
        greaterThan(tester.getBottomLeft(pinned).dy - 1),
      );
    });

    testWidgets('scrolling back up hides the pinned chips', (tester) async {
      await pumpView(tester, menu: _menu());
      final list = find.byKey(const Key('browse_list'));
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsOneWidget);
      await tester.drag(list, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_chips_pinned')), findsNothing);
    });

    testWidgets('a section without items is coming soon; back returns', (
      tester,
    ) async {
      var backs = 0;
      await pumpView(
        tester,
        menu: _menu(slug: 'desserts'),
        onBack: () => backs++,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
      expect(find.text(l10nEn.comingSoonTitle('Desserts')), findsOneWidget);
      expect(find.byType(ItemCard), findsNothing);
      expect(find.byKey(const Key('category_chips')), findsNothing);
      await tester.expectAccessible();

      await tester.tap(find.text(l10nEn.comingSoonAction));
      expect(backs, 1);
    });

    testWidgets('an unknown section says so and leads home', (tester) async {
      var backs = 0;
      await pumpView(
        tester,
        menu: const SectionMissing(),
        onBack: () => backs++,
      );
      expect(find.byKey(const Key('section_missing')), findsOneWidget);
      expect(find.text(l10nEn.sectionMissingTitle), findsOneWidget);
      await tester.expectAccessible();
      await tester.tap(find.text(l10nEn.notFoundGoHome));
      expect(backs, 1);
    });

    testWidgets('loading, and a section emptied by a sync', (tester) async {
      await pumpView(tester);
      expect(find.bySemanticsLabel(l10nEn.loading), findsOneWidget);

      await pumpView(tester, menu: _menu(items: const []));
      expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('back and search are one tap away', (tester) async {
      var backs = 0;
      var searches = 0;
      await pumpView(
        tester,
        menu: _menu(),
        onBack: () => backs++,
        onSearch: () => searches++,
      );
      await tester.tap(find.byKey(const Key('section_back')));
      await tester.tap(find.byKey(const Key('section_search')));
      expect((backs, searches), (1, 1));
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
      expect(find.text('مشروبات'), findsOneWidget);
      expect(find.text('قهوة'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.text('مشروبات'))),
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

    testWidgets('pulled down past the top, the band stretches, no gap', (
      tester,
    ) async {
      await pumpView(tester, menu: _menu());
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      final fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(HeaderOverscroll),
          matching: find.byWidgetPredicate(
            (w) => w is ColoredBox && w.color == AppColors.headerTop,
          ),
        ),
      );
      expect(tester.getSize(find.byWidget(fill)).height, greaterThan(0));
      await gesture.up();
      await tester.pumpAndSettle();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a chip ticks like an iOS picker, once', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add('${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpView(tester, menu: _menu());
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('category_chips')),
          matching: find.text('Iced coffee'),
        ),
      );
      await tester.pumpAndSettle();
      expect(haptics, ['HapticFeedbackType.selectionClick']);
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

  group(ItemCard, () {
    Future<void> pumpCard(
      WidgetTester tester,
      CatalogItem item, {
      Locale locale = const Locale('en'),
    }) => tester.pumpApp(
      Center(
        child: SizedBox(width: 170, child: ItemCard(item: item)),
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
              SizedBox(width: 170, child: ItemCard(item: item)),
          ],
        ),
      );
      final heights = [
        for (final card in find.byType(ItemCard).evaluate())
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
          child: SizedBox(width: 138, child: ItemCard(item: item)),
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
          tester.getCenter(find.byType(ItemCard)),
        );
        await tester.pumpAndSettle();
        final scale = tester
            .widget<AnimatedScale>(
              find.descendant(
                of: find.byType(ItemCard),
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
            child: ItemCard(item: item, onTap: () {}),
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
            child: ItemCard(
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
      await tester.tap(find.byType(ItemCard));
      expect(opened, 1);
      handle.dispose();
    });
  });

  group(SectionPage, () {
    Widget page(String slug) => ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(has: true),
        ),
        todayProvider.overrideWithValue(_day),
      ],
      child: SectionPage(slug: slug),
    );

    testWidgets('reads its section from the device, by slug', (tester) async {
      await tester.pumpApp(page('cafe'));
      await tester.pumpAndSettle();
      expect(find.text('Flat White'), findsWidgets);

      await tester.pumpApp(page('desserts'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
      expect(find.text('Flat White'), findsNothing);

      await tester.pumpApp(page('no_such_section'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('section_missing')), findsOneWidget);
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
          child: const SectionPage(slug: 'cafe'),
        ),
      );
      await tester.pumpAndSettle();
      final today = find.byKey(const Key('item_of_the_day'));
      expect(
        find.descendant(of: today, matching: find.byType(PlayNameButton)),
        findsOneWidget,
      );
      // Affogato and Iced Mocha have no clips.
      expect(find.byKey(const Key('play_affogato')), findsNothing);

      final card = find.widgetWithText(ItemCard, 'Flat White');
      await tester.dragUntilVisible(
        card,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      // Clear of the chips pinned at the top.
      await tester.drag(
        find.byKey(const Key('browse_list')),
        const Offset(0, 250),
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
      // Still on the section.
      expect(find.byType(SectionView), findsOneWidget);
      player.finish();
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });
  });
}
