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
import 'package:yaani_eh/features/smart_search/presentation/search_page.dart';
import 'package:yaani_eh/l10n/l10n.dart';

import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_favorites.dart';

/// Deep links are untrusted input: unknown or crafted paths must land on a
/// safe screen, never crash or open something unexpected.
void main() {
  late FakeFavoritesRepository favorites;

  Future<void> pumpRouter(WidgetTester tester) async {
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

    await tester.tap(find.byKey(const Key('favorite_espresso')));
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
