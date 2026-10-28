import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/router/not_found_page.dart';
import 'package:yaani_eh/features/home/presentation/home_page.dart';
import 'package:yaani_eh/features/settings/presentation/settings_page.dart';

/// Root navigator, used to show app-wide dialogs (e.g. the update dialog).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. Deep links are handled by go_router automatically.
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  observers: [
    ...Monitoring.navigatorObservers,
    ...Analytics.navigatorObservers,
  ],
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
