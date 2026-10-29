import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/domain/repositories/catalog_repository.dart';
import 'package:yaani_eh/features/catalog_sync/domain/usecases/sync_catalog.dart';

/// Override in tests: `catalogRepositoryProvider.overrideWithValue(fake)`.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => Dependencies.catalogRepository,
);

final catalogSyncControllerProvider =
    NotifierProvider<CatalogSyncController, CatalogSyncState>(
      CatalogSyncController.new,
    );

/// The menu on this device, for screens that list it.
final catalogItemsProvider = StreamProvider<List<CatalogItem>>(
  (ref) => WatchCatalog(ref.watch(catalogRepositoryProvider)).items(),
);

final catalogCategoriesProvider = StreamProvider<List<CatalogCategory>>(
  (ref) => WatchCatalog(ref.watch(catalogRepositoryProvider)).categories(),
);

/// What the app can show right now.
sealed class CatalogSyncState {
  const new();
}

/// Looking at the device (a moment at start-up).
final class CatalogChecking extends CatalogSyncState {
  const new();
}

/// First launch: downloading the menu.
final class CatalogFirstLoad extends CatalogSyncState {
  const new([this.progress]);

  /// Null until the server says how many items there are.
  final SyncProgress? progress;
}

/// Nothing on the device and the download failed; retried automatically.
final class CatalogUnavailable extends CatalogSyncState {
  const new(this.failure);

  final AppFailure failure;
}

/// The menu is on the device. Later syncs run quietly in the background;
/// when they fail, the offline banner speaks, not this state.
final class CatalogReady extends CatalogSyncState {
  const new();
}

/// Runs the sync: at start-up, when the app comes back to the foreground
/// (at most every [resumeThrottle]), and every [retryEvery] while there's
/// nothing to show.
class CatalogSyncController extends Notifier<CatalogSyncState> {
  static const retryEvery = Duration(seconds: 30);
  static const resumeThrottle = Duration(minutes: 2);

  Timer? _retry;
  AppLifecycleListener? _lifecycle;
  DateTime? _lastSync;
  Future<void>? _running;

  SyncCatalog get _sync => SyncCatalog(ref.read(catalogRepositoryProvider));

  @override
  CatalogSyncState build() {
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    ref.onDispose(() {
      _retry?.cancel();
      _lifecycle?.dispose();
    });
    unawaited(Future.microtask(_start));
    return const CatalogChecking();
  }

  Future<void> _start() async {
    final has = await _sync.hasCatalog();
    if (!ref.mounted) return;
    state = has ? const CatalogReady() : const CatalogFirstLoad();
    await sync();
  }

  void _onResume() {
    final last = _lastSync;
    if (last != null && DateTime.now().difference(last) < resumeThrottle) {
      return;
    }
    unawaited(sync());
  }

  /// Syncs now (joins a sync that's already running).
  Future<void> sync() =>
      _running ??= _run().whenComplete(() => _running = null);

  /// The retry button and "back online".
  Future<void> retry() {
    if (state is CatalogUnavailable) state = const CatalogFirstLoad();
    return sync();
  }

  Future<void> _run() async {
    _retry?.cancel();
    final first = state is! CatalogReady;
    final started = DateTime.now();
    final result = await _sync(
      onProgress: (progress) {
        if (ref.mounted && state is! CatalogReady) {
          state = CatalogFirstLoad(progress);
        }
      },
    );
    if (!ref.mounted) return;
    _lastSync = DateTime.now();
    switch (result) {
      case Success(:final value):
        state = const CatalogReady();
        unawaited(
          Analytics.capture('catalog_sync_completed', {
            'first': value.firstSync,
            'changed': value.changed,
            'removed': value.removed,
            'skipped': value.skipped,
            'duration_ms': DateTime.now().difference(started).inMilliseconds,
          }),
        );
      case Failed(:final failure):
        unawaited(
          Analytics.capture('catalog_sync_failed', {
            'first': first,
            'reason': failure.runtimeType.toString(),
          }),
        );
        if (first) {
          state = CatalogUnavailable(failure);
          _retry = Timer(retryEvery, () => unawaited(sync()));
        }
    }
  }
}
