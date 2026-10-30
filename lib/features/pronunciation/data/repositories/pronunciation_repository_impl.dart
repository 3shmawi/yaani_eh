import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yaani_eh/core/backend/media.dart';
import 'package:yaani_eh/core/config/env.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/pronunciation/domain/repositories/pronunciation_repository.dart';

/// Clips from the public `item-audio` bucket through a device cache.
///
/// A fresh device copy is used as is. A stale one (past the bucket's
/// max-age) is checked again when online, and used as is when offline, so a
/// name heard once always plays.
class PronunciationRepositoryImpl implements PronunciationRepository {
  const new(
    this._cache, {
    this._baseUrl = Env.supabaseUrl,
    this._now = DateTime.now,
  });

  final BaseCacheManager _cache;
  final String _baseUrl;
  final DateTime Function() _now;

  @override
  Future<Result<String>> clipFile(String path) async {
    final url = MediaUrls.itemAudio(path, baseUrl: _baseUrl);
    if (url == null) return const Failed(NotFoundFailure());
    return await guard(
      () => _file(url),
      // A tap waits for this: one quick retry, then say so.
      retries: 1,
      timeout: const Duration(seconds: 15),
    );
  }

  Future<String> _file(String url) async {
    final cached = await _cache.getFileFromCache(url);
    if (cached != null && cached.validTill.isAfter(_now())) {
      return cached.file.path;
    }
    try {
      return (await _cache.downloadFile(url)).file.path;
    } on Object catch (error) {
      // The server says the clip isn't there (Supabase answers 400 or 404):
      // don't play a copy of something that was removed.
      final gone =
          error is HttpExceptionWithStatus &&
          error.statusCode >= 400 &&
          error.statusCode < 500;
      if (cached == null || gone) rethrow;
      return cached.file.path;
    }
  }

  @override
  Future<void> prefetch(Iterable<String> paths) async {
    for (final path in paths) {
      final url = MediaUrls.itemAudio(path, baseUrl: _baseUrl);
      if (url == null) continue;
      try {
        if (await _cache.getFileFromCache(url) == null) {
          await _cache.downloadFile(url);
        }
      } on Object {
        // Best effort: offline or missing now, fetched again on tap.
      }
    }
  }
}
