import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaani_eh/core/theme/app_theme.dart';
import 'package:yaani_eh/features/settings/domain/entities/app_settings.dart';
import 'package:yaani_eh/features/settings/presentation/settings_view.dart';

import '../../../helpers/pump_app.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'app',
      packageName: 'com.example.app',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  Widget view({
    AppSettings settings = const AppSettings(),
    ValueChanged<Locale?>? onLocaleChanged,
    VoidCallback? onOpenPrivacy,
    VoidCallback? onOpenTerms,
    VoidCallback? onOpenLicenses,
  }) => SettingsView(
    settings: settings,
    onLocaleChanged: onLocaleChanged ?? (_) {},
    onThemeModeChanged: (_) {},
    onOpenPrivacy: onOpenPrivacy,
    onOpenTerms: onOpenTerms,
    onOpenLicenses: onOpenLicenses,
  );

  group(SettingsView, () {
    testWidgets('shows the app version and build number, left to right', (
      tester,
    ) async {
      await tester.pumpApp(view());
      await tester.pumpAndSettle();

      expect(find.text('1.2.3 (45)'), findsOneWidget);
      final value = tester.widget<Text>(
        find.byKey(const Key('settings_version')),
      );
      expect(value.textDirection, TextDirection.ltr);
    });

    testWidgets('the language row shows the current choice', (tester) async {
      await tester.pumpApp(
        view(settings: const AppSettings(locale: Locale('en'))),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('settings_language')),
          matching: find.text(l10nEn.languageEnglish),
        ),
        findsOneWidget,
      );
    });

    testWidgets('picks a language from the sheet', (tester) async {
      Locale? locale = const Locale('x');
      await tester.pumpApp(view(onLocaleChanged: (value) => locale = value));

      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_choice_1')));
      await tester.pumpAndSettle();
      expect(locale, const Locale('en'));
      expect(find.byKey(const Key('settings_choice_1')), findsNothing);

      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_choice_0')));
      await tester.pumpAndSettle();
      expect(locale, isNull);
    });

    testWidgets('closing the sheet changes nothing', (tester) async {
      var calls = 0;
      await tester.pumpApp(view(onLocaleChanged: (_) => calls++));

      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_choice_2')), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_choice_2')), findsNothing);
      expect(calls, 0);
    });

    testWidgets('the sheet marks the current language', (tester) async {
      // A first launch is Arabic (AppSettings' default).
      await tester.pumpApp(view());
      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();

      bool selected(int i) => tester
          .getSemantics(find.byKey(Key('settings_choice_$i')))
          .flagsCollection
          .isSelected
          .toBoolOrNull()!;
      expect(selected(2), isTrue);
      expect(selected(1), isFalse);
    });

    testWidgets('no theme row while light mode is off', (tester) async {
      await tester.pumpApp(view());
      expect(AppTheme.lightModeReady, isFalse);
      expect(find.byKey(const Key('settings_theme')), findsNothing);
      expect(find.text(l10nEn.settingsTheme), findsNothing);
    });

    testWidgets('opens the privacy policy, terms and licenses', (tester) async {
      final opened = <String>[];
      await tester.pumpApp(
        view(
          onOpenPrivacy: () => opened.add('privacy'),
          onOpenTerms: () => opened.add('terms'),
          onOpenLicenses: () => opened.add('licenses'),
        ),
      );

      await tester.tap(find.text(l10nEn.settingsPrivacy));
      await tester.tap(find.text(l10nEn.settingsTerms));
      await tester.tap(find.text(l10nEn.settingsLicenses));
      expect(opened, ['privacy', 'terms', 'licenses']);
    });

    testWidgets('hides the About links without callbacks', (tester) async {
      await tester.pumpApp(view());
      expect(find.byKey(const Key('settings_privacy')), findsNothing);
      expect(find.byKey(const Key('settings_terms')), findsNothing);
      expect(find.byKey(const Key('settings_licenses')), findsNothing);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(
        view(onOpenPrivacy: () {}, onOpenTerms: () {}, onOpenLicenses: () {}),
      );
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });

    testWidgets('the choice sheet meets accessibility guidelines', (
      tester,
    ) async {
      await tester.pumpApp(view());
      await tester.tap(find.byKey(const Key('settings_language')));
      await tester.pumpAndSettle();
      await tester.expectAccessible();
    });
  });
}
