import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/backend/media.dart';

/// Media paths come from the database (photos, pronunciation clips). Even
/// if a bad path got past the catalog parser, it must never reach another
/// Storage path, another host, or add a query.
void main() {
  const base = 'https://abc.supabase.co';
  const traversal = [
    '..',
    '../x',
    'a/../../auth/v1/admin',
    './x',
    '/x',
    'a//b',
    'x/',
    'https://evil.example/x',
  ];
  const hostile = [
    'a.m4a?token=x#frag',
    "'; drop table items; --",
    '<script>alert(1)</script>',
    'https:/evil.example/x',
    '%2e%2e/x',
    '\u202Egnp.exe',
    'لاتيه.m4a',
  ];

  final builders = <String, String? Function(String)>{
    'item-images': (p) => MediaUrls.itemImage(p, baseUrl: base),
    'item-images (thumbnail)': (p) => MediaUrls.itemThumbnail(p, baseUrl: base),
    'item-audio': (p) => MediaUrls.itemAudio(p, baseUrl: base),
  };

  for (final MapEntry(key: name, value: url) in builders.entries) {
    test('$name: traversal-like paths give no URL', () {
      for (final path in traversal) {
        expect(url(path), isNull, reason: path);
      }
    });

    test('$name: other hostile paths stay in the bucket', () {
      final bucket = name.split(' ').first;
      for (final path in hostile) {
        final uri = Uri.parse(url(path)!);
        expect(uri.host, 'abc.supabase.co', reason: path);
        expect(uri.scheme, 'https', reason: path);
        expect(uri.hasQuery || uri.hasFragment, isFalse, reason: path);
        expect(
          uri.pathSegments.take(5).join('/'),
          'storage/v1/object/public/$bucket',
          reason: path,
        );
      }
    });
  }
}
