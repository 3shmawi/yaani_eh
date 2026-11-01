import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'catalog_database.g.dart';

/// The menu on this device (SQLite via drift). Only published rows are
/// stored; the server is the source of truth and this is its offline copy.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get slug => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get icon => text().nullable()();

  /// JSON list (sections only).
  TextColumn get traitSchema => text().nullable()();

  /// Sections only: recipe | story | usage (see DetailKind).
  TextColumn get detailKind => text().nullable()();
  TextColumn get detailsTitleAr => text().nullable()();
  TextColumn get detailsTitleEn => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ItemRow')
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get slug => text()();
  TextColumn get menuName => text()();
  TextColumn get menuNameAr => text()();
  TextColumn get explanationAr => text()();
  TextColumn get explanationEn => text()();
  TextColumn get gistAr => text().nullable()();
  TextColumn get gistEn => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get audioSpokenPath => text().nullable()();
  TextColumn get audioOriginalPath => text().nullable()();

  /// JSON object.
  TextColumn get traits => text().withDefault(const Constant('{}'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// The section's kind of details, JSON in the server's shape
  /// (`{kind, …}`).
  TextColumn get details => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ItemTermRow')
class ItemTerms extends Table {
  TextColumn get itemId => text()();
  TextColumn get term => text()();
  TextColumn get lang => text()();
  TextColumn get kind => text()();

  @override
  Set<Column<Object>> get primaryKey => {itemId, term, lang};
}

/// Key/value sync bookkeeping (the cursor, first-sync done).
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Categories, Items, ItemTerms, SyncMeta])
class CatalogDatabase extends _$CatalogDatabase {
  /// [executor] defaults to the app's on-device database; tests pass
  /// `NativeDatabase.memory()`.
  new([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'catalog'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS items_category ON items (category_id)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // The «يعني» line. Rows already on the phone don't have it, so the
        // next sync starts over and fetches every drink again.
        await m.addColumn(items, items.gistAr);
        await m.addColumn(items, items.gistEn);
        await (delete(syncMeta)..where((r) => r.key.equals('cursor'))).go();
      }
      if (from < 3) {
        // «طريقة التحضير»: the same, so every drink comes back with it.
        // (The column is gone since v4; this only matters when coming
        // from v2, and the v4 step below rebuilds the table anyway.)
        await customStatement('ALTER TABLE items ADD COLUMN recipe TEXT');
        await (delete(syncMeta)..where((r) => r.key.equals('cursor'))).go();
      }
      if (from < 4) {
        // Generic items: details (any kind) instead of recipe, the spoken
        // clip, calories/size in traits, no prices. The table is rebuilt
        // with the old values moved over, so the offline copy keeps its
        // recipes; the next sync then fetches everything again.
        await m.alterTable(
          TableMigration(
            items,
            columnTransformer: {
              items.details: const CustomExpression<String>(
                'CASE WHEN recipe IS NULL THEN NULL '
                r"ELSE json_set(recipe, '$.kind', 'recipe') END",
              ),
              items.audioSpokenPath: const CustomExpression<String>(
                'audio_barista_path',
              ),
              items.traits: const CustomExpression<String>(
                'json_patch(traits, json_object( '
                "'calories', calories, 'size_ml', size_ml))",
              ),
            },
          ),
        );
        await m.addColumn(categories, categories.detailKind);
        await m.addColumn(categories, categories.detailsTitleAr);
        await m.addColumn(categories, categories.detailsTitleEn);
        await (delete(syncMeta)..where((r) => r.key.equals('cursor'))).go();
      }
    },
  );
}
