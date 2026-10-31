import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/favorites/domain/entities/favorite.dart';

/// The drinks saved on this phone. No account and no server: they work
/// offline and stay until the user removes them or the app is deleted.
abstract interface class FavoritesRepository {
  /// Every saved drink, newest first; emits again on every change.
  Stream<List<Favorite>> watch();

  Future<Result<void>> add(String itemId);

  Future<Result<void>> remove(String itemId);
}
