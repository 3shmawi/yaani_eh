import 'package:yaani_eh/core/config/env.dart';

/// Which copy of a drink photo a screen shows.
enum PhotoSize {
  /// ~400 px wide, ~30–40 KB: cards (Home, search, similar drinks).
  thumbnail,

  /// 1200×1600, < 300 KB: the drink page.
  full,
}

/// Public URLs of catalog media in Supabase Storage (public buckets, read
/// by URL; see supabase/migrations/0002_catalog.sql).
abstract final class MediaUrls {
  /// A thumbnail sits next to its photo, with this ending instead of the
  /// photo's extension: `latte.webp` → `latte.thumb.webp`
  /// (docs/content.md → Photos).
  static const thumbnailSuffix = '.thumb.webp';

  /// A drink photo, or null when there's none (or no Supabase configured).
  static String? itemImage(String? path, {String baseUrl = Env.supabaseUrl}) =>
      _public('item-images', path, baseUrl);

  /// The thumbnail of a drink photo, or null (also when the photo's own
  /// path is refused).
  static String? itemThumbnail(
    String? path, {
    String baseUrl = Env.supabaseUrl,
  }) => itemImage(path, baseUrl: baseUrl) == null
      ? null
      : _public('item-images', thumbnailPath(path), baseUrl);

  /// The URLs to try for a drink photo, best first: the [size] asked for,
  /// then the other copy (a card falls back to the full photo when a
  /// thumbnail is missing; the drink page shows the cached thumbnail when
  /// the full photo can't load). Empty when there's no photo.
  static List<String> itemImageSources(
    String? path,
    PhotoSize size, {
    String baseUrl = Env.supabaseUrl,
  }) {
    final full = itemImage(path, baseUrl: baseUrl);
    final thumbnail = itemThumbnail(path, baseUrl: baseUrl);
    final ordered = size == PhotoSize.thumbnail
        ? [thumbnail, full]
        : [full, thumbnail];
    return ordered.nonNulls.toSet().toList();
  }

  /// `drinks/latte.webp` → `drinks/latte.thumb.webp` (any extension; a
  /// thumbnail path stays as it is). Null for no photo.
  static String? thumbnailPath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.endsWith(thumbnailSuffix)) return path;
    final slash = path.lastIndexOf('/');
    final dot = path.lastIndexOf('.');
    // A dot that starts the file name (`.webp`) isn't an extension.
    final stem = dot > slash + 1 ? path.substring(0, dot) : path;
    return '$stem$thumbnailSuffix';
  }

  /// A pronunciation clip, or null.
  static String? itemAudio(String? path, {String baseUrl = Env.supabaseUrl}) =>
      _public('item-audio', path, baseUrl);

  /// Null for no path, no Supabase, or a path that could leave the bucket
  /// (`..`, `.` or empty segments: URLs collapse them).
  static String? _public(String bucket, String? path, String baseUrl) {
    if (path == null || path.isEmpty || baseUrl.isEmpty) return null;
    final parts = path.split('/');
    if (parts.any((p) => p.isEmpty || p == '.' || p == '..')) return null;
    final segments = parts.map(Uri.encodeComponent).join('/');
    return '$baseUrl/storage/v1/object/public/$bucket/$segments';
  }
}
