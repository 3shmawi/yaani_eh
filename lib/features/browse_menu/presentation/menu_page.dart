import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_controller.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_view.dart';

/// Home: wires the menu state to [MenuView].
class MenuPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MenuView(
    menu: ref.watch(menuProvider),
    onSelectCategory: (c) => ref
        .read(selectedCategoryProvider.notifier)
        .select(c?.id, slug: c?.slug),
    onOpenSettings: () => unawaited(context.push<void>(AppRoutes.settings)),
  );
}
