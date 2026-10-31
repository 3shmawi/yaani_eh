import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'favorites_database.g.dart';

/// Saved drinks on this device (SQLite via drift). Its own file, apart from
/// the menu copy, so a full menu resync never touches what the user saved.
@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get itemId => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemId};
}

@DriftDatabase(tables: [Favorites])
class FavoritesDatabase extends _$FavoritesDatabase {
  /// [executor] defaults to the app's on-device database; tests pass
  /// `NativeDatabase.memory()`.
  new([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'favorites'));

  @override
  int get schemaVersion => 1;
}
