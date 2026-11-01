import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/item_card.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: "Everything you don't get, one tap away."
/// Home lists the sections; search is always on top. Open the drinks:
/// the cards rise in, each saying what it is in everyday words («فلات
/// وايت يعني قهوة باللبن تقيلة في فنجان صغير»). Open one and come back; a
/// chip scrolls to its category; back Home, desserts say «جاي قريب».
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A text in either language (the device may be in Arabic or English).
  Finder either(String en, String ar) => find.byWidgetPredicate(
    (w) => w is Text && [en, ar].contains(w.data ?? w.textSpan?.toPlainText()),
  );

  testWidgets('Home lists the sections; open drinks, a chip, desserts', (
    tester,
  ) async {
    await DemoApp.start(pageSize: 100);

    // 1. Home: search on top, the item of the day, then one card per
    // section.
    await pumpUntil(tester, find.byKey(const Key('item_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    final home = find.byKey(const Key('home_list'));
    final drinks = find.byKey(const Key('section_cafe'));
    await tester.dragUntilVisible(drinks, home, const Offset(0, -150));
    await tester.pumpAndSettle();
    await beat(tester, 1500);

    // 2. Open the drinks: their own page, with chips.
    await tester.tap(drinks);
    await pumpUntil(tester, find.byKey(const Key('browse_list')));
    await tester.pumpAndSettle();
    await beat(tester, 1500);

    // 3. Scroll through the cards (any screen size).
    final list = find.byKey(const Key('browse_list'));
    await tester.dragUntilVisible(
      find.byType(ItemCard).first,
      list,
      const Offset(0, -200),
    );
    expect(find.byType(ItemCard), findsWidgets);
    await tester.drag(list, const Offset(0, -450));
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    await tester.drag(list, const Offset(0, 1200));
    await tester.pumpAndSettle();

    // 4. Every card says what it is: Flat White, «يعني قهوة باللبن تقيلة…».
    final meaning = either(
      'Strong milky coffee in a small cup',
      'يعني قهوة باللبن تقيلة في فنجان صغير',
    );
    await tester.dragUntilVisible(meaning, list, const Offset(0, -150));
    // The whole card in the middle of the screen, like a thumb would put it.
    final flatWhite = find.widgetWithText(ItemCard, 'Flat White');
    await Scrollable.ensureVisible(tester.element(flatWhite), alignment: 0.5);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(meaning, findsOneWidget);

    // Open it: the photo flies into the item page. Then back.
    await tester.tap(flatWhite);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    await tester.tap(find.byKey(const Key('item_back')));
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.drag(list, const Offset(0, 1200));
    await tester.pumpAndSettle();

    // 5. A chip scrolls the list to its category; back, chips and search
    // stay pinned at the top.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('category_chips')),
        matching: either('Iced coffee', 'قهوة ساقعة'),
      ),
    );
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('section_pinned')), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Cold Brew'),
      list,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await beat(tester);

    // 6. Back Home: desserts are coming soon. Then back to the sections.
    await tester.tap(find.byKey(const Key('section_back')).first);
    await tester.pumpAndSettle();
    await beat(tester);
    final desserts = find.byKey(const Key('section_desserts'));
    await tester.dragUntilVisible(desserts, home, const Offset(0, -150));
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    await tester.tap(desserts);
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
    expect(find.byType(ItemCard), findsNothing);
    final back = either('Back to sections', 'ارجع للأقسام');
    await tester.ensureVisible(back); // below the fold on small phones
    await tester.pumpAndSettle();
    await tester.tap(back);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.byKey(const Key('home_list')), findsOneWidget);
  });
}
