import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_controller.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_page.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_view.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_welcome.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('view', () {
    late List<(WelcomeExit, int)> exits;

    Future<void> pumpView(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) {
      exits = [];
      return tester.pumpApp(
        WelcomeView(onExit: (exit, page) => exits.add((exit, page))),
        locale: locale,
      );
    }

    testWidgets('«التالي» walks the three pages; the last offers both ways', (
      tester,
    ) async {
      await pumpView(tester);
      expect(find.text(l10nEn.welcomeMenuTitle), findsOneWidget);
      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
      await tester.expectAccessible();

      await tester.tap(find.byKey(const Key('welcome_next')));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.welcomeHearTitle), findsOneWidget);
      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('welcome_next')));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.welcomeTasteTitle), findsOneWidget);
      expect(find.byKey(const Key('welcome_next')), findsNothing);
      expect(find.byKey(const Key('welcome_skip')), findsNothing);
      await tester.expectAccessible();

      await tester.tap(find.byKey(const Key('welcome_taste')));
      await tester.tap(find.byKey(const Key('welcome_menu')));
      expect(exits, [(WelcomeExit.taste, 3), (WelcomeExit.menu, 3)]);
    });

    testWidgets('swiping moves between pages', (tester) async {
      await pumpView(tester);
      await tester.fling(find.byType(PageView), const Offset(-200, 0), 800);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.welcomeHearTitle), findsOneWidget);
    });

    testWidgets('«تخطّي» leaves from the page it is on', (tester) async {
      await pumpView(tester);
      await tester.tap(find.byKey(const Key('welcome_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('welcome_skip')));
      expect(exits, [(WelcomeExit.skip, 2)]);
    });

    testWidgets('Arabic swipes the other way (RTL)', (tester) async {
      await pumpView(tester, locale: const Locale('ar'));
      expect(find.text('منيو الكافيه… بس مفهوم'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(200, 0), 800);
      await tester.pumpAndSettle();
      expect(find.text('اسمعه، واعمله'), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('a small phone with large text: nothing overflows', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpView(tester, locale: const Locale('ar'));
      tester.view.physicalSize = const Size(960, 1500);
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('welcome_next')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('welcome_taste')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.expectAccessible();
    });

    testWidgets('Reduce Motion: «التالي» jumps', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpView(tester);
      await tester.tap(find.byKey(const Key('welcome_next')));
      await tester.pump();
      expect(find.text(l10nEn.welcomeHearTitle), findsOneWidget);
    });
  });

  group('page', () {
    late FakeWelcomeRepository welcome;
    late FakeCatalogRepository catalog;

    Future<void> pumpPage(WidgetTester tester) {
      welcome = FakeWelcomeRepository(seen: false);
      catalog = FakeCatalogRepository();
      final router = GoRouter(
        initialLocation: AppRoutes.welcome,
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('home')),
          GoRoute(
            path: AppRoutes.taste,
            builder: (_, _) => const Text('taste'),
          ),
          GoRoute(
            path: AppRoutes.welcome,
            builder: (_, _) => const WelcomePage(),
          ),
        ],
      );
      addTearDown(router.dispose);
      return tester.pumpApp(
        ProviderScope(
          overrides: [
            ...welcomeOverrides(welcome),
            catalogRepositoryProvider.overrideWithValue(catalog),
          ],
          child: Router.withConfig(config: router),
        ),
      );
    }

    testWidgets('starts the menu download while you read', (tester) async {
      await pumpPage(tester);
      await tester.pumpAndSettle();
      expect(catalog.syncCalls, 1);
    });

    testWidgets('skipping saves it seen and opens Home', (tester) async {
      await pumpPage(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('welcome_skip')));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(welcome.seen, isTrue);
    });

    testWidgets('«قولنا ذوقك» opens the quiz', (tester) async {
      await pumpPage(tester);
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('welcome_next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('welcome_taste')));
      await tester.pumpAndSettle();
      expect(find.text('taste'), findsOneWidget);
      expect(welcome.seen, isTrue);
    });

    testWidgets('a failed save still lets you in', (tester) async {
      await pumpPage(tester);
      welcome.failSave = true;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('welcome_skip')));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });

  test('the seen flag starts from the repository', () {
    final container = ProviderContainer(
      overrides: welcomeOverrides(FakeWelcomeRepository(seen: false)),
    );
    addTearDown(container.dispose);
    expect(container.read(welcomeSeenProvider), isFalse);
    container
        .read(welcomeSeenProvider.notifier)
        .finish(WelcomeExit.menu, page: 3);
    expect(container.read(welcomeSeenProvider), isTrue);
  });
}
