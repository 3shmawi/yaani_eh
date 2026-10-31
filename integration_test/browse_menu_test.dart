import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: "A café menu… that finally makes sense."
/// The cards rise in; each one says what the drink is in everyday words
/// («فلات وايت يعني قهوة باللبن تقيلة في فنجان صغير»). Open one (its
/// photo flies into the page) and come back; a chip scrolls to its
/// category; desserts say they're coming soon.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A text in either language (the device may be in Arabic or English).
  Finder either(String en, String ar) => find.byWidgetPredicate(
    (w) => w is Text && [en, ar].contains(w.data ?? w.textSpan?.toPlainText()),
  );

  testWidgets('browse the menu, jump to a category, peek at desserts', (
    tester,
  ) async {
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

    // 3. Every card says what it is: Flat White, «يعني قهوة باللبن تقيلة…».
    final meaning = either(
      'Strong milky coffee in a small cup',
      'يعني قهوة باللبن تقيلة في فنجان صغير',
    );
    await tester.dragUntilVisible(meaning, list, const Offset(0, -150));
    // The whole card in the middle of the screen, like a thumb would put it.
    final flatWhite = find.widgetWithText(DrinkCard, 'Flat White');
    await Scrollable.ensureVisible(tester.element(flatWhite), alignment: 0.5);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(meaning, findsOneWidget);

    // Open it: the photo flies into the drink page. Then back.
    await tester.tap(flatWhite);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.byKey(const Key('drink_back')), findsOneWidget);
    await tester.tap(find.byKey(const Key('drink_back')));
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.drag(list, const Offset(0, 1200));
    await tester.pumpAndSettle();

    // 4. A chip scrolls the list to its category; the chips stay pinned
    // at the top and follow.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('category_chips')),
        matching: either('Iced coffee', 'قهوة ساقعة'),
      ),
    );
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('category_chips_pinned')), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Cold Brew'),
      list,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await beat(tester);

    // 5. Back up to the switch: desserts are coming soon. Then back.
    await tester.drag(list, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.tap(either('Desserts', 'حلويات'));
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('menu_coming_soon')), findsOneWidget);
    expect(find.byType(DrinkCard), findsNothing);
    final back = either('See what’s here now', 'شوف المتاح دلوقتي');
    await tester.ensureVisible(back); // below the fold on small phones
    await tester.pumpAndSettle();
    await tester.tap(back);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.byKey(const Key('drink_of_the_day')), findsOneWidget);
  });
}
