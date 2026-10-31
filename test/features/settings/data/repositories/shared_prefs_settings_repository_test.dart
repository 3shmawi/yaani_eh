import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaani_eh/features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'package:yaani_eh/features/settings/domain/entities/app_settings.dart';

void main() {
  group(SharedPrefsSettingsRepository, () {
    Future<SharedPrefsSettingsRepository> create([
      Map<String, Object> values = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
    }

    test('a first launch is Arabic and dark', () async {
      final repository = await create();
      expect(repository.load(), const AppSettings());
      expect(repository.load().locale, const Locale('ar'));
      expect(repository.load().themeMode, ThemeMode.dark);
    });

    test('saves and loads locale and theme mode', () async {
      final repository = await create();
      const settings = AppSettings(
        locale: Locale('en'),
        themeMode: ThemeMode.light,
      );

      await repository.save(settings);

      expect(repository.load(), settings);
    });

    test(
      "«the phone's language» is kept, not mistaken for a first launch",
      () async {
        final repository = await create({'settings.locale': 'ar'});

        await repository.save(const AppSettings(locale: null));

        expect(repository.load().locale, isNull);
      },
    );

    test('an unknown stored theme falls back to dark', () async {
      final repository = await create({'settings.theme_mode': 'neon'});
      expect(repository.load().themeMode, ThemeMode.dark);
    });
  });
}
