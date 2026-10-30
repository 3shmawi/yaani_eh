import 'package:yaani_eh/core/config/env.dart';

/// Public URLs of catalog media in Supabase Storage (public buckets, read
/// by URL; see supabase/migrations/0002_catalog.sql).
abstract final class MediaUrls {
  /// A drink photo, or null when there's none (or no Supabase configured).
  static String? itemImage(String? path) => _public('item-images', path);

  /// A pronunciation clip, or null.
  static String? itemAudio(String? path) => _public('item-audio', path);

  static String? _public(String bucket, String? path) {
    if (path == null || path.isEmpty || Env.supabaseUrl.isEmpty) return null;
    final segments = path.split('/').map(Uri.encodeComponent).join('/');
    return '${Env.supabaseUrl}/storage/v1/object/public/$bucket/$segments';
  }
}
