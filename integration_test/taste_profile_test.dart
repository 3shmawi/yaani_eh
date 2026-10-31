import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: «قولنا ذوقك» — "Tell us your taste."
/// Home invites to «ذوقي»: four questions, one at a time, each a tap.
/// Back on Home, «على ذوقك» shows the drinks that fit, with why; open one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> answer(WidgetTester tester, String key, int option) async {
    await tester.tap(find.byKey(Key('taste_option_${key}_$option')));
    await tester.pump(AppMotion.jump);
    await tester.pumpAndSettle();
    await beat(tester, 1000);
  }

  testWidgets('take the quiz, then see what fits your taste', (tester) async {
    await DemoApp.start(pageSize: 100);
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 1. The invite, under the drink of the day.
    final invite = find.byKey(const Key('taste_invite'));
    await Scrollable.ensureVisible(tester.element(invite), alignment: 0.4);
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    await tester.tap(find.byKey(const Key('taste_start')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);
    expect(find.byKey(const Key('taste_quiz')), findsOneWidget);

    // 2. Four questions: iced, sweet, with milk, and «doesn't matter».
    await answer(tester, 'temp', 1);
    await answer(tester, 'sweetness', 2);
    await answer(tester, 'milk', 0);
    await tester.tap(find.byKey(const Key('taste_skip')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // 3. Back on Home: «على ذوقك», with why under each.
    expect(find.byKey(const Key('taste_quiz')), findsNothing);
    final row = find.byKey(const Key('taste_row'));
    await Scrollable.ensureVisible(tester.element(row), alignment: 0.3);
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    final first = find.byKey(const Key('taste_match_iced_latte'));
    expect(first, findsOneWidget);

    // 4. Open the first match.
    await tester.tap(first);
    await tester.pumpAndSettle();
    await beat(tester, 1500);
    expect(find.text('Iced Latte'), findsWidgets);
  });
}
