import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/pronunciation/domain/repositories/pronunciation_repository.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronunciation_controller.dart';

/// Clips without Supabase, with a pretend device cache: online, every clip
/// downloads to `/clips/<path>` and stays "on the device"; offline
/// ([online] false) only those play, others fail with `NetworkFailure`.
/// [failures] force a result; [delay] makes loading visible; [hold] keeps
/// every request loading until completed.
class FakePronunciationRepository implements PronunciationRepository {
  final requested = <String>[];
  final prefetched = <String>[];
  final onDevice = <String>{};
  final failures = <String, AppFailure>{};
  bool online = true;
  Duration delay = Duration.zero;
  Completer<void>? hold;

  @override
  Future<Result<String>> clipFile(String path) async {
    requested.add(path);
    if (hold case final hold?) await hold.future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failures[path] case final failure?) return Failed(failure);
    if (online) onDevice.add(path);
    return onDevice.contains(path)
        ? Success('/clips/$path')
        : const Failed(NetworkFailure());
  }

  @override
  Future<void> prefetch(Iterable<String> paths) async {
    prefetched.addAll(paths);
    if (online) onDevice.addAll(paths);
  }
}

/// A player without speakers: a clip "plays" until [finish] or [stop]
/// (or for [length] when set, like a real name — used by demos).
class FakeClipPlayer implements ClipPlayer {
  final played = <({String file, double speed})>[];
  int stops = 0;
  Duration? length;
  Object? throwOnPlay;
  Completer<void>? _current;

  bool get isPlaying => _current != null && !_current!.isCompleted;

  @override
  Future<void> play(String filePath, {required double speed}) async {
    if (throwOnPlay case final error?) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    played.add((file: filePath, speed: speed));
    final done = _current = Completer<void>();
    if (length case final length?) {
      unawaited(Future<void>.delayed(length).then((_) => _end(done)));
    }
    await done.future;
  }

  /// The clip reaches its end.
  void finish() => _end(_current);

  @override
  Future<void> stop() async {
    stops++;
    _end(_current);
  }

  void _end(Completer<void>? c) {
    if (c != null && !c.isCompleted) c.complete();
  }
}

/// Riverpod overrides that put the fakes behind the pronunciation feature.
List<Override> pronunciationOverrides(
  FakePronunciationRepository repository,
  FakeClipPlayer player,
) => [
  pronunciationRepositoryProvider.overrideWithValue(repository),
  clipPlayerProvider.overrideWithValue(player),
];
