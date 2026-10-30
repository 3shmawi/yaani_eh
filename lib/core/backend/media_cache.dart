import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// The on-device copy of drink photos and thumbnails, so the menu keeps its
/// pictures offline. Kept longer and bigger than the package default
/// (30 days, 200 files): a thumbnail and a photo per drink, and a café
/// visit can be months after the last one. Least recently used files go
/// first. A file past its HTTP max-age is checked again when online; offline
/// the stored copy is used.
class MediaCache extends CacheManager with ImageCacheManager {
  new _()
    : super(
        Config(key, stalePeriod: stalePeriod, maxNrOfCacheObjects: maxFiles),
      );

  static const key = 'yaanieh_media';
  static const stalePeriod = Duration(days: 180);
  static const maxFiles = 600;

  static final MediaCache instance = MediaCache._();
}
