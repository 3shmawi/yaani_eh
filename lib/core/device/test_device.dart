import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the app runs on a Google test device: Firebase Test Lab, which
/// also runs Google Play's pre-launch report on every release. Those
/// devices are x86_64 emulators (Android build `QKR1.191246.002`, a
/// 288×448 screen, a real phone's name such as `OnePlus8Pro`) that made up
/// every native crash in Sentry and many of its 504s (docs/security.md →
/// "Monitoring: only real bugs").
///
/// Detected the documented way: the system setting `firebase.test.lab` is
/// "true" (firebase.google.com/docs/test-lab/android/android-studio, read
/// 2026-11-24). Android only; false everywhere else, and on any failure.
abstract final class TestDevice {
  static const channel = MethodChannel('yaanieh/device');

  static bool _isTestLab = false;

  static bool get isTestLab => _isTestLab;

  /// Tests set the answer here instead of asking the platform.
  @visibleForTesting
  static set isTestLab(bool value) => _isTestLab = value;

  /// Reads the setting once, at start, before monitoring and analytics.
  static Future<void> detect() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      _isTestLab = await channel.invokeMethod<bool>('isTestLab') ?? false;
    } on Object {
      _isTestLab = false;
    }
  }
}
