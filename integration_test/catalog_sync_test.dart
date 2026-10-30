import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_view.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: "No internet at the café? No problem."
/// First launch downloads the menu once (the cup fills up), then the app is
/// closed, the phone goes offline, and the whole menu still opens.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the menu downloads once, then opens offline', (tester) async {
    final app = await DemoApp.start();
    await tester.pump();

    // 1. First launch: the menu downloads, with progress and a tip.
    await pumpUntil(tester, find.byType(CatalogSyncView));
    await beat(tester, 1500);

    // 2. Done: the menu is on the phone.
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await beat(tester, 1200);
    await tester.drag(
      find.byKey(const Key('menu_list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await beat(tester);

    // 3. Airplane mode, close the app, open it again.
    await app.setOnline(tester, online: false);
    await beat(tester);
    await app.relaunch(tester);
    await app.setOnline(tester, online: false);
    await pumpUntil(tester, find.byKey(const Key('menu_list')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 4. The whole menu is still there, with the offline note.
    expect(find.byKey(const Key('menu_list')), findsOneWidget);
    expect(find.byIcon(AppIcons.wifiSlash), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Iced Mocha'),
      find.byKey(const Key('menu_list')),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.text('Iced Mocha'), findsWidgets);
  });
}
