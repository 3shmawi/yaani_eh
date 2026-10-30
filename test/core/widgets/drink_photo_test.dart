import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/widgets/drink_photo.dart';

import '../../helpers/pump_app.dart';

const _base = 'https://abc.supabase.co';
const _bucket = '$_base/storage/v1/object/public/item-images';
const _full = '$_bucket/latte.webp';
const _thumb = '$_bucket/latte.thumb.webp';

/// Serves files from memory, fails the URLs in [errors] and leaves every
/// other request loading. Records what was asked, in order.
class _FakeCache extends Fake implements BaseCacheManager {
  final requests = <String>[];
  final errors = <String, Object>{};
  final files = <String, Uint8List>{};
  final _pending = <StreamController<FileResponse>>[];
  final _fs = MemoryFileSystem();

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    requests.add(url);
    final error = errors[url];
    if (error != null) return Stream.error(error);
    final bytes = files[url];
    if (bytes != null) {
      final file = _fs.file('/${requests.length}.png')..writeAsBytesSync(bytes);
      return Stream.value(
        FileInfo(file, FileSource.Cache, DateTime(2100), url),
      );
    }
    final pending = StreamController<FileResponse>();
    _pending.add(pending);
    return pending.stream;
  }

  Future<void> closePending() async {
    for (final c in _pending) {
      await c.close();
    }
  }
}

const _notThere = HttpExceptionWithStatus(400, 'Object not found');
const _offline = SocketException('Failed host lookup');

Widget _photo(
  _FakeCache cache,
  PhotoSize size, {
  String? path = 'latte.webp',
  String baseUrl = _base,
  Key? key,
  Size box = const Size(120, 160),
}) => Center(
  child: SizedBox.fromSize(
    size: box,
    child: DrinkPhoto(
      key: key,
      name: 'Latte',
      imagePath: path,
      size: size,
      cacheManager: cache,
      baseUrl: baseUrl,
    ),
  ),
);

Iterable<CachedNetworkImage> _images(WidgetTester tester) =>
    tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage));

Iterable<String> _shown(WidgetTester tester) =>
    _images(tester).map((i) => i.imageUrl);

void main() {
  late _FakeCache cache;

  setUp(() {
    cache = _FakeCache();
    DrinkPhoto.resetKnownMissing();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  tearDown(() => cache.closePending());

  group('DrinkPhoto.decodeWidth', () {
    test('the box width in pixels for a 3:4 box or a wider one', () {
      expect(DrinkPhoto.decodeWidth(const Size(120, 160), 3), 360);
      expect(DrinkPhoto.decodeWidth(const Size(343, 190), 2), 686);
      expect(DrinkPhoto.decodeWidth(const Size(100.2, 50), 2), 201);
    });

    test('wider than the box when the box is taller than 3:4 (cover)', () {
      // 104×200 box: the photo is scaled to 200 high → 150 wide.
      expect(DrinkPhoto.decodeWidth(const Size(104, 200), 3), 450);
    });

    test('no finite size → decode as is', () {
      expect(DrinkPhoto.decodeWidth(Size.infinite, 3), isNull);
      expect(DrinkPhoto.decodeWidth(Size.zero, 3), isNull);
      expect(DrinkPhoto.decodeWidth(const Size(100, 100), 0), isNull);
      expect(DrinkPhoto.decodeWidth(const Size(100, double.infinity), 2), 200);
    });
  });

  group('cards (thumbnail)', () {
    testWidgets('load the thumbnail, decoded at display size', (tester) async {
      await tester.pumpApp(_photo(cache, PhotoSize.thumbnail));
      await tester.pump();

      expect(cache.requests, [_thumb]);
      final image = _images(tester).single;
      expect(image.imageUrl, _thumb);
      // 120 logical px × 3 (device pixel ratio). Width only: the photo
      // keeps its shape.
      expect(image.memCacheWidth, 360);
      expect(image.memCacheHeight, isNull);
      expect(image.cacheManager, same(cache));
      // The letter until it's there.
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('a missing thumbnail falls back to the full photo, and is '
        'not asked for again this session', (tester) async {
      cache.errors[_thumb] = _notThere;
      await tester.pumpApp(_photo(cache, PhotoSize.thumbnail));
      await tester.pump();
      await tester.pump();

      expect(cache.requests, [_thumb, _full]);
      expect(_shown(tester), contains(_full));
      expect(DrinkPhoto.isKnownMissing(_thumb), isTrue);

      // Another card for the same drink goes straight to the full photo.
      await tester.pumpApp(
        _photo(cache, PhotoSize.thumbnail, key: const Key('again')),
      );
      await tester.pump();
      expect(cache.requests.where((url) => url == _thumb), hasLength(1));
      expect(_shown(tester), [_full]);
    });

    testWidgets('offline: the cached full photo is used, and the thumbnail '
        'is asked for again once back online', (tester) async {
      cache.errors[_thumb] = _offline;
      await tester.pumpApp(_photo(cache, PhotoSize.thumbnail));
      await tester.pump();
      await tester.pump();

      expect(cache.requests, [_thumb, _full]);
      expect(DrinkPhoto.isKnownMissing(_thumb), isFalse);

      cache.errors.clear();
      PaintingBinding.instance.imageCache.clear();
      await tester.pumpApp(
        _photo(cache, PhotoSize.thumbnail, key: const Key('again')),
      );
      await tester.pump();
      expect(cache.requests.last, _thumb);
    });

    testWidgets('neither copy loads → the letter', (tester) async {
      cache.errors
        ..[_thumb] = _notThere
        ..[_full] = _offline;
      await tester.pumpApp(_photo(cache, PhotoSize.thumbnail));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(cache.requests, [_thumb, _full]);
      expect(find.text('L'), findsOneWidget);
    });
  });

  group('drink page (full)', () {
    testWidgets('loads the full photo and shows the thumbnail meanwhile', (
      tester,
    ) async {
      await tester.pumpApp(
        _photo(cache, PhotoSize.full, box: const Size(375, 420)),
      );
      await tester.pump();

      expect(cache.requests.first, _full);
      expect(cache.requests, contains(_thumb));
      final full = _images(tester).firstWhere((i) => i.imageUrl == _full);
      expect(full.memCacheWidth, 1125);
    });

    testWidgets('offline without the full photo cached → the thumbnail', (
      tester,
    ) async {
      cache.errors[_full] = _offline;
      await tester.pumpApp(_photo(cache, PhotoSize.full));
      await tester.pump();
      await tester.pump();

      // The error shows the thumbnail itself, not the loading preview.
      expect(find.byKey(const ValueKey(_thumb)), findsOneWidget);
      expect(find.byKey(const ValueKey('preview:$_thumb')), findsNothing);
    });
  });

  testWidgets('no photo, or no Supabase configured → the letter, no request', (
    tester,
  ) async {
    for (final size in PhotoSize.values) {
      await tester.pumpApp(_photo(cache, size, path: null));
      expect(find.text('L'), findsOneWidget);
      await tester.pumpApp(_photo(cache, size, baseUrl: ''));
      expect(find.text('L'), findsOneWidget);
    }
    expect(cache.requests, isEmpty);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('the photo is decoded at display size, not file size', (
    tester,
  ) async {
    // A 600×800 "photo" shown in a 50×66 box at 3× → decoded 150 wide.
    final png = (await tester.runAsync(() => _png(600, 800)))!;
    cache.files[_thumb] = png;
    await tester.pumpApp(
      _photo(cache, PhotoSize.thumbnail, box: const Size(50, 66)),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (_decoded(tester) != null) break;
      }
    });
    await tester.pump(const Duration(milliseconds: 300));

    final image = _decoded(tester);
    expect(image, isNotNull);
    expect(image!.width, 150);
    expect(image.height, 200);
  });
}

ui.Image? _decoded(WidgetTester tester) {
  tester.binding.scheduleFrame();
  final raw = find.byType(RawImage);
  if (raw.evaluate().isEmpty) return null;
  return tester.widget<RawImage>(raw.first).image;
}

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF8B5A2B),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
