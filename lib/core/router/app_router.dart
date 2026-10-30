import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/router/not_found_page.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_page.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_page.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_page.dart';
import 'package:yaani_eh/features/settings/presentation/settings_page.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_page.dart';

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
      // The menu, once the catalog is on the device (first launch downloads
      // it; see docs/features/catalog_sync.md).
      builder: (context, state) => const CatalogSyncPage(child: MenuPage()),
    ),
    GoRoute(
      path: AppRoutes.drinkPattern,
      // Untrusted input (deep links): anything that isn't a slug is a 404.
      redirect: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        return AppRoutes.slugPattern.hasMatch(slug) ? null : '/not-found';
      },
      builder: (context, state) => CatalogSyncPage(
        child: DrinkPage(slug: state.pathParameters['slug']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => CatalogSyncPage(
        child: SearchPage(
          initialQuery: AppRoutes.cleanQuery(state.uri.queryParameters['q']),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
