import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_controller.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_view.dart';

/// The welcome, shown before Home on the first open. The menu starts
/// downloading underneath, so it's usually there by the last page.
class WelcomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listening keeps the sync running without rebuilding the pages.
    ref.listen(catalogSyncControllerProvider, (_, _) {});
    return WelcomeView(
      onExit: (exit, page) {
        ref.read(welcomeSeenProvider.notifier).finish(exit, page: page);
        context.go(
          exit == WelcomeExit.taste ? AppRoutes.taste : AppRoutes.home,
        );
      },
    );
  }
}
