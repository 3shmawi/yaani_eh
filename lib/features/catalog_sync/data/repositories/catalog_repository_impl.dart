import 'dart:async';
import 'dart:math' as math;

import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_local_data_source.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_remote_data_source.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/domain/repositories/catalog_repository.dart';

/// Offline-first catalog: everything is read from the device; [sync]
/// downloads what changed since the last sync.
///
/// How a sync works:
/// 1. `since` = the saved cursor minus [overlap] (rows committed late are
///    not missed; re-saving a row is harmless), or the epoch the first time.
/// 2. Categories, then items page by page with their search terms (items
///    and terms are saved together, terms replaced).
/// 3. Hidden / deleted rows (`catalog_removed_since`) are dropped.
/// 4. The cursor (newest `updated_at` seen) is saved last, so an interrupted
///    sync simply starts over from the same point.
class CatalogRepositoryImpl implements CatalogRepository {
  const new(
    this._remote,
    this._local, {
    this.pageSize = 100,
    this.overlap = const Duration(minutes: 2),
  });

  final CatalogRemoteDataSource _remote;
  final CatalogLocalDataSource _local;
  final int pageSize;
  final Duration overlap;

  static final _epoch = DateTime.utc(1970);

  @override
  Future<bool> hasCatalog() => _local.firstSyncDone();

  @override
  Future<Result<SyncReport>> sync({void Function(SyncProgress)? onProgress}) =>
      guard(() => _sync(onProgress), timeout: const Duration(minutes: 2));

  Future<SyncReport> _sync(void Function(SyncProgress)? onProgress) async {
    final cursor = await _local.cursor();
    final firstSync = !await _local.firstSyncDone();
    final since = cursor == null ? _epoch : cursor.subtract(overlap);
    var newest = cursor ?? _epoch;
    var skipped = 0;

    void seen(Object? row) {
      final at = CatalogRows.updatedAt(row);
      if (at != null && at.isAfter(newest)) newest = at;
    }

    // Categories.
    final categoryRows = await _remote.categories(since: since);
    final categories = <CatalogCategory>[];
    for (final row in categoryRows) {
      final category = CatalogRows.category(row);
      if (category == null) {
        skipped++;
      } else {
        categories.add(category);
        seen(row);
      }
    }
    await _local.saveCategories(categories);

    // Items, page by page.
    final total = await _remote.countItems(since: since);
    var saved = 0;
    onProgress?.call(SyncProgress(saved: 0, total: total));
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _remote.items(
        since: since,
        offset: offset,
        limit: pageSize,
      );
      final items = <CatalogItem>[];
      for (final row in rows) {
        final item = CatalogRows.item(row);
        if (item == null) {
          skipped++;
        } else {
          items.add(item);
          seen(row);
        }
      }
      final terms = <String, List<ItemTerm>>{};
      if (items.isNotEmpty) {
        final termRows = await _remote.terms(
          itemIds: [for (final i in items) i.id],
        );
        for (final row in termRows) {
          final parsed = CatalogRows.term(row);
          if (parsed == null) {
            skipped++;
          } else {
            (terms[parsed.$1] ??= []).add(parsed.$2);
          }
        }
      }
      await _local.saveItems(items, terms);
      saved += rows.length;
      onProgress?.call(
        SyncProgress(saved: saved, total: math.max(total, saved)),
      );
      if (rows.length < pageSize) break;
    }

    // Removals.
    final removedRows = await _remote.removed(since: since);
    final itemIds = <String>[];
    final categoryIds = <String>[];
    for (final row in removedRows) {
      final removed = CatalogRows.removed(row);
      if (removed == null) {
        skipped++;
      } else if (removed.kind == 'item') {
        itemIds.add(removed.id);
      } else {
        categoryIds.add(removed.id);
      }
    }
    await _local.remove(itemIds: itemIds, categoryIds: categoryIds);

    await _local.completeSync(newest);
    if (skipped > 0) {
      unawaited(
        Monitoring.captureException(
          FormatException('Catalog sync skipped $skipped malformed rows'),
          StackTrace.current,
        ),
      );
    }
    return SyncReport(
      changed: saved,
      removed: itemIds.length + categoryIds.length,
      skipped: skipped,
      firstSync: firstSync,
    );
  }

  @override
  Stream<List<CatalogItem>> watchItems() => _local.watchItems();

  @override
  Stream<List<CatalogCategory>> watchCategories() => _local.watchCategories();
}
