import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/pronunciation/domain/entities/pronunciation.dart';
import 'package:yaani_eh/features/pronunciation/domain/repositories/pronunciation_repository.dart';
import 'package:yaani_eh/features/pronunciation/domain/usecases/clips_for.dart';

/// Override in tests: `pronunciationRepositoryProvider.overrideWithValue(…)`.
final pronunciationRepositoryProvider = Provider<PronunciationRepository>(
  (ref) => Dependencies.pronunciationRepository,
);

final clipPlayerProvider = Provider<ClipPlayer>(
  (ref) => Dependencies.clipPlayer,
);

/// The one pronunciation player of the app: only one name plays at a time,
/// wherever it was tapped.
final pronunciationProvider =
    NotifierProvider<PronunciationController, PronunciationState>(
      PronunciationController.new,
    );

class PronunciationController extends Notifier<PronunciationState> {
  /// How long a failed button shows its problem before going back to normal.
  static const failureShownFor = Duration(seconds: 4);

  /// Bumped by every tap and stop; an older run that wakes up later sees
  /// it's been replaced and leaves the state alone.
  int _run = 0;
  Timer? _clearFailure;

  @override
  PronunciationState build() {
    ref.onDispose(() {
      _run++;
      _clearFailure?.cancel();
    });
    return const PronunciationState();
  }

  /// Plays [item]'s [voice], or stops it when it's the one playing (or
  /// loading). Anything else playing stops first.
  Future<void> toggle(CatalogItem item, Voice voice) async {
    if (_isActive(item, voice)) return await stop();
    final clip = const ClipsFor().voice(item, voice);
    if (clip == null) return;
    final run = ++_run;
    _clearFailure?.cancel();
    final player = ref.read(clipPlayerProvider);
    state = state.copyWith(
      playback: PlaybackLoading(itemId: item.id, voice: voice),
    );
    await player.stop();
    final file = await ref
        .read(pronunciationRepositoryProvider)
        .clipFile(clip.path);
    if (!_current(run)) return;
    switch (file) {
      case Failed(:final failure):
        _fail(item, voice, failure);
      case Success(:final value):
        final speed = state.speed;
        state = state.copyWith(
          playback: PlaybackPlaying(itemId: item.id, voice: voice),
        );
        unawaited(
          Analytics.capture('pronunciation_played', {
            'drink': item.slug,
            'voice': voice.name,
            'speed': speed.factor,
          }),
        );
        try {
          await player.play(value, speed: speed.factor);
        } on Object catch (error, stackTrace) {
          if (!_current(run)) return;
          unawaited(Monitoring.captureException(error, stackTrace));
          _fail(item, voice, UnknownFailure(error));
          return;
        }
        if (_current(run)) {
          state = state.copyWith(playback: const PlaybackIdle());
        }
    }
  }

  /// The cards' button: plays [item]'s first clip (barista when it has
  /// one), or stops whatever of this item is playing.
  Future<void> toggleFirst(CatalogItem item) async {
    if (_isActive(item)) return await stop();
    final clips = const ClipsFor()(item);
    if (clips.isEmpty) return;
    await toggle(item, clips.first.voice);
  }

  /// Stops the clip playing now, if any.
  Future<void> stop() async {
    _run++;
    _clearFailure?.cancel();
    state = state.copyWith(playback: const PlaybackIdle());
    await ref.read(clipPlayerProvider).stop();
  }

  /// 1× ↔ 0.75×; used from the next clip on.
  void toggleSpeed() => state = state.copyWith(
    speed: state.speed == PlaybackSpeed.normal
        ? PlaybackSpeed.slow
        : PlaybackSpeed.normal,
  );

  /// Gets [item]'s clips onto the device in the background (the drink page
  /// calls this), so they also play offline later.
  void prefetch(CatalogItem item) {
    final paths = [for (final clip in const ClipsFor()(item)) clip.path];
    if (paths.isEmpty) return;
    unawaited(ref.read(pronunciationRepositoryProvider).prefetch(paths));
  }

  bool _isActive(CatalogItem item, [Voice? voice]) => switch (state.playback) {
    final PlaybackLoading p => p.isFor(item.id, voice),
    final PlaybackPlaying p => p.isFor(item.id, voice),
    _ => false,
  };

  bool _current(int run) => ref.mounted && run == _run;

  void _fail(CatalogItem item, Voice voice, AppFailure failure) {
    final failed = PlaybackFailed(
      itemId: item.id,
      voice: voice,
      failure: failure,
    );
    state = state.copyWith(playback: failed);
    unawaited(
      Analytics.capture('pronunciation_failed', {
        'drink': item.slug,
        'voice': voice.name,
        'reason': failureReason(failure),
      }),
    );
    _clearFailure = Timer(failureShownFor, () {
      if (ref.mounted && identical(state.playback, failed)) {
        state = state.copyWith(playback: const PlaybackIdle());
      }
    });
  }

  /// `offline`, `missing` or `other`, for analytics and the message shown.
  static String failureReason(AppFailure failure) => switch (failure) {
    NetworkFailure() || TimeoutFailure() => 'offline',
    NotFoundFailure() => 'missing',
    _ => 'other',
  };
}
