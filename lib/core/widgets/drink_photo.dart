import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yaani_eh/core/backend/media.dart';
import 'package:yaani_eh/core/backend/media_cache.dart';
import 'package:yaani_eh/core/config/env.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';

export 'package:yaani_eh/core/backend/media.dart' show PhotoSize;

/// A drink photo filling its box, cached on the device after the first
/// view (works offline from then on). Cards ask for the [PhotoSize.thumbnail]
/// and fall back to the full photo when the thumbnail is missing; the drink
/// page asks for the [PhotoSize.full] photo, shows the thumbnail while it
/// loads and when it can't load. Decoded at the size it's shown, not the
/// file's. No photo, or nothing loaded yet: the brand gradient with the
/// drink's first letter. Decorative for screen readers; the name is always
/// in text next to it.
class DrinkPhoto extends StatelessWidget {
  const new({
    required this.name,
    required this.size,
    this.imagePath,
    this.cacheManager,
    this.baseUrl = Env.supabaseUrl,
    super.key,
  });

  final String name;

  /// Path of the full photo in the `item-images` bucket.
  final String? imagePath;

  final PhotoSize size;

  /// Defaults to [MediaCache.instance]; tests pass a fake.
  final BaseCacheManager? cacheManager;

  /// The Supabase URL; tests pass one (CI has no env file).
  final String baseUrl;

  /// Drink photos are 3:4 (docs/content.md → Photos).
  static const double aspectRatio = 3 / 4;

  /// The width in pixels to decode a 3:4 photo at so it covers a [box] of
  /// logical pixels without blur: the box's width, or more when the box is
  /// taller than 3:4. Only the width is given so the photo keeps its shape;
  /// a photo is never decoded larger than its file. Null when the box has
  /// no finite size (decode as is).
  static int? decodeWidth(Size box, double devicePixelRatio) {
    final fromWidth = box.width.isFinite ? box.width : 0.0;
    final fromHeight = box.height.isFinite ? box.height * aspectRatio : 0.0;
    final logical = math.max(fromWidth, fromHeight);
    if (logical <= 0 || devicePixelRatio <= 0) return null;
    return (logical * devicePixelRatio).ceil();
  }

  /// URLs that answered "not there" (4xx) this session, so cards whose
  /// thumbnail isn't uploaded yet go straight to the full photo instead of
  /// asking again on every scroll. Network errors (offline) aren't kept.
  static final Set<String> _missing = {};

  /// Whether [url] answered "not there" this session.
  static bool isKnownMissing(String url) => _missing.contains(url);

  /// Remembers [url] as missing when [error] is a 4xx answer.
  @visibleForTesting
  static void noteError(String url, Object error) {
    if (error is HttpExceptionWithStatus &&
        error.statusCode >= 400 &&
        error.statusCode < 500) {
      _missing.add(url);
    }
  }

  @visibleForTesting
  static void resetKnownMissing() => _missing.clear();

  @override
  Widget build(BuildContext context) {
    final fallback = _Fallback(name: name);
    final sources = MediaUrls.itemImageSources(
      imagePath,
      size,
      baseUrl: baseUrl,
    ).where((url) => !isKnownMissing(url)).toList();
    if (sources.isEmpty) return ExcludeSemantics(child: fallback);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => _Sources(
          urls: sources,
          decodeWidth: decodeWidth(
            constraints.biggest,
            MediaQuery.devicePixelRatioOf(context),
          ),
          cacheManager: cacheManager ?? MediaCache.instance,
          // A big photo shows its (likely cached) thumbnail while loading;
          // a thumbnail never waits on the big photo.
          previewWhileLoading: size == PhotoSize.full,
          fallback: fallback,
        ),
      ),
    );
  }
}

/// Tries [urls] in order: each one's error shows the next; after the last,
/// the [fallback].
class _Sources extends StatelessWidget {
  const new({
    required this.urls,
    required this.decodeWidth,
    required this.cacheManager,
    required this.previewWhileLoading,
    required this.fallback,
  });

  final List<String> urls;
  final int? decodeWidth;
  final BaseCacheManager cacheManager;
  final bool previewWhileLoading;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => _source(0);

  Widget _source(int i) {
    if (i >= urls.length) return fallback;
    final url = urls[i];
    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      cacheManager: cacheManager,
      memCacheWidth: decodeWidth,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) =>
          previewWhileLoading && i == 0 ? _preview(i + 1) : fallback,
      errorWidget: (_, _, _) => _source(i + 1),
      errorListener: (error) => DrinkPhoto.noteError(url, error),
    );
  }

  /// The next source as a placeholder: its own error or wait is the
  /// [fallback], never the photo that's still loading.
  Widget _preview(int i) {
    if (i >= urls.length) return fallback;
    final url = urls[i];
    return CachedNetworkImage(
      key: ValueKey('preview:$url'),
      imageUrl: url,
      cacheManager: cacheManager,
      memCacheWidth: decodeWidth,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
      errorListener: (error) => DrinkPhoto.noteError(url, error),
    );
  }
}

class _Fallback extends StatelessWidget {
  const new({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.palette.brandGradient),
      child: Align(
        alignment: const AlignmentDirectional(0, -0.35),
        child: Text(
          initial.toUpperCase(),
          style: AppTextStyles.forText(initial, TextRole.largeTitle).copyWith(
            color: AppColors.onHeader.withValues(alpha: 0.85),
            fontSize: 56,
          ),
        ),
      ),
    );
  }
}
