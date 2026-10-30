import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/domain/repositories/catalog_repository.dart';

/// Brings the menu on this device up to date.
class SyncCatalog {
  const new(this._repository);

  final CatalogRepository _repository;

  Future<bool> hasCatalog() => _repository.hasCatalog();

  Future<Result<SyncReport>> call({void Function(SyncProgress)? onProgress}) =>
      _repository.sync(onProgress: onProgress);
}

/// The menu as stored on this device.
class WatchCatalog {
  const new(this._repository);

  final CatalogRepository _repository;

  Stream<List<CatalogItem>> items() => _repository.watchItems();

  Stream<List<CatalogCategory>> categories() => _repository.watchCategories();
}
