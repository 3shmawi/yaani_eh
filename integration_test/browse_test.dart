import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/item_card.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: "Everything you don't get, one tap away."
/// Home opens on the drinks, with the section tabs on top and search always
/// there: the cards rise in, each saying what it is in everyday words
/// («فلات وايت يعني قهوة باللبن تقيلة في فنجان صغير»). Open one and come
/// back; a chip scrolls to its category; the «حلويات» tab says «جاي قريب»
/// and «مشروبات» brings the drinks back.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A text in either language (the device may be in Arabic or English).
  Finder either(String en, String ar) => find.byWidgetPredicate(
    (w) => w is Text && [en, ar].contains(w.data ?? w.textSpan?.toPlainText()),
  );

  testWidgets('Home opens on the drinks; a chip, then the desserts tab', (
    tester,
  ) async {
    await DemoApp.start(pageSize: 100);

    // 1. Home: search and the section tabs on top, the drink of the day,
    // then the cards.
    await pumpUntil(tester, find.byKey(const Key('item_of_the_day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('section_tabs')), findsOneWidget);
    await beat(tester, 1800);

    // 2. The drinks need no tap: their chips are right there.
    final list = find.byKey(const Key('browse_list'));
    expect(find.byKey(const Key('category_chips')), findsOneWidget);
    await beat(tester, 1500);

    // 3. Scroll through the cards (any screen size).
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

    // 6. The band has scrolled away: scroll back up to the section tabs.
    // Desserts are coming soon; the Drinks tab brings the items back.
    await tester.drag(list, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await beat(tester);
    final tabs = find.byKey(const Key('section_tabs'));
    await tester.tap(
      find.descendant(of: tabs, matching: either('Desserts', 'حلويات')),
    );
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('browse_coming_soon')), findsOneWidget);
    expect(find.byType(ItemCard), findsNothing);
    await tester.tap(
      find.descendant(of: tabs, matching: either('Drinks', 'مشروبات')),
    );
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.byType(ItemCard), findsWidgets);
  });
}
