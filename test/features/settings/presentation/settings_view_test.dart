import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_theme.dart';
import 'package:yaani_eh/features/settings/domain/entities/app_settings.dart';
import 'package:yaani_eh/features/settings/presentation/settings_view.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group(SettingsView, () {
    testWidgets('reports language choices', (tester) async {
      Locale? locale = const Locale('x');
      await tester.pumpApp(
        SettingsView(
          settings: const AppSettings(),
          onLocaleChanged: (value) => locale = value,
          onThemeModeChanged: (_) {},
        ),
      );

      await tester.tap(find.text(l10nEn.languageEnglish));
      expect(locale, const Locale('en'));
      await tester.tap(find.text(l10nEn.settingsLanguageSystem));
      expect(locale, isNull);
    });

    testWidgets('no theme choice while light mode is off', (tester) async {
      await tester.pumpApp(
        SettingsView(
          settings: const AppSettings(),
          onLocaleChanged: (_) {},
          onThemeModeChanged: (_) {},
        ),
      );
      expect(AppTheme.lightModeReady, isFalse);
      expect(find.text(l10nEn.settingsTheme), findsNothing);
      expect(find.text(l10nEn.settingsThemeLight), findsNothing);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(
        SettingsView(
          settings: const AppSettings(),
          onLocaleChanged: (_) {},
          onThemeModeChanged: (_) {},
        ),
      );
      await tester.expectAccessible();
    });

    testWidgets('marks the current language as selected', (tester) async {
      await tester.pumpApp(
        SettingsView(
          settings: const AppSettings(),
          onLocaleChanged: (_) {},
          onThemeModeChanged: (_) {},
        ),
      );
      final arabic = tester.widget<ListTile>(
        find.widgetWithText(ListTile, l10nEn.languageArabic),
      );
      final english = tester.widget<ListTile>(
        find.widgetWithText(ListTile, l10nEn.languageEnglish),
      );
      expect(arabic.selected, isTrue);
      expect(english.selected, isFalse);
    });
  });
}
