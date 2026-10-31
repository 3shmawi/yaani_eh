import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_database.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_local_data_source.dart';

/// The menu as version 1 of the app stored it: no «يعني» columns.
const _v1 = '''
CREATE TABLE categories (
  id TEXT NOT NULL, parent_id TEXT, slug TEXT NOT NULL,
  name_ar TEXT NOT NULL, name_en TEXT NOT NULL, icon TEXT,
  trait_schema TEXT, sort_order INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (id));
CREATE TABLE items (
  id TEXT NOT NULL, category_id TEXT NOT NULL, slug TEXT NOT NULL,
  menu_name TEXT NOT NULL, menu_name_ar TEXT NOT NULL,
  explanation_ar TEXT NOT NULL, explanation_en TEXT NOT NULL,
  calories INTEGER, size_ml INTEGER, price_min_egp INTEGER,
  price_max_egp INTEGER, price_updated_at INTEGER, image_path TEXT,
  audio_barista_path TEXT, audio_original_path TEXT,
  traits TEXT NOT NULL DEFAULT '{}', sort_order INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (id));
CREATE TABLE item_terms (
  item_id TEXT NOT NULL, term TEXT NOT NULL, lang TEXT NOT NULL,
  kind TEXT NOT NULL, PRIMARY KEY (item_id, term, lang));
CREATE TABLE sync_meta (
  key TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY (key));
INSERT INTO items (id, category_id, slug, menu_name, menu_name_ar,
  explanation_ar, explanation_en)
  VALUES ('i1', 'c1', 'latte', 'Latte', 'لاتيه', 'قهوة بلبن.', 'Milky.');
INSERT INTO sync_meta VALUES ('cursor', '2026-10-01T00:00:00.000Z');
INSERT INTO sync_meta VALUES ('first_sync_done', 'true');
PRAGMA user_version = 1;
''';

void main() {
  test('upgrading from v1 keeps the menu and fetches it all again', () async {
    final db = CatalogDatabase(
      NativeDatabase.memory(
        setup: (raw) => _v1
            .split(';')
            .map((sql) => sql.trim())
            .where((sql) => sql.isNotEmpty)
            .forEach(raw.execute),
      ),
    );
    addTearDown(db.close);
    final local = CatalogLocalDataSource(db);

    final rows = await db.select(db.items).get();
    expect(rows.single.menuName, 'Latte');
    expect(rows.single.gistAr, isNull);
    // Offline right after the update, the menu still opens…
    expect(await local.firstSyncDone(), isTrue);
    // …and the next sync starts over, so every drink gets its line.
    expect(await local.cursor(), isNull);

    await db
        .update(db.items)
        .write(const ItemsCompanion(gistAr: Value('قهوة بلبن كتير')));
    expect((await db.select(db.items).getSingle()).gistAr, 'قهوة بلبن كتير');
  });
}
