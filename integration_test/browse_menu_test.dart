import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: "A café menu… that finally makes sense."
/// The cards rise in; each one says what the drink is in everyday words
/// («فلات وايت يعني زي اللاتيه بس أقوى»). Open one (its photo flies into
/// the page) and come back, filter by a category chip, then back to
/// everything.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A text in either language (the device may be in Arabic or English).
  Finder either(String en, String ar) => find.byWidgetPredicate(
    (w) => w is Text && [en, ar].contains(w.data ?? w.textSpan?.toPlainText()),
  );

  testWidgets('browse the menu and filter by category', (tester) async {
    await DemoApp.start(pageSize: 100);

    // 1. Home: drink of the day, then the coffee cards.
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1800);

    // 2. Scroll through the glass cards (any screen size).
    final list = find.byKey(const Key('menu_list'));
    await tester.dragUntilVisible(
      find.byType(DrinkCard).first,
      list,
      const Offset(0, -200),
    );
    expect(find.byType(DrinkCard), findsWidgets);
    await tester.drag(list, const Offset(0, -450));
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    await tester.drag(list, const Offset(0, -450));
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    await tester.drag(list, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await beat(tester);

    // 3. Every card says what it is: Flat White, «يعني زي اللاتيه بس أقوى».
    final meaning = either(
      'Like a latte, but stronger',
      'يعني زي اللاتيه بس أقوى وأصغر',
    );
    await tester.dragUntilVisible(meaning, list, const Offset(0, -150));
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(meaning, findsOneWidget);

    // Open it: the photo flies into the drink page. Then back.
    await tester.tap(find.widgetWithText(DrinkCard, 'Flat White'));
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.byKey(const Key('drink_back')), findsOneWidget);
    await tester.tap(find.byKey(const Key('drink_back')));
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.drag(list, const Offset(0, 1200));
    await tester.pumpAndSettle();

    // 4. Only iced coffee.
    await tester.tap(either('Iced coffee', 'قهوة ساقعة').first);
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('drink_of_the_day')), findsNothing);
    await tester.dragUntilVisible(
      find.text('Cold Brew'),
      list,
      const Offset(0, -200),
    );
    expect(find.text('Espresso'), findsNothing);
    await tester.drag(list, const Offset(0, 1200));
    await tester.pumpAndSettle();

    // 5. Back to everything.
    await tester.tap(either('All', 'الكل'));
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.byKey(const Key('drink_of_the_day')), findsOneWidget);
  });
}
