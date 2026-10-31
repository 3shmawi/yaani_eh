import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/text/bidi.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_fonts.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('colors (Design System tokens)', () {
    for (final (name, p) in [
      ('light', AppPalette.light),
      ('dark', AppPalette.dark),
    ]) {
      test('$name: text pairs meet WCAG AA', () {
        expect(_contrast(p.ink, p.surface), greaterThanOrEqualTo(7));
        expect(_contrast(p.ink, p.surfaceRaised), greaterThanOrEqualTo(7));
        expect(_contrast(p.inkMuted, p.surface), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(p.inkMuted, p.surfaceRaised),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(p.onBrand, p.brand), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.brand, p.surface), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.danger, p.surface), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(p.success, p.surfaceRaised),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(p.warning, p.surfaceRaised),
          greaterThanOrEqualTo(4.5),
        );
        // Meaningful borders.
        expect(_contrast(p.lineStrong, p.surface), greaterThanOrEqualTo(3));
      });
    }

    test('header band titles stay readable across the gradient', () {
      for (final stop in [
        AppColors.headerTop,
        AppColors.espresso,
        AppColors.headerBottom,
      ]) {
        expect(_contrast(AppColors.onHeader, stop), greaterThanOrEqualTo(11));
        expect(
          _contrast(AppColors.onHeaderMuted, stop),
          greaterThanOrEqualTo(8),
        );
      }
    });

    test('selected chips are solid and high contrast', () {
      // Warm milk, not white: AAA (7:1) text, and clearly brighter than
      // the espresso band it sits on, in both themes.
      expect(
        _contrast(AppColors.onSelected, AppColors.selected),
        greaterThanOrEqualTo(7),
      );
      expect(
        _contrast(AppColors.selected, AppColors.espresso),
        greaterThanOrEqualTo(7),
      );
    });

    test('exact token values', () {
      expect(AppColors.brand, const Color(0xFF9A4A24));
      expect(AppPalette.light.surface, const Color(0xFFF6EEE6));
      expect(AppPalette.dark.brand, const Color(0xFFE5A178));
      expect(AppColors.glassClearLight.a, closeTo(0.5, 0.01));
      expect(AppColors.glassClearDark.a, closeTo(0.55, 0.01));
    });
  });

  group(AppTextStyles, () {
    // Spacing is screen-scaled (text isn't), so ScreenUtil must be ready.
    setUp(
      () => ScreenUtil.configure(
        data: const MediaQueryData(size: Size(375, 812)),
        designSize: const Size(375, 812),
        minTextAdapt: false,
        splitScreenMode: false,
      ),
    );
    test('text is the same size on every phone, like iOS', () {
      final small = AppTextStyles.latin(TextRole.body).fontSize;
      ScreenUtil.configure(
        data: const MediaQueryData(size: Size(430, 932)),
        designSize: const Size(375, 812),
      );
      expect(AppTextStyles.latin(TextRole.body).fontSize, small);
      expect(small, 15);
    });

    test('Arabic reading text is a point smaller than Latin', () {
      for (final role in [TextRole.body, TextRole.callout, TextRole.cardBody]) {
        expect(
          AppTextStyles.arabic(role).fontSize,
          AppTextStyles.latin(role).fontSize! - 1,
          reason: '$role',
        );
      }
    });

    test('picks the font by the string, not the app language', () {
      final latin = AppTextStyles.forText('Flat White', TextRole.headline);
      final arabic = AppTextStyles.forText('فلات وايت', TextRole.headline);
      expect(latin.fontFamily, AppFonts.latin);
      expect(arabic.fontFamily, AppFonts.arabic);
    });

    test('Arabic runs a taller line height', () {
      final latin = AppTextStyles.latin(TextRole.body);
      final arabic = AppTextStyles.arabic(TextRole.body);
      expect(latin.height, closeTo(22 / 15, 0.001));
      expect(arabic.height, closeTo(23 / 14, 0.001));
      expect(arabic.height, greaterThan(latin.height!));
    });

    test('UI copy follows the locale', () {
      expect(
        AppTextStyles.forLocale(const Locale('ar'), TextRole.label).fontFamily,
        AppFonts.arabic,
      );
      expect(
        AppTextStyles.forLocale(const Locale('en'), TextRole.label).fontFamily,
        AppFonts.latin,
      );
    });

    test('never smaller than caption (12)', () {
      for (final role in TextRole.values) {
        expect(AppTextStyles.latin(role).fontSize, greaterThanOrEqualTo(12));
        expect(AppTextStyles.arabic(role).fontSize, greaterThanOrEqualTo(12));
      }
    });
  });

  group(Bidi, () {
    test('detects Arabic', () {
      expect(Bidi.hasArabic('قهوة'), isTrue);
      expect(Bidi.hasArabic('Latte'), isFalse);
      expect(Bidi.hasArabic('Latte لاتيه'), isTrue);
      expect(Bidi.hasArabic(''), isFalse);
    });

    test('keeps ranges left-to-right inside RTL text', () {
      expect(Bidi.range(70, 150), '\u206670–150\u2069');
      expect(Bidi.range(90, 90), '\u206690\u2069');
      expect(Bidi.ltr('0.75×'), '\u20660.75×\u2069');
    });
  });

  group('screen scaling', () {
    test('the design frame on a design-sized phone', () {
      expect(AppDimens.designFor(const Size(375, 812)), AppDimens.designSize);
    });

    test('a big phone or a tablet grows by at most maxScale', () {
      for (final screen in const [Size(430, 932), Size(1024, 1366)]) {
        final frame = AppDimens.designFor(screen);
        expect(
          screen.width / frame.width,
          lessThanOrEqualTo(AppDimens.maxScale),
        );
        expect(
          screen.height / frame.height,
          lessThanOrEqualTo(AppDimens.maxScale),
        );
      }
      // An iPhone 15 grows less than the cap: by its own width.
      final iphone = AppDimens.designFor(const Size(393, 852));
      expect(393 / iphone.width, closeTo(393 / 375, 0.001));
    });

    test('a small phone still scales down to fit', () {
      expect(AppDimens.designFor(const Size(320, 568)), AppDimens.designSize);
    });
  });

  test('back and forward chevrons mirror in Arabic, like iOS', () {
    expect(AppIcons.back.matchTextDirection, isTrue);
    expect(AppIcons.forward.matchTextDirection, isTrue);
  });
}
