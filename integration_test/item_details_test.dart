import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_view.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: «يعني إيه فلات وايت؟» — "What is a flat white?"
/// Tap a drink → its plain explanation, calories, traits and price; then a
/// similar drink, and back to the menu.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open a drink, then a similar one, then go back', (tester) async {
    await DemoApp.start(pageSize: 100);
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 1. Find Flat White among the cards and open it.
    final menu = find.byKey(const Key('menu_list'));
    final flatWhite = find.widgetWithText(DrinkCard, 'Flat White');
    await tester.dragUntilVisible(flatWhite, menu, const Offset(0, -200));
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.tap(flatWhite);
    await tester.pumpAndSettle();
    await beat(tester, 2000);
    expect(find.byType(DrinkView), findsOneWidget);

    // 2. Read on: traits, price, similar drinks.
    final details = find.byKey(const Key('drink_scroll'));
    await tester.drag(details, const Offset(0, -350));
    await tester.pumpAndSettle();
    await beat(tester, 1500);

    // 3. A similar drink.
    final similar = find.descendant(
      of: find.byKey(const Key('similar_drinks')),
      matching: find.byType(DrinkCard),
    );
    await tester.dragUntilVisible(
      similar.first,
      details,
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(similar.first);
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byType(DrinkView), findsOneWidget);

    // 4. Back twice: the first drink, then the menu.
    await tester.tap(find.byKey(const Key('drink_back')).last);
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.tap(find.byKey(const Key('drink_back')).last);
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    expect(find.byType(DrinkView), findsNothing);
    expect(find.byKey(const Key('menu_list')), findsOneWidget);
  });
}
