import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/app/app_tabs_shell.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/router/not_found_page.dart';
import 'package:yaani_eh/features/browse/presentation/browse_page.dart';
import 'package:yaani_eh/features/browse/presentation/section_page.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_page.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_page.dart';
import 'package:yaani_eh/features/item_details/presentation/item_page.dart';
import 'package:yaani_eh/features/recipes/presentation/step_by_step_page.dart';
import 'package:yaani_eh/features/settings/presentation/settings_page.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_page.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_controller.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_page.dart';

/// Root navigator, used to show app-wide dialogs (e.g. the update dialog).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. Deep links are handled by go_router automatically.
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
<<<<<<< yours
  // Old `/drink/...` links (shared before items were general) keep working.
  redirect: (context, state) => AppRoutes.fromLegacy(state.uri),
=======
  // Root navigator only. Tabs added later (StatefulShellBranch) need their
  // own `observers: Analytics.navigatorObservers` to be tracked.
>>>>>>> kit 1928c02
  observers: [
    ...Monitoring.navigatorObservers,
    ...Analytics.navigatorObservers,
  ],
  // Every route has a `name`: it is the screen name in analytics ($screen)
  // and monitoring. Without one a nested route reports only its own path
  // piece (e.g. ':exerciseId'). Names are stable; never put ids in them.
  routes: [
    // The tabs: Home, Favorites and Settings, each with its own navigator,
    // so a tab keeps its scroll position. A section stays under the tab
    // bar; pages pushed from a tab (an item, search) cover it.
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
          // Each tab has its own navigator: without this, PostHog never
          // sees its screens (the router's observers watch the root only).
          observers: Analytics.navigatorObservers,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              // The menu, once the catalog is on the device (first launch
              // downloads it; see docs/features/catalog_sync.md).
              // The welcome comes first, once (docs/features/welcome.md).
              // Only Home waits for it: a deep link opens what it links to.
              redirect: (context, state) =>
                  ProviderScope.containerOf(
                    context,
                    listen: false,
                  ).read(welcomeSeenProvider)
                  ? null
                  : AppRoutes.welcome,
              builder: (context, state) =>
                  const CatalogSyncPage(child: BrowsePage()),
            ),
            // One section of Home, under the tab bar. In the same branch,
            // so a link to it opens without the welcome or Home underneath
            // (back then goes Home).
            GoRoute(
              path: AppRoutes.sectionPattern,
              // Untrusted input (deep links): anything that isn't a slug
              // is a 404.
              redirect: (context, state) {
                final slug = state.pathParameters['slug'] ?? '';
                return AppRoutes.slugPattern.hasMatch(slug)
                    ? null
                    : '/not-found';
              },
              builder: (context, state) => CatalogSyncPage(
                child: SectionPage(slug: state.pathParameters['slug']!),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          // Each tab has its own navigator: without this, PostHog never
          // sees its screens (the router's observers watch the root only).
          observers: Analytics.navigatorObservers,
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              builder: (context, state) =>
                  const CatalogSyncPage(child: FavoritesPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.itemPattern,
      // Untrusted input (deep links): anything that isn't a slug is a 404.
      redirect: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        return AppRoutes.slugPattern.hasMatch(slug) ? null : '/not-found';
      },
      builder: (context, state) =>
          CatalogSyncPage(child: ItemPage(slug: state.pathParameters['slug']!)),
      routes: [
        GoRoute(
          path: AppRoutes.itemStepsSegment,
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: StepByStepPage(slug: state.pathParameters['slug']!),
          ),
        ),
      ],
    ),
    GoRoute(
<<<<<<< yours
      path: AppRoutes.search,
      builder: (context, state) => CatalogSyncPage(
        child: SearchPage(
          initialQuery: AppRoutes.cleanQuery(state.uri.queryParameters['q']),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
=======
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
>>>>>>> kit 1928c02
    ),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
