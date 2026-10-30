import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// The on-device copy of pronunciation clips (a few KB each), so a name
/// heard once — or prefetched on its drink page — plays offline. Kept a
/// year after last use; least recently used go first past [maxFiles].
class AudioCache extends CacheManager {
  new _()
    : super(
        Config(key, stalePeriod: stalePeriod, maxNrOfCacheObjects: maxFiles),
      );

  static const key = 'yaanieh_audio';
  static const stalePeriod = Duration(days: 365);
  static const maxFiles = 400;

  static final AudioCache instance = AudioCache._();
}
