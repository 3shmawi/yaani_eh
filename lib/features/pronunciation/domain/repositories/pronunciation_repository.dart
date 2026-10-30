import 'package:yaani_eh/core/network/result.dart';

/// Where clips come from: the `item-audio` bucket, kept on the device after
/// the first play so a name heard once plays offline.
abstract interface class PronunciationRepository {
  /// The clip at [path] as a local file path: the device copy when there
  /// is one, else downloaded. Offline with no copy → `NetworkFailure`; no
  /// such clip → `NotFoundFailure`.
  Future<Result<String>> clipFile(String path);

  /// Downloads [paths] in the background when they aren't on the device
  /// yet, so the drink page's names also work offline later. Never fails.
  Future<void> prefetch(Iterable<String> paths);
}

/// Plays one local clip at a time.
abstract interface class ClipPlayer {
  /// Plays the file at [filePath] at [speed] (pitch kept). Completes when
  /// the clip ends or [stop] is called; throws when it can't be played.
  Future<void> play(String filePath, {required double speed});

  /// Stops the clip playing now, if any.
  Future<void> stop();
}
