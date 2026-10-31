import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: «اعمله في البيت» — "Make it at home."
/// Long-press Flat White, then «طريقة التحضير»: the cup fills in layer by
/// layer, to scale, and the steps follow. «خطوة بخطوة» goes through them
/// one at a time, to «خلصت، بالهنا» and back to the menu.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('see how a drink is made, then make it step by step', (
    tester,
  ) async {
    await DemoApp.start(pageSize: 100);
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 1. Long-press Flat White, in the middle of the screen.
    final card = find.widgetWithText(DrinkCard, 'Flat White');
    await tester.dragUntilVisible(
      card,
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await Scrollable.ensureVisible(tester.element(card), alignment: 0.5);
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.longPress(card);
    await tester.pumpAndSettle();
    await beat(tester, 1500);

    // 2. «طريقة التحضير»: the cup fills in, then the steps.
    await tester.tap(find.byKey(const Key('preview_recipe')));
    await tester.pumpAndSettle();
    await beat(tester, 2500);
    expect(find.byKey(const Key('recipe_cup')), findsOneWidget);

    final sheet = find.descendant(
      of: find.byKey(const Key('recipe_view')),
      matching: find.byType(Scrollable),
    );
    final stepByStep = find.byKey(const Key('recipe_step_by_step'));
    await tester.scrollUntilVisible(stepByStep, 120, scrollable: sheet);
    await tester.pumpAndSettle();
    await beat(tester, 1800);

    // 3. Step by step: one at a time, big, to the end.
    await tester.tap(stepByStep);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.byKey(const Key('step_by_step')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('steps_next')));
      await tester.pumpAndSettle();
      await beat(tester, 1500);
    }
    expect(find.byKey(const Key('steps_page_3')), findsOneWidget);

    // «خلصت، بالهنا»: back to the menu it was opened from.
    await tester.tap(find.byKey(const Key('steps_next')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    expect(find.byKey(const Key('step_by_step')), findsNothing);
    expect(find.widgetWithText(DrinkCard, 'Flat White'), findsOneWidget);
  });
}
