import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_view.dart';

/// Shows [child] (the menu) once the catalog is on the device; until then,
/// the first-launch download or its error. Also retries as soon as the
/// connection comes back.
class CatalogSyncPage extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<CatalogSyncPage> createState() => _CatalogSyncPageState();
}

class _CatalogSyncPageState extends ConsumerState<CatalogSyncPage> {
  /// One tip per launch.
  final int _tip = DateTime.now().day;
  NetworkState? _network;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final network = ConnectionScope.of(context);
    final cameBack =
        _network == NetworkState.offline && network != NetworkState.offline;
    _network = network;
    if (cameBack &&
        ref.read(catalogSyncControllerProvider) is CatalogUnavailable) {
      unawaited(ref.read(catalogSyncControllerProvider.notifier).retry());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogSyncControllerProvider);
    final controller = ref.read(catalogSyncControllerProvider.notifier);
    return switch (state) {
      // A blank surface for the instant it takes to look at the device.
      CatalogChecking() => ColoredBox(color: context.palette.surface),
      CatalogReady() => widget.child,
      CatalogFirstLoad(:final progress) => CatalogSyncView(
        progress: progress,
        failure: null,
        tipIndex: _tip,
        onRetry: () => unawaited(controller.retry()),
      ),
      CatalogUnavailable(:final failure) => CatalogSyncView(
        progress: null,
        failure: failure,
        tipIndex: _tip,
        onRetry: () => unawaited(controller.retry()),
      ),
    };
  }
}
