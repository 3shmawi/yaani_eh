import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yaani_eh/core/text/bidi.dart';
import 'package:yaani_eh/core/theme/app_fonts.dart';

/// The Design System type scale. Each role exists twice: Latin
/// (Plus Jakarta Sans) and Arabic (Readex Pro, taller line height).
///
/// [cardTitle] and [cardBody] are the drink card's two sizes: the name,
/// then its spelling and «يعني» line.
enum TextRole {
  largeTitle,
  title,
  headline,
  body,
  callout,
  label,
  caption,
  cardTitle,
  cardBody,
}

/// Every text style in the app. Colors come from the theme, so these only
/// define family, size, weight, line height and tracking.
///
/// - UI copy follows the app language: `context.text(TextRole.body)`.
/// - Content follows the string's own script (a Latin menu name on an
///   Arabic screen stays Latin): `AppTextStyles.forText(name, role)`.
abstract final class AppTextStyles {
  static TextStyle latin(TextRole role) => switch (role) {
    TextRole.largeTitle => _latin(34, 41, FontWeight.w700, -0.4),
    TextRole.title => _latin(24, 30, FontWeight.w700, -0.2),
    TextRole.headline => _latin(17, 22, FontWeight.w600),
    TextRole.body => _latin(15, 22, FontWeight.w400),
    TextRole.callout => _latin(14, 20, FontWeight.w500),
    TextRole.label => _latin(13, 16, FontWeight.w600),
    TextRole.caption => _latin(12, 16, FontWeight.w500),
    TextRole.cardTitle => _latin(15, 20, FontWeight.w600, -0.1),
    TextRole.cardBody => _latin(13, 18, FontWeight.w400),
  };

  static TextStyle arabic(TextRole role) => switch (role) {
    TextRole.largeTitle => _arabic(32, 44, FontWeight.w700),
    TextRole.title => _arabic(22, 32, FontWeight.w700),
    TextRole.headline => _arabic(17, 26, FontWeight.w600),
    TextRole.body => _arabic(15, 26, FontWeight.w400),
    TextRole.callout => _arabic(14, 22, FontWeight.w500),
    TextRole.label => _arabic(13, 20, FontWeight.w600),
    TextRole.caption => _arabic(12, 18, FontWeight.w500),
    TextRole.cardTitle => _arabic(15, 22, FontWeight.w600),
    TextRole.cardBody => _arabic(13, 20, FontWeight.w400),
  };

  /// The style for [text] by its script, whatever the app language.
  static TextStyle forText(String text, TextRole role) =>
      Bidi.hasArabic(text) ? arabic(role) : latin(role);

  /// The style for UI copy in [locale].
  static TextStyle forLocale(Locale locale, TextRole role) =>
      locale.languageCode == 'ar' ? arabic(role) : latin(role);

  /// Material text theme for [locale], mapped from the Design System roles.
  static TextTheme textTheme(Locale locale) {
    TextStyle s(TextRole role) => forLocale(locale, role);
    return TextTheme(
      displaySmall: s(TextRole.largeTitle),
      headlineSmall: s(TextRole.title),
      titleLarge: s(TextRole.title),
      titleMedium: s(TextRole.headline),
      titleSmall: s(TextRole.callout),
      bodyLarge: s(TextRole.body),
      bodyMedium: s(TextRole.body),
      bodySmall: s(TextRole.caption),
      labelLarge: s(TextRole.label),
      labelMedium: s(TextRole.label),
      labelSmall: s(TextRole.caption),
    );
  }

  static TextStyle _latin(
    double size,
    double lineHeight,
    FontWeight weight, [
    double tracking = 0,
  ]) => TextStyle(
    fontFamily: AppFonts.latin,
    fontFamilyFallback: const [AppFonts.arabic],
    fontSize: size.sp,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: tracking,
  );

  static TextStyle _arabic(double size, double lineHeight, FontWeight weight) =>
      TextStyle(
        fontFamily: AppFonts.arabic,
        fontFamilyFallback: const [AppFonts.latin],
        fontSize: size.sp,
        height: lineHeight / size,
        fontWeight: weight,
      );
}

extension AppTextContext on BuildContext {
  /// The style for UI copy in the current app language.
  TextStyle text(TextRole role) =>
      AppTextStyles.forLocale(Localizations.localeOf(this), role);
}
