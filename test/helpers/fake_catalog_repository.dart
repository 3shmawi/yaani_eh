import 'dart:async';

import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/domain/repositories/catalog_repository.dart';

import 'fake_catalog_remote.dart';

/// A scripted [CatalogRepository] for controller and screen tests.
class FakeCatalogRepository implements CatalogRepository {
  new({this.has = false, List<CatalogItem>? items})
    : itemsNow = items ?? sampleCatalogItems();

  bool has;
  List<CatalogItem> itemsNow;

  /// The next sync's outcome: null = success.
  AppFailure? failWith;

  /// Progress steps reported during a sync.
  List<SyncProgress> progress = const [
    SyncProgress(saved: 0, total: 12),
    SyncProgress(saved: 12, total: 12),
  ];

  /// Completes the sync when set (to inspect the in-between state).
  Completer<void>? gate;
  int syncCalls = 0;

  final _items = StreamController<List<CatalogItem>>.broadcast();

  @override
  Future<bool> hasCatalog() async => has;

  @override
  Future<Result<SyncReport>> sync({
    void Function(SyncProgress)? onProgress,
  }) async {
    syncCalls++;
    progress.forEach(onProgress ?? (_) {});
    await gate?.future;
    final failure = failWith;
    if (failure != null) return Failed(failure);
    final first = !has;
    has = true;
    _items.add(itemsNow);
    return Success(
      SyncReport(changed: 12, removed: 0, skipped: 0, firstSync: first),
    );
  }

  @override
  Stream<List<CatalogItem>> watchItems() async* {
    yield itemsNow;
    yield* _items.stream;
  }

  @override
  Stream<List<CatalogCategory>> watchCategories() async* {
    yield [for (final r in sampleCategories()) CatalogRows.category(r)!];
  }
}

List<CatalogItem> sampleCatalogItems() => [
  for (final r in sampleItems()) CatalogRows.item(r)!,
];
