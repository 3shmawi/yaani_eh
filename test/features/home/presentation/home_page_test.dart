import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/home/presentation/home_page.dart';
import 'package:yaani_eh/features/home/presentation/home_view.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group(HomeView, () {
    testWidgets('lists the menu with names and explanations', (tester) async {
      var opened = 0;
      await tester.pumpApp(
        HomeView(items: sampleCatalogItems(), onOpenSettings: () => opened++),
      );
      expect(find.text(l10nEn.menuTitle), findsOneWidget);
      expect(find.text(l10nEn.menuCount(12)), findsOneWidget);
      expect(find.text('Espresso'), findsOneWidget);
      expect(find.text('إسبريسو'), findsOneWidget);
      expect(find.text('A small, strong shot of coffee.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_settings_button')));
      expect(opened, 1);
      await tester.expectAccessible();
    });

    testWidgets('Arabic shows the Egyptian explanation, right to left', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeView(items: sampleCatalogItems(), onOpenSettings: () {}),
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
      );
      expect(find.text('قهوة مركزة صغيرة، شفطة أو اتنين.'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('Espresso'))),
        TextDirection.rtl,
      );
      await tester.expectAccessible();
    });

    testWidgets('empty and loading states', (tester) async {
      await tester.pumpApp(HomeView(items: const [], onOpenSettings: () {}));
      expect(find.text(l10nEn.menuEmpty), findsOneWidget);

      await tester.pumpApp(HomeView(items: null, onOpenSettings: () {}));
      expect(find.bySemanticsLabel(l10nEn.loading), findsOneWidget);
    });
  });

  testWidgets('HomePage reads the menu from the device', (tester) async {
    await tester.pumpApp(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(has: true),
          ),
        ],
        child: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flat White'), findsOneWidget);
  });
}
