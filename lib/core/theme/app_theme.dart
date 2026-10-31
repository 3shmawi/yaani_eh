import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_fonts.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';

/// Light and dark themes from the Design System: Material 3 seeded from
/// `brand`, with the roles overridden by the exact tokens, plus
/// [AppPalette] for tokens Material has no role for.
/// Must be read inside `ScreenUtilInit` (sizes are screen-scaled).
abstract final class AppTheme {
  /// The light palette isn't finished, so the app runs dark and Settings
  /// doesn't offer a theme. Flip to true to bring the choice back.
  static const lightModeReady = false;

  /// The theme to run: the user's choice once light mode is ready.
  static ThemeMode modeFor(ThemeMode chosen) =>
      lightModeReady ? chosen : ThemeMode.dark;

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  /// Puts the text theme for the app language on top of the current theme
  /// (Arabic runs a taller line height). Used in `MaterialApp.builder`.
  static Widget localize(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    return Theme(
      data: theme.copyWith(
        textTheme: AppTextStyles.textTheme(locale).apply(
          bodyColor: theme.colorScheme.onSurface,
          displayColor: theme.colorScheme.onSurface,
        ),
      ),
      child: child,
    );
  }

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: brightness,
        ).copyWith(
          primary: p.brand,
          onPrimary: p.onBrand,
          primaryContainer: p.brandSoft,
          onPrimaryContainer: p.ink,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.inkMuted,
          surfaceContainerLowest: p.surfaceRaised,
          surfaceContainerLow: p.surfaceRaised,
          surfaceContainer: p.surfaceRaised,
          surfaceContainerHigh: p.surfaceRaised,
          surfaceContainerHighest: p.surfaceRaised,
          outline: p.lineStrong,
          outlineVariant: p.line,
          error: p.danger,
          scrim: p.scrim,
        );
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
    );
    final label = AppTextStyles.latin(TextRole.label);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.surface,
      fontFamily: AppFonts.latin,
      fontFamilyFallback: const [AppFonts.arabic],
      textTheme: AppTextStyles.textTheme(const Locale('en')),
      extensions: [p],
      dividerColor: p.line,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(AppDimens.touchTarget, AppDimens.controlHeight),
          shape: pill,
          textStyle: label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brand,
          minimumSize: Size(AppDimens.touchTarget, AppDimens.controlHeight),
          shape: pill,
          textStyle: label,
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: p.brand,
        brightness: brightness,
        scaffoldBackgroundColor: p.surface,
      ),
    );
  }
}
