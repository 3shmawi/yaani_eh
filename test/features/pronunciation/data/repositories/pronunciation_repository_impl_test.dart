import 'dart:io' show SocketException;

import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/pronunciation/data/repositories/pronunciation_repository_impl.dart';

const _base = 'https://abc.supabase.co';
const _bucket = '$_base/storage/v1/object/public/item-audio';
final _now = DateTime(2026, 10, 30, 12);

/// The device cache: [stored] files with their expiry; downloads succeed
/// with fresh files unless [downloadError] is set.
class _FakeCache extends Fake implements BaseCacheManager {
  final _fs = MemoryFileSystem();
  final stored = <String, DateTime>{};
  final downloads = <String>[];
  Exception? downloadError;

  FileInfo _info(String url, DateTime validTill, FileSource source) => FileInfo(
    _fs.file('/cache/${url.hashCode}')..createSync(recursive: true),
    source,
    validTill,
    url,
  );

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    final validTill = stored[key];
    return validTill == null ? null : _info(key, validTill, FileSource.Cache);
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    downloads.add(url);
    if (downloadError case final error?) throw error;
    stored[url] = _now.add(const Duration(hours: 1));
    return _info(url, stored[url]!, FileSource.Online);
  }
}

void main() {
  late _FakeCache cache;
  late PronunciationRepositoryImpl repo;

  setUp(() {
    cache = _FakeCache();
    repo = PronunciationRepositoryImpl(cache, baseUrl: _base, now: () => _now);
  });

  Future<Result<String>> clip(String path) => repo.clipFile(path);

  group('clipFile', () {
    test('a fresh device copy plays without the network', () async {
      cache.stored['$_bucket/latte.m4a'] = _now.add(const Duration(days: 1));
      final result = await clip('latte.m4a');
      expect(result, isA<Success<String>>());
      expect(cache.downloads, isEmpty);
    });

    test('no copy → downloaded from the item-audio bucket', () async {
      final result = await clip('drinks/latte.m4a');
      expect(result, isA<Success<String>>());
      expect(cache.downloads, ['$_bucket/drinks/latte.m4a']);
    });

    test('a stale copy is checked again online', () async {
      cache.stored['$_bucket/latte.m4a'] = _now.subtract(
        const Duration(days: 1),
      );
      await clip('latte.m4a');
      expect(cache.downloads, ['$_bucket/latte.m4a']);
    });

    test('offline: a stale copy still plays', () async {
      cache
        ..stored['$_bucket/latte.m4a'] = _now.subtract(const Duration(days: 9))
        ..downloadError = const SocketException('offline');
      expect(await clip('latte.m4a'), isA<Success<String>>());
    });

    test('offline with no copy → NetworkFailure, after one retry', () async {
      cache.downloadError = const SocketException('offline');
      final result = await clip('latte.m4a');
      expect((result as Failed<String>).failure, isA<NetworkFailure>());
      expect(cache.downloads, hasLength(2));
    });

    test('a clip the server says is gone → NotFoundFailure, even with a '
        'stale copy, and no retry', () async {
      for (final status in [400, 404]) {
        cache
          ..downloads.clear()
          ..stored['$_bucket/latte.m4a'] = _now.subtract(
            const Duration(days: 1),
          )
          ..downloadError = HttpExceptionWithStatus(status, 'not found');
        final result = await clip('latte.m4a');
        expect((result as Failed<String>).failure, isA<NotFoundFailure>());
        expect(cache.downloads, hasLength(1));
      }
    });

    test('no Supabase configured → NotFoundFailure, no request', () async {
      // Tests run without an env file: no Supabase URL.
      final unconfigured = PronunciationRepositoryImpl(cache);
      final result = await unconfigured.clipFile('latte.m4a');
      expect((result as Failed<String>).failure, isA<NotFoundFailure>());
      expect(cache.downloads, isEmpty);
    });

    test('paths that could leave the bucket are refused, no request', () async {
      for (final path in ['../../auth/v1/admin', '/etc/x', 'a//b', './a']) {
        final result = await clip(path);
        expect(
          (result as Failed<String>).failure,
          isA<NotFoundFailure>(),
          reason: path,
        );
      }
      expect(cache.downloads, isEmpty);
    });

    test('other hostile paths stay inside the bucket (encoded: never a new '
        'host, query or fragment)', () async {
      const hostile = [
        'a.m4a?token=x#frag',
        "'; drop table items; --",
        '<script>alert(1)</script>',
        'https:/evil.example/x.m4a',
        '%2e%2e/x.m4a',
      ];
      for (final path in hostile) {
        await clip(path);
      }
      expect(cache.downloads, hasLength(hostile.length));
      for (final url in cache.downloads) {
        final uri = Uri.parse(url);
        expect(uri.host, 'abc.supabase.co', reason: url);
        expect(uri.hasQuery, isFalse, reason: url);
        expect(uri.hasFragment, isFalse, reason: url);
        expect(
          uri.path,
          startsWith('/storage/v1/object/public/item-audio/'),
          reason: url,
        );
      }
    });
  });

  group('prefetch', () {
    test('downloads only what is not on the device', () async {
      cache.stored['$_bucket/a.m4a'] = _now.subtract(const Duration(days: 1));
      await repo.prefetch(['a.m4a', 'b.m4a']);
      expect(cache.downloads, ['$_bucket/b.m4a']);
    });

    test('never fails (offline)', () async {
      cache.downloadError = const SocketException('offline');
      await expectLater(repo.prefetch(['a.m4a', 'b.m4a']), completes);
      expect(cache.downloads, hasLength(2));
    });

    test('nothing without Supabase', () async {
      await PronunciationRepositoryImpl(cache).prefetch(['a']);
      expect(cache.downloads, isEmpty);
    });
  });
}
