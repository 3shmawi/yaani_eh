import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_database.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_local_data_source.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/data/repositories/catalog_repository_impl.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

import '../../../../helpers/fake_catalog_remote.dart';

void main() {
  late CatalogDatabase db;
  late FakeCatalogRemote remote;
  late CatalogRepositoryImpl repository;

  setUp(() {
    db = CatalogDatabase(NativeDatabase.memory());
    remote = FakeCatalogRemote();
    remote.termRows.addAll([
      {'item_id': fakeId(5), 'term': 'لبن', 'lang': 'ar', 'kind': 'ingredient'},
      {'item_id': fakeId(5), 'term': 'latte', 'lang': 'en', 'kind': 'name'},
      {'item_id': fakeId(5), 'term': 'laban w ahwa', 'lang': 'franco'},
    ]);
    // Small pages, so paging is exercised.
    repository = CatalogRepositoryImpl(
      remote,
      CatalogLocalDataSource(db),
      pageSize: 5,
      overlap: Duration.zero,
    );
  });

  tearDown(() => db.close());

  Future<SyncReport> syncOk({void Function(SyncProgress)? onProgress}) async {
    final result = await repository.sync(onProgress: onProgress);
    return switch (result) {
      Success(:final value) => value,
      Failed(:final failure) => fail('sync failed: $failure'),
    };
  }

  test('a fresh install has no catalog', () async {
    expect(await repository.hasCatalog(), isFalse);
  });

  test('the first sync downloads everything and reports progress', () async {
    final progress = <SyncProgress>[];
    final report = await syncOk(onProgress: progress.add);

    expect(report.firstSync, isTrue);
    expect(report.changed, 12);
    expect(await repository.hasCatalog(), isTrue);
    expect(progress.first, const SyncProgress(saved: 0, total: 12));
    expect(progress.last, const SyncProgress(saved: 12, total: 12));
    expect(remote.itemPageCalls, 3); // 5 + 5 + 2

    final items = await repository.watchItems().first;
    expect(items, hasLength(12));
    expect(items.first.menuName, 'Espresso'); // coffee before iced coffee
    final latte = items.firstWhere((i) => i.slug == 'latte');
    expect(latte.terms, hasLength(3));
    expect(latte.traits['temp'], 'hot');

    final categories = await repository.watchCategories().first;
    expect(categories.map((c) => c.slug), containsAll(['cafe', 'coffee']));
    expect(
      categories.firstWhere((c) => c.slug == 'cafe').traitSchema,
      isNotEmpty,
    );
  });

  test('the «يعني» line reaches the device', () async {
    await syncOk();
    final items = await repository.watchItems().first;
    final espresso = items.firstWhere((i) => i.slug == 'espresso');
    expect(espresso.gistAr, 'فنجان قهوة صغير ومركّز');
    expect(espresso.gistEn, 'A tiny, strong cup of coffee');
    expect(items.firstWhere((i) => i.slug == 'latte').gistAr, isNull);
  });

  test('«طريقة التحضير» reaches the device', () async {
    await syncOk();
    final items = await repository.watchItems().first;
    final recipe = items.firstWhere((i) => i.slug == 'flat_white').recipe!;
    expect(recipe, CatalogRows.recipe(sampleRecipes['flat_white']));
    expect(items.firstWhere((i) => i.slug == 'latte').recipe, isNull);
  });

  test('later syncs only download what changed', () async {
    await syncOk();
    remote.itemPageCalls = 0;
    remote.itemRows[4]
      ..['explanation_en'] = 'Updated latte text'
      ..['updated_at'] = '2026-10-20T09:00:00Z';

    final report = await syncOk();

    expect(report.firstSync, isFalse);
    expect(report.changed, 1);
    final latte = (await repository.watchItems().first).firstWhere(
      (i) => i.slug == 'latte',
    );
    expect(latte.explanationEn, 'Updated latte text');
  });

  test('rows committed just before the cursor are fetched again', () async {
    await syncOk();
    final withOverlap = CatalogRepositoryImpl(
      remote,
      CatalogLocalDataSource(db),
    );
    final again = await withOverlap.sync();
    // All sample rows are within 2 minutes of the newest: re-saved, harmless.
    expect((again as Success<SyncReport>).value.changed, 12);
    expect(await repository.watchItems().first, hasLength(12));
  });

  test('changed search terms replace the old ones', () async {
    await syncOk();
    remote.termRows
      ..clear()
      ..add({'item_id': fakeId(5), 'term': 'caffe latte', 'lang': 'en'});
    remote.itemRows[4]['updated_at'] = '2026-10-20T09:00:00Z';

    await syncOk();

    final latte = (await repository.watchItems().first).firstWhere(
      (i) => i.slug == 'latte',
    );
    expect(latte.terms.map((t) => t.term), ['caffe latte']);
  });

  test('hidden and deleted items disappear', () async {
    await syncOk();
    remote.itemRows[0]
      ..['is_published'] = false
      ..['updated_at'] = '2026-10-20T09:00:00Z';
    remote.removedRows.add({'kind': 'item', 'id': fakeId(2)});

    final report = await syncOk();

    expect(report.removed, 2);
    final slugs = (await repository.watchItems().first).map((i) => i.slug);
    expect(slugs, isNot(contains('espresso')));
    expect(slugs, isNot(contains('cortado')));
    expect(slugs, hasLength(10));
  });

  test('a hidden category hides its items', () async {
    await syncOk();
    remote.removedRows.add({'kind': 'category', 'id': coldId});

    await syncOk();

    final items = await repository.watchItems().first;
    expect(items.where((i) => i.categoryId == coldId), isEmpty);
    expect(items, hasLength(8));
  });

  test('offline: the sync fails without touching the catalog', () async {
    await syncOk();
    remote.online = false;

    final result = await CatalogRepositoryImpl(
      remote,
      CatalogLocalDataSource(db),
    ).sync();

    expect(result, isA<Failed<SyncReport>>());
    expect((result as Failed).failure, isA<NetworkFailure>());
    expect(await repository.watchItems().first, hasLength(12));
    expect(await repository.hasCatalog(), isTrue);
  });

  test('an interrupted first sync is not counted as done', () async {
    remote.itemRows.add({'id': 'boom'}); // fine: skipped
    var calls = 0;
    final flaky = _FailingAfter(remote, () => ++calls > 1);

    final result = await CatalogRepositoryImpl(
      flaky,
      CatalogLocalDataSource(db),
      pageSize: 5,
    ).sync();

    expect(result, isA<Failed<SyncReport>>());
    expect(await repository.hasCatalog(), isFalse);
  });

  group('hostile or broken rows are skipped, never crash', () {
    test('wrong types, missing fields, absurd values', () async {
      remote.itemRows.addAll([
        {'id': fakeId(90), 'slug': 'no_category'},
        {
          ...remote.itemRows.first,
          'id': fakeId(91),
          'slug': 'Robert"); DROP TABLE items;--',
        },
        {...remote.itemRows.first, 'id': fakeId(92), 'calories': 'many'},
        {...remote.itemRows.first, 'id': fakeId(93), 'calories': -50},
        {...remote.itemRows.first, 'id': fakeId(94), 'menu_name': 'x' * 500},
        {...remote.itemRows.first, 'id': fakeId(95), 'traits': 'not a map'},
        {
          ...remote.itemRows.first,
          'id': fakeId(96),
          'price_min_egp': 200,
          'price_max_egp': 100,
        },
        {
          ...remote.itemRows.first,
          'id': fakeId(97),
          'image_path': '../../etc/passwd',
          'slug': 'path_attack',
        },
      ]);
      remote.termRows.add({'item_id': fakeId(1), 'term': 42, 'lang': 'en'});
      remote.removedRows.add({'kind': 'table', 'id': 'drop'});

      final report = await syncOk();

      expect(report.skipped, greaterThanOrEqualTo(9));
      final items = await repository.watchItems().first;
      expect(items, hasLength(13)); // 12 + the path attack, without its path
      final attack = items.firstWhere((i) => i.slug == 'path_attack');
      expect(attack.imagePath, isNull);
    });
  });
}

/// Fails every remote call once [shouldFail] says so (mid-download).
class _FailingAfter extends FakeCatalogRemote {
  new(FakeCatalogRemote base, this.shouldFail)
    : super(categories: base.categoryRows, items: base.itemRows);

  final bool Function() shouldFail;

  @override
  Future<List<Object?>> items({
    required DateTime since,
    required int offset,
    required int limit,
  }) {
    if (shouldFail()) online = false;
    return super.items(since: since, offset: offset, limit: limit);
  }
}
