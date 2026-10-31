import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/favorites/data/datasources/favorites_database.dart';
import 'package:yaani_eh/features/favorites/data/repositories/favorites_repository_impl.dart';

void main() {
  late FavoritesDatabase db;
  late FavoritesRepositoryImpl repository;
  var now = DateTime.utc(2026, 10, 31, 9);

  setUp(() {
    db = FavoritesDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 10, 31, 9);
    repository = FavoritesRepositoryImpl(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('nothing saved on a fresh install', () async {
    expect(await repository.watch().first, isEmpty);
  });

  test('saved drinks come newest first; removing one forgets it', () async {
    expect(await repository.add('a'), isA<Success<void>>());
    now = now.add(const Duration(minutes: 1));
    await repository.add('b');
    expect((await repository.watch().first).map((f) => f.itemId), ['b', 'a']);

    expect(await repository.remove('a'), isA<Success<void>>());
    expect((await repository.watch().first).map((f) => f.itemId), ['b']);
  });

  test('two saved in the same second: the last one comes first', () async {
    // Dates are stored to the second.
    await repository.add('a');
    now = now.add(const Duration(milliseconds: 400));
    await repository.add('b');
    expect((await repository.watch().first).map((f) => f.itemId), ['b', 'a']);
  });

  test('saving twice keeps the first date; removing twice is fine', () async {
    await repository.add('a');
    final first = (await repository.watch().first).single.savedAt;
    now = now.add(const Duration(days: 1));
    await repository.add('a');
    expect((await repository.watch().first).single.savedAt, first);

    await repository.remove('a');
    expect(await repository.remove('a'), isA<Success<void>>());
  });

  test('the stream follows every change', () async {
    final seen = <int>[];
    final sub = repository.watch().listen((f) => seen.add(f.length));
    await pumpEventQueue();
    await repository.add('a');
    await pumpEventQueue();
    await repository.add('b');
    await pumpEventQueue();
    await repository.remove('a');
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [0, 1, 2, 1]);
  });

  test('an id is stored as plain data, whatever it contains', () async {
    const sneaky = "x'); DROP TABLE favorites;--";
    await repository.add(sneaky);
    await repository.add('b');
    expect(
      (await repository.watch().first).map((f) => f.itemId),
      containsAll([sneaky, 'b']),
    );
  });
}
