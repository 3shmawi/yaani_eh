import 'package:meta/meta.dart';
import 'package:yaani_eh/core/network/app_failure.dart';

/// Who says the drink's name.
enum Voice {
  /// How baristas in Egypt say it («زي الباريستا»).
  barista,

  /// The original Italian / English («الأصلي»).
  original,
}

/// Playback speed: normal, or slower to follow along (pitch is kept).
enum PlaybackSpeed {
  normal(1),
  slow(0.75);

  new(this.factor);

  final double factor;
}

/// One recorded name: its voice and its path in the `item-audio` bucket.
@immutable
class Clip {
  const new({required this.voice, required this.path});

  final Voice voice;
  final String path;

  @override
  bool operator ==(Object other) =>
      other is Clip && other.voice == voice && other.path == path;

  @override
  int get hashCode => Object.hash(voice, path);
}

/// What the (single, app-wide) player is doing.
@immutable
sealed class Playback {
  const new();
}

/// Nothing playing.
final class PlaybackIdle extends Playback {
  const new();
}

/// A clip that's busy for one item and voice: being fetched, playing, or
/// that just failed.
sealed class PlaybackOf extends Playback {
  const new({required this.itemId, required this.voice});

  final String itemId;
  final Voice voice;

  bool isFor(String itemId, [Voice? voice]) =>
      this.itemId == itemId && (voice == null || this.voice == voice);
}

/// Fetching the clip (from the device, or downloading it).
final class PlaybackLoading extends PlaybackOf {
  const new({required super.itemId, required super.voice});
}

final class PlaybackPlaying extends PlaybackOf {
  const new({required super.itemId, required super.voice});
}

/// The clip couldn't play; shown for a few seconds.
final class PlaybackFailed extends PlaybackOf {
  const new({
    required super.itemId,
    required super.voice,
    required this.failure,
  });

  final AppFailure failure;
}

/// The pronunciation state the screens read.
@immutable
class PronunciationState {
  const new({
    this.playback = const PlaybackIdle(),
    this.speed = PlaybackSpeed.normal,
  });

  final Playback playback;
  final PlaybackSpeed speed;

  PronunciationState copyWith({Playback? playback, PlaybackSpeed? speed}) =>
      PronunciationState(
        playback: playback ?? this.playback,
        speed: speed ?? this.speed,
      );
}
