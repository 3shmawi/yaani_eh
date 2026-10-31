import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/app/app_tabs_shell.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/router/not_found_page.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_page.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_page.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_page.dart';
import 'package:yaani_eh/features/item_details/presentation/drink_page.dart';
import 'package:yaani_eh/features/recipes/presentation/step_by_step_page.dart';
import 'package:yaani_eh/features/settings/presentation/settings_page.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_page.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_page.dart';

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
    // The tabs: Menu and Favorites, each with its own navigator, so a tab
    // keeps its scroll position. Pages pushed from a tab (a drink, search,
    // settings) cover the tab bar.
    StatefulShellRoute(
      builder: (context, state, shell) => AppTabsShell(shell: shell),
      navigatorContainerBuilder: (context, shell, children) => IndexedStack(
        index: shell.currentIndex,
        children: [
          // Only the tab on screen flies its photos into the drink page:
          // a drink saved in Favorites is on Home too, with the same tag.
          for (final (i, child) in children.indexed)
            HeroMode(enabled: i == shell.currentIndex, child: child),
        ],
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              // The menu, once the catalog is on the device (first launch
              // downloads it; see docs/features/catalog_sync.md).
              builder: (context, state) =>
                  const CatalogSyncPage(child: MenuPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              builder: (context, state) =>
                  const CatalogSyncPage(child: FavoritesPage()),
            ),
          ],
        ),
      ],
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
      routes: [
        GoRoute(
          path: AppRoutes.drinkStepsSegment,
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: StepByStepPage(slug: state.pathParameters['slug']!),
          ),
        ),
      ],
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
      path: AppRoutes.taste,
      pageBuilder: (context, state) {
        // Untrusted input (deep links): only a slug is used; anything else
        // means the default section.
        final section = state.uri.queryParameters['section'];
        return MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: CatalogSyncPage(
            child: TastePage(
              section:
                  section != null && AppRoutes.slugPattern.hasMatch(section)
                  ? section
                  : null,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
