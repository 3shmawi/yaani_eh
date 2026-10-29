import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/features/home/presentation/home_page.dart';
import 'package:yaani_eh/features/settings/presentation/settings_view.dart';
import 'package:yaani_eh/main.dart' as app;

import 'helpers/demo.dart';

// TEMPORARY diagnostics: bounded settles + step markers in logcat.
Future<void> _settle(WidgetTester tester, String step) async {
  debugPrint('YE_STEP settle start: $step');
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    debugPrint('YE_STEP settle ok: $step');
  } on Object catch (e) {
    debugPrint('YE_STEP settle FAILED: $step -> $e');
    rethrow;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on home and opens settings', (tester) async {
    debugPrint('YE_STEP main start');
    await app.main();
    debugPrint('YE_STEP main returned');
    await _settle(tester, 'after main');
    await beat(tester, 1500);

    expect(find.byType(HomePage), findsOneWidget);
    debugPrint('YE_STEP home found');

    await tester.tap(find.byKey(const Key('home_settings_button')));
    await _settle(tester, 'after tap');
    await beat(tester);

    expect(find.byType(SettingsView), findsOneWidget);
    debugPrint('YE_STEP settings found');
    await beat(tester, 1500);
  });
}
