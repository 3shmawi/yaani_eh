import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/router/app_router.dart';
import 'package:yaani_eh/core/router/not_found_page.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_theme.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_page.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

import '../helpers/fake_catalog_repository.dart';

/// Deep links are untrusted input: unknown or crafted paths must land on a
/// safe screen, never crash or open something unexpected.
void main() {
  Future<void> pumpRouter(WidgetTester tester) async {
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
}
