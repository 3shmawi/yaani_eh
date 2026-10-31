import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaani_eh/features/settings/domain/entities/app_settings.dart';
import 'package:yaani_eh/features/settings/domain/repositories/settings_repository.dart';

/// [SettingsRepository] backed by SharedPreferences.
class SharedPrefsSettingsRepository implements SettingsRepository {
  new(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'settings.locale';
  static const _themeModeKey = 'settings.theme_mode';

  /// Stored for «زي لغة الموبايل», so it differs from "never chosen"
  /// (which is Arabic).
  static const _followDevice = 'system';

  @override
  AppSettings load() {
    final languageCode = _prefs.getString(_localeKey);
    final themeModeName = _prefs.getString(_themeModeKey);
    return AppSettings(
      locale: switch (languageCode) {
        null => AppSettings.defaultLocale,
        _followDevice => null,
        final code => Locale(code),
      },
      themeMode:
          ThemeMode.values.asNameMap()[themeModeName] ??
          AppSettings.defaultThemeMode,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(
      _localeKey,
      settings.locale?.languageCode ?? _followDevice,
    );
    await _prefs.setString(_themeModeKey, settings.themeMode.name);
  }
}
