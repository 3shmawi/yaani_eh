import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/browse/presentation/browse_view.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronounce.dart';

/// Home: wires the section cards to [BrowseView].
class BrowsePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => BrowseView(
    hub: ref.watch(hubProvider),
    onOpenSection: (section) {
      trackSectionOpened(section);
      unawaited(context.push<void>(AppRoutes.section(section.section.slug)));
    },
    onOpenSearch: () => unawaited(context.push<void>(AppRoutes.search)),
    onOpenItem: (item) =>
        unawaited(context.push<void>(AppRoutes.item(item.slug))),
    cardAction: (item) => ItemPlayButton(item: item),
  );
}
