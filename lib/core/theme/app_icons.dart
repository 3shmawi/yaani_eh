import 'package:flutter/cupertino.dart';

/// The app's icons: SF Symbols' look on every platform, from
/// `CupertinoIcons` (cupertino_icons, MIT): the same outline weight and
/// rounded ends as iOS, so the glass controls read like the system's. A few
/// food glyphs SF doesn't have (coffee, cake) come from Phosphor (MIT),
/// bundled in `assets/fonts/Phosphor`. [AppIconsFill] is the filled weight
/// for the active tab, a saved heart and a playing name.
abstract final class AppIcons {
  static const _phosphor = 'PhosphorRegular';

  /// Back chevron: mirrors in RTL (like iOS).
  static const IconData back = CupertinoIcons.chevron_back;
  static const IconData forward = CupertinoIcons.chevron_forward;
  static const IconData search = CupertinoIcons.search;
  static const IconData heart = CupertinoIcons.heart;
  static const IconData speaker = CupertinoIcons.speaker_2;
  static const IconData play = CupertinoIcons.play;
  static const IconData pause = CupertinoIcons.pause;
  static const IconData home = CupertinoIcons.house;
  static const IconData sliders = CupertinoIcons.slider_horizontal_3;
  static const IconData wifiSlash = CupertinoIcons.wifi_slash;
  static const IconData plus = CupertinoIcons.plus;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData checkCircle = CupertinoIcons.checkmark_circle;
  static const IconData warningCircle = CupertinoIcons.exclamationmark_circle;
  static const IconData send = CupertinoIcons.paperplane;
  static const IconData retry = CupertinoIcons.arrow_clockwise;
  static const IconData check = CupertinoIcons.checkmark;
  static const IconData settings = CupertinoIcons.gear_alt;
  static const coffee = IconData(0xe1c2, fontFamily: _phosphor);
  static const cake = IconData(0xe780, fontFamily: _phosphor);
}

/// Filled weight: active tab, saved heart, playing name.
abstract final class AppIconsFill {
  static const IconData heart = CupertinoIcons.heart_fill;
  static const IconData home = CupertinoIcons.house_fill;
  static const IconData search = CupertinoIcons.search;
  static const IconData sliders = CupertinoIcons.slider_horizontal_3;
  static const IconData speaker = CupertinoIcons.speaker_2_fill;
}
