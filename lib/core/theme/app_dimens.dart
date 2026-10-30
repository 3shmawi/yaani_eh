import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing, radii, blur and sizes from the Design System, scaled to the
/// screen with flutter_screenutil. Never hard-code sizes in widgets.
abstract final class AppDimens {
  /// The size of the design frame the UI was drawn on.
  static const designSize = Size(375, 812);

  /// Icon-to-label gap.
  static double get space1 => 4.w;

  /// Gap between chips and pills; inner padding of small controls.
  static double get space2 => 8.w;

  /// Gap between rows; padding of compact glass labels.
  static double get space3 => 12.w;

  /// Screen side gutter; card padding.
  static double get space4 => 16.w;

  /// Padding of large glass cards and sheets.
  static double get space5 => 20.w;

  /// Gap between screen sections.
  static double get space6 => 24.w;

  /// Top of empty/error states; above the tab bar.
  static double get space8 => 32.w;

  /// Hero spacing on details and onboarding.
  static double get space10 => 40.w;

  static double get radiusSm => 10.r;
  static double get radiusMd => 16.r;
  static double get radiusLg => 24.r;
  static double get radiusXl => 32.r;
  static const radiusPill = 999.0;

  /// Backdrop blur as a Flutter sigma (≈ the CSS radius ÷ 2).
  static const blurGlassClear = 10.0;
  static const blurGlass = 12.0;
  static const blurGlassStrong = 20.0;

  /// Saturation of clear glass.
  static const glassSaturation = 1.6;

  /// Minimum hit area of every control, even when it draws smaller.
  /// Not scaled: it's an accessibility floor in logical pixels.
  static const touchTarget = 48.0;
  static double get controlHeight => 44.h;
  static double get chipHeight => 34.h;
  static double get searchHeight => 48.h;
  static double get icon => 24.r;
  static double get iconChip => 20.r;
  static double get tabBarHeight => 60.h;
  static double get rowImage => 104.w;
  static double get rowMinHeight => 112.h;

  /// One tile of the header band's mashrabiya pattern.
  static double get patternTile => 28.r;

  /// Pronounce pill: the visible height of a segment and the speed toggle
  /// (the tap area stays [touchTarget]).
  static double get pronounceSegment => 36.r;

  /// Pronounce pill: the moving bars of a playing name.
  static const soundBarWidth = 3.0;
  static const soundBarGap = 2.0;
}

/// Motion from the Design System: short and purposeful (150–300 ms).
/// Widgets that use these turn motion off with Reduce Motion.
abstract final class AppMotion {
  /// A switch or chip moving its selection.
  static const select = Duration(milliseconds: 200);

  /// A list scrolling to a category after its chip is tapped.
  static const jump = Duration(milliseconds: 300);

  /// A card's press feedback.
  static const press = Duration(milliseconds: 150);
  static const pressScale = 0.97;

  /// A list's cards rising into place the first time it shows.
  static const reveal = Duration(milliseconds: 280);
  static const revealStagger = Duration(milliseconds: 45);
  static const revealRise = 12.0;

  /// Only the first cards are staggered; later ones show at once, so
  /// scrolling never waits for them.
  static const revealStaggered = 8;

  static const Curve enter = Curves.easeOutCubic;
}
