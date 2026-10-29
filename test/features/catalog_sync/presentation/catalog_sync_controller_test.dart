import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';

import '../../../helpers/fake_catalog_repository.dart';

void main() {
  late FakeCatalogRepository repository;
  late ProviderContainer container;

  ProviderContainer start() {
    container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    // Keep the controller alive like a mounted page does.
    container.listen(catalogSyncControllerProvider, (_, _) {});
    return container;
  }

  CatalogSyncState state() => container.read(catalogSyncControllerProvider);

  testWidgets('first launch: downloads with progress, then ready', (
    tester,
  ) async {
    repository = FakeCatalogRepository()..gate = Completer();
    start();
    expect(state(), isA<CatalogChecking>());

    await tester.pump();
    final loading = state();
    expect(loading, isA<CatalogFirstLoad>());
    expect(
      (loading as CatalogFirstLoad).progress,
      const SyncProgress(saved: 12, total: 12),
    );

    repository.gate!.complete();
    await tester.pump();
    expect(state(), isA<CatalogReady>());
  });

  testWidgets('with a catalog on the device: ready at once, syncs quietly', (
    tester,
  ) async {
    repository = FakeCatalogRepository(has: true)..gate = Completer();
    start();
    await tester.pump();
    expect(state(), isA<CatalogReady>());
    expect(repository.syncCalls, 1);
    repository.gate!.complete();
  });

  testWidgets('a failed background sync keeps the menu', (tester) async {
    repository = FakeCatalogRepository(has: true)
      ..failWith = const NetworkFailure();
    start();
    await tester.pump();
    expect(state(), isA<CatalogReady>());
  });

  testWidgets('first launch offline: unavailable, retries every 30 s', (
    tester,
  ) async {
    repository = FakeCatalogRepository()..failWith = const NetworkFailure();
    start();
    await tester.pump();
    final failed = state();
    expect(failed, isA<CatalogUnavailable>());
    expect((failed as CatalogUnavailable).failure, isA<NetworkFailure>());
    expect(repository.syncCalls, 1);

    await tester.pump(CatalogSyncController.retryEvery);
    expect(repository.syncCalls, 2);

    repository.failWith = null;
    await tester.pump(CatalogSyncController.retryEvery);
    await tester.pump();
    expect(state(), isA<CatalogReady>());
  });

  testWidgets('retry goes back to downloading', (tester) async {
    repository = FakeCatalogRepository()..failWith = const NetworkFailure();
    start();
    await tester.pump();
    expect(state(), isA<CatalogUnavailable>());

    repository
      ..failWith = null
      ..gate = Completer();
    unawaited(container.read(catalogSyncControllerProvider.notifier).retry());
    await tester.pump();
    expect(state(), isA<CatalogFirstLoad>());
    repository.gate!.complete();
    await tester.pump();
    expect(state(), isA<CatalogReady>());
  });

  testWidgets('two sync calls at once share one download', (tester) async {
    repository = FakeCatalogRepository(has: true)..gate = Completer();
    start();
    await tester.pump();
    final notifier = container.read(catalogSyncControllerProvider.notifier);
    unawaited(notifier.sync());
    unawaited(notifier.sync());
    await tester.pump();
    expect(repository.syncCalls, 1);
    repository.gate!.complete();
    await tester.pump();
  });

  testWidgets('coming back to the app syncs, at most every 2 minutes', (
    tester,
  ) async {
    repository = FakeCatalogRepository(has: true);
    start();
    await tester.pump();
    expect(repository.syncCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.syncCalls, 1, reason: 'synced moments ago');
  });

  testWidgets('the menu stream lists the items on the device', (tester) async {
    repository = FakeCatalogRepository(has: true);
    start();
    container
      ..listen(catalogItemsProvider, (_, _) {})
      ..listen(catalogCategoriesProvider, (_, _) {});
    await tester.pump();
    expect(container.read(catalogItemsProvider).value, hasLength(12));
    expect(container.read(catalogCategoriesProvider).value!.first.slug, 'cafe');
  });
}
