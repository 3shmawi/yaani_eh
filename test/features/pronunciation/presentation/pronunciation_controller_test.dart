import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/pronunciation/domain/entities/pronunciation.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronunciation_controller.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_pronunciation.dart';

void main() {
  late FakePronunciationRepository repo;
  late FakeClipPlayer player;
  late ProviderContainer container;
  final items = sampleCatalogItems(withAudio: true);
  CatalogItem item(String slug) => items.firstWhere((i) => i.slug == slug);
  final flatWhite = item('flat_white');
  final latte = item('latte');

  PronunciationState state() => container.read(pronunciationProvider);
  PronunciationController controller() =>
      container.read(pronunciationProvider.notifier);

  setUp(() {
    repo = FakePronunciationRepository();
    player = FakeClipPlayer();
    container = ProviderContainer(
      overrides: pronunciationOverrides(repo, player),
    );
    addTearDown(container.dispose);
  });

  test('starts idle at 1×', () {
    expect(state().playback, isA<PlaybackIdle>());
    expect(state().speed, PlaybackSpeed.normal);
  });

  test('a tap loads, plays, then goes idle when the clip ends', () async {
    repo.hold = Completer();
    final run = controller().toggle(flatWhite, Voice.barista);
    await pumpEventQueue();
    expect(state().playback, isA<PlaybackLoading>());

    repo.hold!.complete();
    await pumpEventQueue();
    final playing = state().playback as PlaybackPlaying;
    expect(playing.isFor(flatWhite.id, Voice.barista), isTrue);
    expect(player.played.single.file, '/clips/flat_white.barista.m4a');
    expect(player.played.single.speed, 1);

    player.finish();
    await run;
    expect(state().playback, isA<PlaybackIdle>());
  });

  test('tapping the playing voice stops it', () async {
    unawaited(controller().toggle(flatWhite, Voice.original));
    await pumpEventQueue();
    expect(state().playback, isA<PlaybackPlaying>());

    await controller().toggle(flatWhite, Voice.original);
    expect(state().playback, isA<PlaybackIdle>());
    expect(player.isPlaying, isFalse);
  });

  test('only one name at a time: a new tap stops the old one', () async {
    unawaited(controller().toggle(flatWhite, Voice.barista));
    await pumpEventQueue();
    unawaited(controller().toggle(latte, Voice.original));
    await pumpEventQueue();

    final playing = state().playback as PlaybackPlaying;
    expect(playing.isFor(latte.id, Voice.original), isTrue);
    expect(player.played.map((p) => p.file), [
      '/clips/flat_white.barista.m4a',
      '/clips/latte.original.m4a',
    ]);
    expect(player.stops, greaterThanOrEqualTo(2));
  });

  test('a slow download that is overtaken never plays', () async {
    repo.hold = Completer();
    unawaited(controller().toggle(flatWhite, Voice.barista));
    await pumpEventQueue();
    repo.hold = null;
    unawaited(controller().toggle(latte, Voice.barista));
    await pumpEventQueue();
    expect(player.played.single.file, '/clips/latte.barista.m4a');
  });

  test('0.75× applies to the next clip', () async {
    controller().toggleSpeed();
    expect(state().speed, PlaybackSpeed.slow);
    unawaited(controller().toggle(flatWhite, Voice.barista));
    await pumpEventQueue();
    expect(player.played.single.speed, 0.75);
    controller().toggleSpeed();
    expect(state().speed, PlaybackSpeed.normal);
  });

  test('cards play the barista clip first, else the original', () async {
    unawaited(controller().toggleFirst(flatWhite));
    await pumpEventQueue();
    expect((state().playback as PlaybackPlaying).voice, Voice.barista);

    // Tapping the card again stops it, whichever voice is playing.
    await controller().toggleFirst(flatWhite);
    expect(state().playback, isA<PlaybackIdle>());
  });

  test('a drink with no clips does nothing', () async {
    await controller().toggleFirst(item('affogato'));
    await controller().toggle(item('cold_brew'), Voice.original);
    expect(state().playback, isA<PlaybackIdle>());
    expect(repo.requested, isEmpty);
  });

  test('a failure shows for a few seconds, then clears', () {
    fakeAsync((async) {
      repo.failures['flat_white.barista.m4a'] = const NetworkFailure();
      unawaited(controller().toggle(flatWhite, Voice.barista));
      async.flushMicrotasks();
      final failed = state().playback as PlaybackFailed;
      expect(failed.failure, isA<NetworkFailure>());
      expect(failed.isFor(flatWhite.id, Voice.barista), isTrue);
      expect(player.played, isEmpty);

      async.elapse(PronunciationController.failureShownFor);
      expect(state().playback, isA<PlaybackIdle>());
    });
  });

  test('a new tap replaces a shown failure', () {
    fakeAsync((async) {
      repo.failures['flat_white.barista.m4a'] = const NotFoundFailure();
      unawaited(controller().toggle(flatWhite, Voice.barista));
      async.flushMicrotasks();
      unawaited(controller().toggle(latte, Voice.barista));
      async
        ..flushMicrotasks()
        ..elapse(PronunciationController.failureShownFor);
      expect(state().playback, isA<PlaybackPlaying>());
    });
  });

  test('a clip the player can not play → failed, not a crash', () async {
    player.throwOnPlay = StateError('bad file');
    await controller().toggle(flatWhite, Voice.barista);
    final failed = state().playback as PlaybackFailed;
    expect(failed.failure, isA<UnknownFailure>());
  });

  test('stop() when nothing plays is fine', () async {
    await controller().stop();
    expect(state().playback, isA<PlaybackIdle>());
  });

  test('prefetch asks for both clips of a drink, none without clips', () {
    controller()
      ..prefetch(flatWhite)
      ..prefetch(item('affogato'));
    expect(repo.prefetched, [
      'flat_white.barista.m4a',
      'flat_white.original.m4a',
    ]);
  });

  test('failure reasons for analytics', () {
    expect(
      PronunciationController.failureReason(const NetworkFailure()),
      'offline',
    );
    expect(
      PronunciationController.failureReason(const TimeoutFailure()),
      'offline',
    );
    expect(
      PronunciationController.failureReason(const NotFoundFailure()),
      'missing',
    );
    expect(
      PronunciationController.failureReason(const UnknownFailure()),
      'other',
    );
  });
}
