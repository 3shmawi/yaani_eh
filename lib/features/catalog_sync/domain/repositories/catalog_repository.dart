import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

/// The menu on this device, kept in sync with the server.
///
/// The first sync downloads everything; later ones only what changed since
/// the last one (including what was hidden or deleted). Everything is read
/// from the device, so the menu works offline.
abstract interface class CatalogRepository {
  /// Whether a first sync has completed on this device.
  Future<bool> hasCatalog();

  /// Downloads what changed. [onProgress] reports items saved / total.
  Future<Result<SyncReport>> sync({void Function(SyncProgress)? onProgress});

  /// Published items in visible categories, in menu order.
  Stream<List<CatalogItem>> watchItems();

  /// Sections and categories, in menu order.
  Stream<List<CatalogCategory>> watchCategories();
}
