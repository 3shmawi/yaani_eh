import 'package:flutter/material.dart';

/// The user's app-wide preferences.
@immutable
class AppSettings {
  const new({this.locale = defaultLocale, this.themeMode = defaultThemeMode});

  /// A first launch opens in Arabic, whatever the phone's language: the
  /// app is for Egyptian Arabic speakers. Settings can switch to English
  /// or to the phone's language.
  static const Locale defaultLocale = Locale('ar');

  /// Dark until the light palette is finished (see `AppTheme.lightModeReady`).
  static const ThemeMode defaultThemeMode = ThemeMode.dark;

  /// `null` means "follow the device language".
  final Locale? locale;
  final ThemeMode themeMode;

  AppSettings copyWith({ValueGetter<Locale?>? locale, ThemeMode? themeMode}) {
    return AppSettings(
      locale: locale != null ? locale() : this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.locale == locale &&
          other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(locale, themeMode);
}
