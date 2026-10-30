import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/pronunciation/domain/entities/pronunciation.dart';

/// The clips an item has, barista first (the one cards play). A missing or
/// empty path has no clip, so its button is hidden.
class ClipsFor {
  const new();

  List<Clip> call(CatalogItem item) => [
    if (_usable(item.audioBaristaPath) case final path?)
      Clip(voice: Voice.barista, path: path),
    if (_usable(item.audioOriginalPath) case final path?)
      Clip(voice: Voice.original, path: path),
  ];

  /// The clip for [voice], or null.
  Clip? voice(CatalogItem item, Voice voice) {
    for (final clip in call(item)) {
      if (clip.voice == voice) return clip;
    }
    return null;
  }

  static String? _usable(String? path) {
    final trimmed = path?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
