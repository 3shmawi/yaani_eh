import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_view.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_page.dart';
import 'package:yaani_eh/features/smart_search/presentation/widgets/answer_card.dart';
import 'package:yaani_eh/features/smart_search/presentation/widgets/result_row.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: «كتبت لبن ورغوة…» — "I typed milk and foam…"
/// Search both ways: a name gets the answer at once; a description gets
/// the drinks that match it, with the words highlighted. Works offline.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> typeSlowly(WidgetTester tester, String text) async {
    for (var i = 1; i <= text.length; i++) {
      await tester.enterText(find.byType(TextField), text.substring(0, i));
      await tester.pump(const Duration(milliseconds: isDemo ? 120 : 10));
    }
    await tester.pump(SearchPage.debounce);
    await tester.pumpAndSettle();
  }

  testWidgets('search by name, then by description', (tester) async {
    await DemoApp.start(pageSize: 100);
    await pumpUntil(tester, find.byKey(const Key('search_entry')));
    await tester.pumpAndSettle();
    await beat(tester);

    // 1. Open search from the Home header.
    await tester.tap(find.byKey(const Key('search_entry')));
    await tester.pumpAndSettle();
    await beat(tester);

    // 2. A name: the answer card, right away.
    await typeSlowly(tester, 'cortado');
    expect(find.byType(AnswerCard), findsOneWidget);
    await beat(tester, 2200);

    // 3. A description: the drinks that match, words highlighted.
    await tester.tap(find.byKey(const Key('search_clear')));
    await tester.pumpAndSettle();
    await typeSlowly(tester, 'milk foam');
    expect(find.byType(AnswerCard), findsNothing);
    expect(find.byType(ResultRow), findsWidgets);
    await beat(tester, 2200);

    // 4. Open the first result.
    await tester.tap(find.byType(ResultRow).first);
    await tester.pumpAndSettle();
    await beat(tester, 1800);
    expect(find.byType(DrinkView), findsOneWidget);
  });
}
