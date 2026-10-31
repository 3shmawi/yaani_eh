import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The app's two tabs, «المنيو» and «المفضلة», under the floating glass
/// tab bar. The Favorites tab shows how many drinks are saved.
class AppTabsShell extends ConsumerWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saved = ref.watch(favoriteIdsProvider).length;
    return AppTabScaffold(
      body: shell,
      selectedIndex: shell.currentIndex,
      // Tapping the open tab again takes it back to its start.
      onSelected: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
      tabs: [
        AppTab(
          icon: AppIcons.home,
          activeIcon: AppIconsFill.home,
          label: l10n.tabMenu,
        ),
        AppTab(
          icon: AppIcons.heart,
          activeIcon: AppIconsFill.heart,
          label: l10n.tabFavorites,
          badge: saved,
          semanticLabel: saved == 0
              ? l10n.tabFavorites
              : l10n.tabFavoritesSaved(saved),
        ),
      ],
    );
  }
}
