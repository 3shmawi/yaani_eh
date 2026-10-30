import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/features/settings/presentation/settings_view.dart';

import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on home and opens settings', (tester) async {
    await DemoApp.start(pageSize: 100);
    await pumpUntil(tester, find.byKey(const Key('menu_list')));
    await tester.pumpAndSettle();
    await beat(tester, 1500);

    await tester.tap(find.byKey(const Key('home_settings_button')));
    await tester.pumpAndSettle();
    await beat(tester);

    expect(find.byType(SettingsView), findsOneWidget);
    await beat(tester, 1500);
  });
}
