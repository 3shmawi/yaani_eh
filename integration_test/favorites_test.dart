import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: «احفظ اللي عجبك» — "Keep the ones you like."
/// Long-press Flat White: what it is at a glance, then save it from there.
/// Heart Espresso right on its card. The Favorites tab counts them; open
/// one; take them off again until it's empty, and back to the menu.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A text in either language (the device may be in Arabic or English).
  Finder either(String en, String ar) => find.byWidgetPredicate(
    (w) => w is Text && [en, ar].contains(w.data ?? w.textSpan?.toPlainText()),
  );

  Finder inTabBar(Finder finder) => find
      .descendant(of: find.byKey(const Key('app_tab_bar')), matching: finder)
      .first;

  /// The card in the middle of the screen, clear of the pinned chips.
  Future<Finder> centered(WidgetTester tester, String name) async {
    final card = find.widgetWithText(DrinkCard, name);
    await tester.dragUntilVisible(
      card,
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await Scrollable.ensureVisible(tester.element(card), alignment: 0.5);
    await tester.pumpAndSettle();
    return card;
  }

  testWidgets('save drinks, find them in Favorites, then clear them', (
    tester,
  ) async {
    await DemoApp.start(pageSize: 100);
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 1. Long-press Flat White: the preview says what it is.
    final flatWhite = await centered(tester, 'Flat White');
    await beat(tester);
    await tester.longPress(flatWhite);
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('drink_preview')), findsOneWidget);

    // Save it from the preview.
    await tester.tap(find.byKey(const Key('preview_save')));
    await tester.pumpAndSettle();
    await beat(tester);

    // 2. Heart Espresso right on its card.
    await centered(tester, 'Espresso');
    await beat(tester);
    await tester.tap(find.byKey(const Key('favorite_espresso')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 3. The Favorites tab counts them: newest first.
    expect(inTabBar(find.text('2')), findsOneWidget);
    await tester.tap(inTabBar(either('Favorites', 'المفضلة')));
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    final saved = tester
        .widgetList<DrinkCard>(find.byType(DrinkCard))
        .map((c) => c.item.slug)
        .toList();
    expect(saved, ['espresso', 'flat_white']);

    // 4. Open Flat White; its photo flies into the page. Back.
    await tester.tap(find.widgetWithText(DrinkCard, 'Flat White'));
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    await tester.tap(find.byKey(const Key('drink_back')));
    await tester.pumpAndSettle();
    await beat(tester);

    // 5. Take both off: the tab says how to save one.
    await tester.tap(find.byKey(const Key('favorite_espresso')));
    await tester.pumpAndSettle();
    await beat(tester);
    await tester.tap(find.byKey(const Key('favorite_flat_white')));
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byKey(const Key('favorites_empty')), findsOneWidget);

    // 6. Back to the menu.
    final toMenu = either('See the menu', 'شوف المنيو');
    await tester.ensureVisible(toMenu);
    await tester.pumpAndSettle();
    await tester.tap(toMenu);
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    expect(find.byKey(const Key('drink_of_the_day')), findsOneWidget);
  });
}
