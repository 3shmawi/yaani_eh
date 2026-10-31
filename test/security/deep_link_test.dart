import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/router/app_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/router/not_found_page.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_theme.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_page.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_view.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_view.dart';
import 'package:yaani_eh/features/recipes/presentation/step_by_step_view.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_page.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_quiz_view.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_favorites.dart';
import '../helpers/fake_taste.dart';
import '../helpers/fake_welcome.dart';

/// Deep links are untrusted input: unknown or crafted paths must land on a
/// safe screen, never crash or open something unexpected.
void main() {
  late FakeFavoritesRepository favorites;

  Future<void> pumpRouter(
    WidgetTester tester, {
    FakeWelcomeRepository? welcome,
  }) async {
    favorites = FakeFavoritesRepository();
    tester.view
      ..physicalSize = const Size(1125, 2436)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(has: true),
          ),
          ...favoritesOverrides(favorites),
          ...welcomeOverrides(welcome),
          ...tasteOverrides(),
        ],
        child: AppUi.testWrap(
          ScreenUtilInit(
            designSize: AppDimens.designSize,
            builder: (context, _) => MaterialApp.router(
              routerConfig: appRouter,
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unknown and crafted paths show the not-found page', (
    tester,
  ) async {
    await pumpRouter(tester);

    for (final path in [
      '/does-not-exist',
      '/settings/../../etc/passwd',
      '/%2e%2e/admin',
      '/drink/../../etc/passwd',
      '/drink/%3Cscript%3Ealert(1)%3C%2Fscript%3E',
      "/drink/latte');DROP TABLE items;--",
      '/drink/FLAT_WHITE',
      '/drink/${'a' * 200}',
      '/drink/',
      '/favorites/secret',
      '/favorites/../../etc/passwd',
      '/favorites%2F..%2Fadmin',
      '/drink/../steps',
      '/drink/FLAT_WHITE/steps',
      "/drink/latte');DROP TABLE items;--/steps",
      '/drink/flat_white/steps/../../etc/passwd',
      '/drink/flat_white/steps/1',
      '/drink//steps',
      '/taste/../admin',
      '/taste/cafe',
      '/welcome/../admin',
      '/welcome/1',
    ]) {
      appRouter.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(NotFoundPage), findsOneWidget, reason: path);
    }
  });

  testWidgets('query parameters cannot redirect the app', (tester) async {
    await pumpRouter(tester);

    appRouter.go('/?redirect=https://evil.example.com');
    await tester.pumpAndSettle();

    expect(find.byType(MenuPage), findsOneWidget);
  });

  testWidgets('a fresh install opens on the welcome; links still work', (
    tester,
  ) async {
    final welcome = FakeWelcomeRepository(seen: false);
    await pumpRouter(tester, welcome: welcome);

    appRouter.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeView), findsOneWidget);

    // A link opens what it links to, not the welcome.
    appRouter.go('/drink/cortado');
    await tester.pumpAndSettle();
    expect(find.byType(DrinkView), findsOneWidget);

    // A crafted query on Home is ignored: still the welcome.
    appRouter.go('/?redirect=https://evil.example.com');
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeView), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(MenuPage), findsOneWidget);
    expect(welcome.seen, isTrue);

    // Seen: Home opens directly; /welcome still opens the welcome itself.
    appRouter.go('/welcome?next=https://evil.example.com');
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeView), findsOneWidget);
    appRouter.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(MenuPage), findsOneWidget);
  });

  testWidgets('a drink link opens the drink; an unknown one is safe', (
    tester,
  ) async {
    await pumpRouter(tester);

    appRouter.go('/drink/cortado');
    await tester.pumpAndSettle();
    expect(find.byType(DrinkView), findsOneWidget);

    appRouter.go('/drink/no_such_drink');
    await tester.pumpAndSettle();
    expect(find.byType(DrinkMissingView), findsOneWidget);

    appRouter.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('a steps link opens step by step, or says there is none', (
    tester,
  ) async {
    await pumpRouter(tester);

    for (final path in [
      AppRoutes.drinkSteps('flat_white'),
      '/drink/flat_white/steps?step=999',
      '/drink/flat_white/steps?redirect=https://evil.example.com',
    ]) {
      appRouter.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(StepByStepView), findsOneWidget, reason: path);
      expect(tester.takeException(), isNull);
    }

    // Closing goes back to the drink, not out of the app.
    await tester.tap(find.byKey(const Key('steps_close')));
    await tester.pumpAndSettle();
    expect(find.byType(DrinkView), findsOneWidget);

    // A drink without a recipe, and one that doesn't exist.
    for (final slug in ['latte', 'no_such_drink']) {
      appRouter.go(AppRoutes.drinkSteps(slug));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('steps_missing')), findsOneWidget);
    }
    appRouter.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('a taste link opens the quiz; a crafted section is ignored', (
    tester,
  ) async {
    await pumpRouter(tester);
    for (final path in [
      AppRoutes.taste,
      AppRoutes.tasteFor('cafe'),
      '/taste?section=desserts',
      "/taste?section=cafe');DROP TABLE items;--",
      '/taste?section=../../etc/passwd',
      '/taste?section=${'a' * 200}',
      '/taste?redirect=https://evil.example.com',
    ]) {
      appRouter.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(TasteQuizView), findsOneWidget, reason: path);
      expect(tester.takeException(), isNull);
    }
    // ✕ goes back into the app, never out of it.
    await tester.tap(find.byKey(const Key('taste_close')));
    await tester.pumpAndSettle();
    expect(find.byType(MenuPage), findsOneWidget);
  });

  testWidgets('the favorites link opens the Favorites tab, nothing else', (
    tester,
  ) async {
    await pumpRouter(tester);
    for (final path in [
      AppRoutes.favorites,
      '/favorites?redirect=https://evil.example.com',
      '/favorites#<script>',
    ]) {
      appRouter.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesView), findsOneWidget, reason: path);
      expect(tester.takeException(), isNull);
    }
    appRouter.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('the tab bar switches tabs and counts saved drinks', (
    tester,
  ) async {
    await pumpRouter(tester);
    appRouter.go('/');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app_tab_bar')), findsOneWidget);
    expect(find.byType(MenuPage), findsOneWidget);

    // Clear of the pinned chips and of «على ذوقك».
    final heart = find.byKey(const Key('favorite_espresso'));
    await Scrollable.ensureVisible(tester.element(heart), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(favorites.saved, hasLength(1));
    expect(
      find.descendant(
        of: find.byKey(const Key('app_tab_bar')),
        matching: find.text('1'),
      ),
      // The tab draws its icon twice to cross-fade into the active one.
      findsWidgets,
    );

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('app_tab_bar')),
            matching: find.text('Favorites'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesView), findsOneWidget);
    expect(find.text('Espresso'), findsWidgets);

    // A drink opened from Favorites covers the tab bar; back returns.
    await tester.tap(find.text('Espresso').first);
    await tester.pumpAndSettle();
    expect(find.byType(DrinkView), findsOneWidget);
    expect(find.byKey(const Key('app_tab_bar')), findsNothing);
    await tester.tap(find.byKey(const Key('drink_back')));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesView), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('app_tab_bar')),
            matching: find.text('Menu'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(MenuPage), findsOneWidget);
  });

  testWidgets('search links: any query is shown safely, never executed', (
    tester,
  ) async {
    await pumpRouter(tester);
    for (final query in [
      'latte',
      '<script>alert(1)</script>',
      "'; DROP TABLE items; --",
      '%00%0A',
      'a' * 500,
    ]) {
      appRouter.go(AppRoutes.searchFor(query));
      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsOneWidget, reason: query);
      expect(tester.takeException(), isNull);
    }
    appRouter.go('/');
    await tester.pumpAndSettle();
  });
}
