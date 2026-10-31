import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: «منيو الكافيه… بس مفهوم» — "Café menus that make sense."
/// A fresh install opens on the welcome: three pages, swiped and tapped,
/// then «قولنا ذوقك» goes straight into the quiz, and Home after it.
/// Opened again, the app goes straight to Home.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first open: the welcome, then the quiz, then Home', (
    tester,
  ) async {
    final app = await DemoApp.start(pageSize: 100, welcomed: false);
    await pumpUntil(tester, find.byKey(const Key('welcome')));
    await tester.pumpAndSettle();
    await beat(tester, 1800);

    // 1. Swipe to the second page.
    await tester.fling(
      find.byType(PageView),
      Offset(
        Directionality.of(tester.element(find.byType(PageView))) ==
                TextDirection.rtl
            ? 200
            : -200,
        0,
      ),
      800,
    );
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('welcome_next')), findsOneWidget);

    // 2. «التالي» to the last page.
    await tester.tap(find.byKey(const Key('welcome_next')));
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('welcome_skip')), findsNothing);

    // 3. «قولنا ذوقك»: the quiz opens right away.
    await tester.tap(find.byKey(const Key('welcome_taste')));
    await pumpUntil(tester, find.byKey(const Key('taste_quiz')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 4. Not now: ✕ lands on Home, with the menu already downloaded.
    await tester.tap(find.byKey(const Key('taste_close')));
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 5. Opened again: straight to Home.
    await app.relaunch(tester);
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('welcome')), findsNothing);
    await beat(tester, 1000);
  });
}
