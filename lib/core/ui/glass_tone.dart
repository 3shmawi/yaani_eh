import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Which glass tone a clear-glass control uses, like iOS 26: light glass
/// with dark content over bright photos, dark glass with white content
/// over dark ones.
enum GlassTone {
  /// Light over a photo area at or above [GlassToneResolver.threshold];
  /// follows the theme when there's no photo.
  auto,
  light,
  dark,
}

/// Reads how bright the photo is under a control, once per image, and
/// caches the answer by image and region.
abstract final class GlassToneResolver {
  /// Relative luminance at and above which the light tone is used.
  static const threshold = 0.40;

  /// Width the image is decoded at; plenty for an average brightness.
  static const _sampleWidth = 24;

  static final _cache = <(Object, Rect), GlassTone>{};

  /// The cached tone for [image] under [region], if already measured.
  static GlassTone? cached(ImageProvider image, Rect region) =>
      _cache[(image, region)];

  /// Measures the tone for [image] under [region] (fractions of the image:
  /// `Rect.fromLTWH(0, 0, 0.3, 0.2)` is the top-start corner). Falls back to
  /// [fallback] when the image can't be read.
  static Future<GlassTone> resolve(
    ImageProvider image,
    Rect region, {
    GlassTone fallback = GlassTone.dark,
  }) async {
    final key = (image, region);
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final small = ResizeImage(image, width: _sampleWidth);
      final decoded = await _load(small);
      final bytes = await decoded.toByteData();
      final tone = bytes == null
          ? fallback
          : toneFor(luminance(bytes, decoded.width, decoded.height, region));
      decoded.dispose();
      return _cache[key] = tone;
    } on Object {
      return fallback;
    }
  }

  static GlassTone toneFor(double luminance) =>
      luminance >= threshold ? GlassTone.light : GlassTone.dark;

  /// Relative luminance (WCAG) of the average color of [region] in an RGBA
  /// image — what a blur under the control would show.
  static double luminance(ByteData rgba, int width, int height, Rect region) {
    final left = (region.left.clamp(0, 1) * width).floor();
    final top = (region.top.clamp(0, 1) * height).floor();
    final right = math.max(left + 1, (region.right.clamp(0, 1) * width).ceil());
    final bottom = math.max(
      top + 1,
      (region.bottom.clamp(0, 1) * height).ceil(),
    );
    var r = 0.0;
    var g = 0.0;
    var b = 0.0;
    var n = 0;
    for (var y = top; y < math.min(bottom, height); y++) {
      for (var x = left; x < math.min(right, width); x++) {
        final i = (y * width + x) * 4;
        r += _linear(rgba.getUint8(i));
        g += _linear(rgba.getUint8(i + 1));
        b += _linear(rgba.getUint8(i + 2));
        n++;
      }
    }
    if (n == 0) return 0;
    return 0.2126 * r / n + 0.7152 * g / n + 0.0722 * b / n;
  }

  static double _linear(int channel) {
    final c = channel / 255;
    return c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static Future<ui.Image> _load(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        completer.complete(info.image.clone());
        info.dispose();
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        completer.completeError(error, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  @visibleForTesting
  static void clearCache() => _cache.clear();
}
