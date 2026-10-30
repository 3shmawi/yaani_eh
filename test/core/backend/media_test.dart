import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/backend/media.dart';

const _base = 'https://abc.supabase.co';
const _bucket = '$_base/storage/v1/object/public/item-images';

void main() {
  group('MediaUrls.thumbnailPath', () {
    test('sits next to the photo with .thumb.webp', () {
      expect(MediaUrls.thumbnailPath('latte.webp'), 'latte.thumb.webp');
      expect(
        MediaUrls.thumbnailPath('cafe/iced/latte.webp'),
        'cafe/iced/latte.thumb.webp',
      );
    });

    test('is always WebP, whatever the photo is', () {
      expect(MediaUrls.thumbnailPath('latte.jpg'), 'latte.thumb.webp');
      expect(MediaUrls.thumbnailPath('latte.PNG'), 'latte.thumb.webp');
      expect(MediaUrls.thumbnailPath('latte'), 'latte.thumb.webp');
    });

    test('only the last extension of the file name goes', () {
      expect(
        MediaUrls.thumbnailPath('flat.white.webp'),
        'flat.white.thumb.webp',
      );
      // A dot in a folder name isn't the file's extension.
      expect(MediaUrls.thumbnailPath('v1.2/latte'), 'v1.2/latte.thumb.webp');
      // A file name that starts with a dot has no extension.
      expect(MediaUrls.thumbnailPath('.webp'), '.webp.thumb.webp');
    });

    test('a thumbnail path stays as it is', () {
      expect(MediaUrls.thumbnailPath('latte.thumb.webp'), 'latte.thumb.webp');
    });

    test('no photo, no thumbnail', () {
      expect(MediaUrls.thumbnailPath(null), isNull);
      expect(MediaUrls.thumbnailPath(''), isNull);
    });
  });

  group('MediaUrls URLs', () {
    test('full photo and thumbnail in the public item-images bucket', () {
      expect(
        MediaUrls.itemImage('latte.webp', baseUrl: _base),
        '$_bucket/latte.webp',
      );
      expect(
        MediaUrls.itemThumbnail('latte.webp', baseUrl: _base),
        '$_bucket/latte.thumb.webp',
      );
    });

    test('each path segment is encoded; folders are kept', () {
      expect(
        MediaUrls.itemThumbnail('my drinks/لاتيه?x=1#a.webp', baseUrl: _base),
        '$_bucket/my%20drinks/'
        '${Uri.encodeComponent('لاتيه')}%3Fx%3D1%23a.thumb.webp',
      );
    });

    test('no Supabase configured or no photo → no URL', () {
      // Tests run without an env file: the default base URL is empty.
      expect(MediaUrls.itemImage('latte.webp'), isNull);
      expect(MediaUrls.itemThumbnail('latte.webp'), isNull);
      expect(MediaUrls.itemImage(null, baseUrl: _base), isNull);
      expect(MediaUrls.itemThumbnail('', baseUrl: _base), isNull);
    });

    test('audio uses its own bucket', () {
      expect(
        MediaUrls.itemAudio('latte.m4a', baseUrl: _base),
        '$_base/storage/v1/object/public/item-audio/latte.m4a',
      );
    });
  });

  group('MediaUrls.itemImageSources', () {
    test('cards: thumbnail first, then the full photo', () {
      expect(
        MediaUrls.itemImageSources(
          'latte.webp',
          PhotoSize.thumbnail,
          baseUrl: _base,
        ),
        ['$_bucket/latte.thumb.webp', '$_bucket/latte.webp'],
      );
    });

    test('drink page: full photo first, then the thumbnail', () {
      expect(
        MediaUrls.itemImageSources(
          'latte.webp',
          PhotoSize.full,
          baseUrl: _base,
        ),
        ['$_bucket/latte.webp', '$_bucket/latte.thumb.webp'],
      );
    });

    test('a path that is already a thumbnail is tried once', () {
      expect(
        MediaUrls.itemImageSources(
          'latte.thumb.webp',
          PhotoSize.full,
          baseUrl: _base,
        ),
        ['$_bucket/latte.thumb.webp'],
      );
    });

    test('nothing to try without a photo or Supabase', () {
      for (final size in PhotoSize.values) {
        expect(MediaUrls.itemImageSources(null, size, baseUrl: _base), isEmpty);
        expect(MediaUrls.itemImageSources('a.webp', size), isEmpty);
      }
    });
  });
}
