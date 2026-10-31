import 'package:flutter/widgets.dart';

/// The app's icons: Phosphor (MIT), bundled in `assets/fonts/Phosphor`.
/// Regular weight by default; [AppIconsFill] for the active tab and a
/// saved heart. Add an icon by copying its code point from
/// https://phosphoricons.com (the same code point works in both weights).
abstract final class AppIcons {
  static const _family = 'PhosphorRegular';

  /// Back chevron: mirrors in RTL.
  static const back = IconData(
    0xe138,
    fontFamily: _family,
    matchTextDirection: true,
  );
  static const forward = IconData(
    0xe13a,
    fontFamily: _family,
    matchTextDirection: true,
  );
  static const search = IconData(0xe30c, fontFamily: _family);
  static const heart = IconData(0xe2a8, fontFamily: _family);
  static const speaker = IconData(0xe44a, fontFamily: _family);
  static const play = IconData(0xe3d0, fontFamily: _family);
  static const pause = IconData(0xe39e, fontFamily: _family);
  static const home = IconData(0xe2c2, fontFamily: _family);
  static const sliders = IconData(0xe432, fontFamily: _family);
  static const wifiSlash = IconData(0xe4f2, fontFamily: _family);
  static const plus = IconData(0xe3d4, fontFamily: _family);
  static const close = IconData(0xe4f6, fontFamily: _family);
  static const checkCircle = IconData(0xe184, fontFamily: _family);
  static const warningCircle = IconData(0xe4e2, fontFamily: _family);
  static const coffee = IconData(0xe1c2, fontFamily: _family);
  static const cake = IconData(0xe780, fontFamily: _family);
  static const send = IconData(0xe398, fontFamily: _family);
  static const retry = IconData(0xe036, fontFamily: _family);
  static const check = IconData(0xe182, fontFamily: _family);
  static const settings = IconData(0xe270, fontFamily: _family);
}

/// Fill weight: active tab, saved heart, playing audio.
abstract final class AppIconsFill {
  static const _family = 'PhosphorFill';

  static const heart = IconData(0xe2a8, fontFamily: _family);
  static const home = IconData(0xe2c2, fontFamily: _family);
  static const search = IconData(0xe30c, fontFamily: _family);
  static const sliders = IconData(0xe432, fontFamily: _family);
  static const speaker = IconData(0xe44a, fontFamily: _family);
}
