import 'package:flutter/widgets.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/backend/backend.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/theme/app_fonts.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';

/// Starts monitoring first, then initialises every core service and runs
/// the app. Anything that fails during start-up is reported.
///
/// [overrides] swap services for fakes (integration tests and demos).
Future<void> bootstrap(
  Widget Function() builder, {
  DependencyOverrides? overrides,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFonts.registerLicenses();
  await Monitoring.run(() async {
    await Backend.init();
    await Analytics.init();
    await Dependencies.init(overrides);
    await AppUi.initialize();
    return AppUi.wrap(builder());
  });
}
