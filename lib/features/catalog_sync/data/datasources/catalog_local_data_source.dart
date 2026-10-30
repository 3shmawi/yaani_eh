import 'package:drift/drift.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_database.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// Reads and writes the on-device copy of the catalog.
class CatalogLocalDataSource {
  const new(this._db);

  final CatalogDatabase _db;

  static const _cursorKey = 'cursor';
  static const _completeKey = 'first_sync_done';

  // Sync bookkeeping

  Future<DateTime?> cursor() async {
    final value = await _meta(_cursorKey);
    return value == null ? null : DateTime.tryParse(value)?.toUtc();
  }

  Future<bool> firstSyncDone() async => await _meta(_completeKey) == 'true';

  /// Saves the cursor and marks the first sync as done, together.
  Future<void> completeSync(DateTime cursor) => _db.transaction(() async {
    await _setMeta(_cursorKey, cursor.toUtc().toIso8601String());
    await _setMeta(_completeKey, 'true');
  });

  // Writes

  Future<void> saveCategories(List<CatalogCategory> categories) => _db.batch((
    b,
  ) {
    b.insertAllOnConflictUpdate(_db.categories, [
      for (final c in categories)
        CategoriesCompanion.insert(
          id: c.id,
          parentId: Value(c.parentId),
          slug: c.slug,
          nameAr: c.nameAr,
          nameEn: c.nameEn,
          icon: Value(c.icon),
          traitSchema: Value(
            c.traitSchema == null ? null : CatalogRows.encode(c.traitSchema),
          ),
          sortOrder: Value(c.sortOrder),
        ),
    ]);
  });

  /// Saves [items] and replaces their search terms with [terms].
  Future<void> saveItems(
    List<CatalogItem> items,
    Map<String, List<ItemTerm>> terms,
  ) => _db.transaction(() async {
    final ids = [for (final i in items) i.id];
    await (_db.delete(_db.itemTerms)..where((t) => t.itemId.isIn(ids))).go();
    await _db.batch((b) {
      b
        ..insertAllOnConflictUpdate(_db.items, [
          for (final i in items)
            ItemsCompanion.insert(
              id: i.id,
              categoryId: i.categoryId,
              slug: i.slug,
              menuName: i.menuName,
              menuNameAr: i.menuNameAr,
              explanationAr: i.explanationAr,
              explanationEn: i.explanationEn,
              calories: Value(i.calories),
              sizeMl: Value(i.sizeMl),
              priceMinEgp: Value(i.priceMinEgp),
              priceMaxEgp: Value(i.priceMaxEgp),
              priceUpdatedAt: Value(i.priceUpdatedAt),
              imagePath: Value(i.imagePath),
              audioBaristaPath: Value(i.audioBaristaPath),
              audioOriginalPath: Value(i.audioOriginalPath),
              traits: Value(CatalogRows.encode(i.traits)),
              sortOrder: Value(i.sortOrder),
            ),
        ])
        ..insertAll(_db.itemTerms, [
          for (final id in ids)
            for (final t in terms[id] ?? const <ItemTerm>[])
              ItemTermsCompanion.insert(
                itemId: id,
                term: t.term,
                lang: t.lang.name,
                kind: t.kind.name,
              ),
        ], mode: InsertMode.insertOrIgnore);
    });
  });

  /// Drops hidden or deleted rows (their terms go with the items).
  Future<void> remove({
    required List<String> itemIds,
    required List<String> categoryIds,
  }) => _db.transaction(() async {
    if (itemIds.isNotEmpty) {
      await (_db.delete(
        _db.itemTerms,
      )..where((t) => t.itemId.isIn(itemIds))).go();
      await (_db.delete(_db.items)..where((t) => t.id.isIn(itemIds))).go();
    }
    if (categoryIds.isNotEmpty) {
      await (_db.delete(
        _db.categories,
      )..where((t) => t.id.isIn(categoryIds))).go();
    }
  });

  // Reads

  /// Items whose category (and that category's section) are present.
  Stream<List<CatalogItem>> watchItems() {
    final category = _db.alias(_db.categories, 'c');
    final query =
        _db.select(_db.items).join([
            innerJoin(category, category.id.equalsExp(_db.items.categoryId)),
          ])
          ..where(
            category.parentId.isNull() |
                category.parentId.isInQuery(
                  _db.selectOnly(_db.categories)
                    ..addColumns([_db.categories.id]),
                ),
          )
          ..orderBy([
            OrderingTerm.asc(category.sortOrder),
            OrderingTerm.asc(_db.items.sortOrder),
            OrderingTerm.asc(_db.items.menuName),
          ]);
    return query.watch().asyncMap((rows) async {
      final items = [for (final r in rows) r.readTable(_db.items)];
      final terms = await _termsFor([for (final i in items) i.id]);
      return [for (final i in items) _item(i, terms[i.id] ?? const [])];
    });
  }

  Stream<List<CatalogCategory>> watchCategories() =>
      (_db.select(_db.categories)..orderBy([
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.nameEn),
          ]))
          .watch()
          .map((rows) => [for (final r in rows) _category(r)]);

  Future<Map<String, List<ItemTerm>>> _termsFor(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.itemTerms,
    )..where((t) => t.itemId.isIn(ids))).get();
    final out = <String, List<ItemTerm>>{};
    for (final r in rows) {
      final lang = TermLang.values.asNameMap()[r.lang];
      final kind = TermKind.values.asNameMap()[r.kind];
      if (lang == null || kind == null) continue;
      (out[r.itemId] ??= []).add(
        ItemTerm(term: r.term, lang: lang, kind: kind),
      );
    }
    return out;
  }

  CatalogItem _item(ItemRow r, List<ItemTerm> terms) {
    final traits = CatalogRows.decode(r.traits);
    return CatalogItem(
      id: r.id,
      categoryId: r.categoryId,
      slug: r.slug,
      menuName: r.menuName,
      menuNameAr: r.menuNameAr,
      explanationAr: r.explanationAr,
      explanationEn: r.explanationEn,
      calories: r.calories,
      sizeMl: r.sizeMl,
      priceMinEgp: r.priceMinEgp,
      priceMaxEgp: r.priceMaxEgp,
      priceUpdatedAt: r.priceUpdatedAt,
      imagePath: r.imagePath,
      audioBaristaPath: r.audioBaristaPath,
      audioOriginalPath: r.audioOriginalPath,
      traits: traits is Map<String, Object?> ? traits : const {},
      sortOrder: r.sortOrder,
      terms: terms,
    );
  }

  CatalogCategory _category(CategoryRow r) {
    final schema = CatalogRows.decode(r.traitSchema);
    return CatalogCategory(
      id: r.id,
      parentId: r.parentId,
      slug: r.slug,
      nameAr: r.nameAr,
      nameEn: r.nameEn,
      icon: r.icon,
      traitSchema: schema is List ? List<Object?>.of(schema) : null,
      sortOrder: r.sortOrder,
    );
  }

  Future<String?> _meta(String key) async {
    final row = await (_db.select(
      _db.syncMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _setMeta(String key, String value) => _db
      .into(_db.syncMeta)
      .insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
}
