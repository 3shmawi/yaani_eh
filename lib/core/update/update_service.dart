import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaani_eh/core/backend/backend.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/update/app_version.dart';
import 'package:yaani_eh/core/update/update_info.dart';

/// Reads the `app_versions` row for this platform from Supabase and decides
/// whether to show an optional or a forced update. Control it from the
/// Supabase dashboard — no release needed.
abstract final class UpdateService {
  static const table = 'app_versions';

  /// Returns the update to show, or `null` when the app is up to date,
  /// offline, or Supabase isn't configured.
  static Future<UpdateInfo?> check() async {
    if (kIsWeb || !Backend.isConfigured) return null;
    final platform = _platform;
    if (platform == null) return null;

    try {
      final row = await Backend.client
          .from(table)
          .select()
          .eq('platform', platform)
          .maybeSingle();
      if (row == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final current = AppVersion.parse(packageInfo.version);
      final config = VersionConfig.fromJson(row);
      final type = evaluateUpdate(current: current, config: config);
      if (type == UpdateType.none) return null;
      return UpdateInfo(type: type, current: current, config: config);
    } on Exception catch (error, stackTrace) {
      unawaited(Monitoring.captureException(error, stackTrace));
      return null;
    }
  }

  /// This platform's store page (`app_versions.store_url`), for «حدّث
  /// التطبيق» outside the update dialog; null when offline or unknown.
  static Future<Uri?> storeUrl() async {
    if (kIsWeb || !Backend.isConfigured) return null;
    final platform = _platform;
    if (platform == null) return null;
    try {
      final row = await Backend.client
          .from(table)
          .select('store_url')
          .eq('platform', platform)
          .maybeSingle();
      return safeStoreUrl(row?['store_url']);
    } on Exception catch (error, stackTrace) {
      unawaited(Monitoring.captureException(error, stackTrace));
      return null;
    }
  }

  /// [value] as a store link, or null: https only, on the App Store or
  /// Google Play (content can't send the user anywhere else).
  @visibleForTesting
  static Uri? safeStoreUrl(Object? value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https') return null;
    return const {'apps.apple.com', 'play.google.com'}.contains(uri.host)
        ? uri
        : null;
  }

  static String? get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => null,
  };
}
