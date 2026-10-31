import 'package:drift/drift.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/favorites/data/datasources/favorites_database.dart';
import 'package:yaani_eh/features/favorites/domain/entities/favorite.dart';
import 'package:yaani_eh/features/favorites/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  new(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final FavoritesDatabase _db;
  final DateTime Function() _clock;

  @override
  Stream<List<Favorite>> watch() =>
      (_db.select(
        _db.favorites,
      )..orderBy([(f) => OrderingTerm.desc(f.savedAt)])).watch().map(
        (rows) => [
          for (final r in rows) Favorite(itemId: r.itemId, savedAt: r.savedAt),
        ],
      );

  /// Saving twice keeps the first date.
  @override
  Future<Result<void>> add(String itemId) => guard(
    () => _db
        .into(_db.favorites)
        .insert(
          FavoritesCompanion.insert(itemId: itemId, savedAt: _clock()),
          mode: InsertMode.insertOrIgnore,
        ),
    retries: 0,
  );

  @override
  Future<Result<void>> remove(String itemId) => guard(
    () =>
        (_db.delete(_db.favorites)..where((f) => f.itemId.equals(itemId))).go(),
    retries: 0,
  );
}
