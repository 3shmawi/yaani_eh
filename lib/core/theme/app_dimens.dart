import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing, radii, blur and sizes from the Design System, scaled to the
/// screen with flutter_screenutil. Never hard-code sizes in widgets.
///
/// Sizes follow the screen, but only so far: up to [maxScale] on a big
/// phone or a tablet, which gets more room instead of bigger everything
/// (like iOS). Text doesn't scale with the screen at all; it follows the
/// phone's own text size (`AppTextStyles`).
abstract final class AppDimens {
  /// The size of the design frame the UI was drawn on.
  static const designSize = Size(375, 812);

  /// The most a size grows on a screen bigger than [designSize].
  static const maxScale = 1.1;

  /// The frame to give flutter_screenutil on a [screen] (in points): the
  /// design frame, widened on big screens so nothing grows past
  /// [maxScale]. Smaller phones still scale down to fit.
  static Size designFor(Size screen) => Size(
    math.max(designSize.width, screen.width / maxScale),
    math.max(designSize.height, screen.height / maxScale),
  );

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

  /// The count on a tab's icon (saved drinks).
  static double get badgeSize => 16.r;
  static double get rowImage => 104.w;
  static double get rowMinHeight => 112.h;

  /// The long-press preview's width (it stays a card, not a sheet, on a
  /// tablet).
  static double get previewWidth => 380.w;

  /// The long-press preview's photo: wider than a card's, so the text fits.
  static const double previewPhotoRatio = 4 / 3;

  /// One tile of the header band's mashrabiya pattern.
  static double get patternTile => 28.r;

  /// «طريقة التحضير»: the cup, the numbered dots of the steps, the sheet's
  /// grab handle, and the big picture of a step in step-by-step mode.
  static double get cupWidth => 112.r;
  static double get cupHeight => 136.r;
  static double get stepDot => 34.r;
  static double get stepLine => 2.r;
  static double get grabWidth => 38.w;
  static double get grabHeight => 5.h;
  static double get stepArt => 120.r;
  static double get stepArtIcon => 54.r;
  static double get progressHeight => 4.h;
  static double get legendSwatch => 12.r;

  /// How tall a sheet may get, as a share of the screen.
  static const double sheetMaxShare = 0.92;

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

  /// The long-press preview growing into place.
  static const previewFrom = 0.94;

  /// A heart popping when a drink is saved.
  static const pop = Duration(milliseconds: 450);
  static const popFrom = 0.7;

  /// A card's press feedback.
  static const press = Duration(milliseconds: 120);
  static const release = Duration(milliseconds: 320);
  static const pressScale = 0.96;

  /// A list's cards rising into place the first time it shows.
  static const reveal = Duration(milliseconds: 280);

  /// The cup filling in, one layer after another (bottom first).
  static const pourLayer = Duration(milliseconds: 520);
  static const pourStagger = Duration(milliseconds: 260);

  /// Step by step: sliding to the next step.
  static const step = Duration(milliseconds: 360);
  static const revealStagger = Duration(milliseconds: 45);
  static const revealRise = 12.0;

  /// Only the first cards are staggered; later ones show at once, so
  /// scrolling never waits for them.
  static const revealStaggered = 8;

  static const Curve enter = Curves.easeOutCubic;
}
