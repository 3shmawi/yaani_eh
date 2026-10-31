import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/favorites/domain/entities/favorite.dart';
import 'package:yaani_eh/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';

/// Saved drinks in memory. [fail] makes every write fail (a full disk).
class FakeFavoritesRepository implements FavoritesRepository {
  new({Iterable<String> saved = const []}) {
    for (final (i, id) in saved.indexed) {
      _saved[id] = DateTime.utc(2026, 10, 1, 0, i);
    }
  }

  final _saved = <String, DateTime>{};
  final _changes = StreamController<void>.broadcast();
  AppFailure? fail;
  var _tick = 0;

  Set<String> get saved => _saved.keys.toSet();

  List<Favorite> _list() => [
    for (final MapEntry(:key, :value) in _saved.entries)
      Favorite(itemId: key, savedAt: value),
  ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Stream<List<Favorite>> watch() async* {
    yield _list();
    yield* _changes.stream.map((_) => _list());
  }

  @override
  Future<Result<void>> add(String itemId) async {
    if (fail case final failure?) return Failed(failure);
    _saved.putIfAbsent(itemId, () => DateTime.utc(2026, 10, 2, 0, _tick++));
    _changes.add(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> remove(String itemId) async {
    if (fail case final failure?) return Failed(failure);
    _saved.remove(itemId);
    _changes.add(null);
    return const Success(null);
  }
}

List<Override> favoritesOverrides(FakeFavoritesRepository repository) => [
  favoritesRepositoryProvider.overrideWithValue(repository),
];
