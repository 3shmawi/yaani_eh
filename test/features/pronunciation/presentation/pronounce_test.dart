import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/features/pronunciation/domain/entities/pronunciation.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronounce.dart';
import 'package:yaani_eh/features/pronunciation/presentation/pronunciation_controller.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/play_name_button.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/pronounce_pill.dart';
import 'package:yaani_eh/l10n/l10n.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_pronunciation.dart';
import '../../../helpers/pump_app.dart';

final AppLocalizations _ar = lookupAppLocalizations(const Locale('ar'));

/// Puts [child] on a dark "photo" the way the drink page does, with Reduce
/// Motion on so the playing bars stand still (and screens can settle).
Widget _onPhoto(Widget child, {bool reduceMotion = true}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: Material(
      color: const Color(0xFF2B1A10),
      child: Center(child: child),
    ),
  ),
);

PronouncePill _pill({
  List<Voice> voices = Voice.values,
  Map<Voice, SegmentState> states = const {},
  PlaybackSpeed speed = PlaybackSpeed.normal,
  AppFailure? failure,
  ValueChanged<Voice>? onToggle,
  VoidCallback? onToggleSpeed,
  String name = 'Flat White',
}) => PronouncePill(
  name: name,
  voices: voices,
  states: states,
  speed: speed,
  failure: failure,
  onToggle: onToggle ?? (_) {},
  onToggleSpeed: onToggleSpeed ?? () {},
);

void main() {
  group('PronouncePill', () {
    testWidgets('a segment per voice and the speed toggle; taps report '
        'the voice', (tester) async {
      final tapped = <Voice>[];
      var speedTaps = 0;
      await tester.pumpApp(
        _onPhoto(_pill(onToggle: tapped.add, onToggleSpeed: () => speedTaps++)),
      );

      expect(find.text(l10nEn.pronounceBarista), findsOneWidget);
      expect(find.text(l10nEn.pronounceOriginal), findsOneWidget);
      expect(find.textContaining('0.75×'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pronounce_original')));
      await tester.tap(find.byKey(const Key('pronounce_barista')));
      await tester.tap(find.byKey(const Key('pronounce_speed')));
      expect(tapped, [Voice.original, Voice.barista]);
      expect(speedTaps, 1);
      await tester.expectAccessible();
    });

    testWidgets('a missing clip hides its segment; none hides the pill', (
      tester,
    ) async {
      await tester.pumpApp(_onPhoto(_pill(voices: [Voice.original])));
      expect(find.text(l10nEn.pronounceBarista), findsNothing);
      expect(find.text(l10nEn.pronounceOriginal), findsOneWidget);

      await tester.pumpApp(_onPhoto(_pill(voices: const [])));
      expect(find.byType(PronouncePill), findsOneWidget);
      expect(find.textContaining('0.75×'), findsNothing);
    });

    testWidgets('screen readers hear what each control does', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        _onPhoto(
          _pill(
            states: {Voice.original: SegmentState.playing},
            speed: PlaybackSpeed.slow,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Play barista pronunciation of Flat White'),
        findsOneWidget,
      );
      // The playing one says it stops.
      expect(find.bySemanticsLabel('Stop Flat White'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('pronounce_speed'))),
        isSemantics(
          label: 'Slower',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('playing: brand fill and the sound bars', (tester) async {
      await tester.pumpApp(
        _onPhoto(_pill(states: {Voice.barista: SegmentState.playing})),
      );
      expect(find.byType(SoundBars), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('the bars move, unless Reduce Motion is on', (tester) async {
      await tester.pumpApp(
        _onPhoto(
          _pill(states: {Voice.barista: SegmentState.playing}),
          reduceMotion: false,
        ),
      );
      double barHeight() => tester
          .getSize(
            find
                .descendant(
                  of: find.byType(SoundBars),
                  matching: find.byType(Container),
                )
                .first,
          )
          .height;
      final before = barHeight();
      await tester.pump(const Duration(milliseconds: 300));
      expect(barHeight(), isNot(before));

      await tester.pumpApp(
        _onPhoto(_pill(states: {Voice.barista: SegmentState.playing})),
      );
      final still = barHeight();
      await tester.pump(const Duration(milliseconds: 300));
      expect(barHeight(), still);
    });

    testWidgets('loading shows a spinner in the segment', (tester) async {
      await tester.pumpApp(
        _onPhoto(_pill(states: {Voice.barista: SegmentState.loading})),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('failures say why, in words', (tester) async {
      for (final (failure, message) in [
        (const NetworkFailure(), l10nEn.pronounceOffline),
        (const TimeoutFailure(), l10nEn.pronounceOffline),
        (const NotFoundFailure(), l10nEn.pronounceMissing),
        (const UnknownFailure(), l10nEn.pronounceError),
      ]) {
        await tester.pumpApp(
          _onPhoto(
            _pill(
              states: {Voice.barista: SegmentState.failed},
              failure: failure,
            ),
          ),
        );
        expect(find.text(message), findsOneWidget);
      }
      await tester.expectAccessible();
    });

    testWidgets('Arabic: right to left, speed stays 0.75×', (tester) async {
      await tester.pumpApp(
        _onPhoto(_pill(speed: PlaybackSpeed.slow)),
        locale: const Locale('ar'),
      );
      expect(find.text(_ar.pronounceBarista), findsOneWidget);
      expect(find.text(_ar.pronounceOriginal), findsOneWidget);
      // Barista is the first segment: on the right in RTL.
      expect(
        tester.getCenter(find.text(_ar.pronounceBarista)).dx,
        greaterThan(tester.getCenter(find.text(_ar.pronounceOriginal)).dx),
      );
      // The speed label is LTR-isolated so it never reads «×0.75».
      final speed = tester.widget<Text>(find.textContaining('0.75×'));
      expect(speed.data, '\u20660.75×\u2069');
      await tester.expectAccessible();
    });

    testWidgets('dark mode and large text (1.3×) on a small phone', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpApp(
        _onPhoto(
          _pill(
            states: {Voice.barista: SegmentState.failed},
            failure: const NetworkFailure(),
          ),
        ),
        themeMode: ThemeMode.dark,
        locale: const Locale('ar'),
      );
      tester.view.physicalSize = const Size(960, 1704); // 320×568 @3x
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.expectAccessible();
    });

    testWidgets('hostile names are shown as text, never interpreted', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      const hostile = "<script>alert('x')</script> \u202E'; drop --";
      await tester.pumpApp(_onPhoto(_pill(name: hostile)));
      expect(
        find.bySemanticsLabel('Play barista pronunciation of $hostile'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });

  group('PlayNameButton', () {
    testWidgets('idle: speaker, «Hear the name»; playing: filled, «Stop»', (
      tester,
    ) async {
      var taps = 0;
      Widget button(SegmentState state, {AppFailure? failure}) => _onPhoto(
        PlayNameButton(
          name: 'Cortado',
          state: state,
          failure: failure,
          onPressed: () => taps++,
        ),
      );
      await tester.pumpApp(button(SegmentState.idle));
      expect(find.byIcon(AppIcons.speaker), findsOneWidget);
      expect(find.byTooltip('Hear the name: Cortado'), findsOneWidget);
      await tester.tap(find.byType(PlayNameButton));
      expect(taps, 1);
      await tester.expectAccessible();

      await tester.pumpApp(button(SegmentState.playing));
      expect(find.byIcon(AppIconsFill.speaker), findsOneWidget);
      expect(find.byTooltip('Stop Cortado'), findsOneWidget);

      await tester.pumpApp(
        button(SegmentState.failed, failure: const NetworkFailure()),
      );
      expect(find.byIcon(AppIcons.wifiSlash), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(PlayNameButton)),
        isSemantics(hint: l10nEn.pronounceOffline, isLiveRegion: true),
      );
      handle.dispose();

      await tester.pumpApp(
        button(SegmentState.failed, failure: const NotFoundFailure()),
      );
      expect(find.byIcon(AppIcons.warningCircle), findsOneWidget);
    });
  });

  group('wired to the player', () {
    late FakePronunciationRepository repo;
    late FakeClipPlayer player;
    final items = sampleCatalogItems(withAudio: true);
    final flatWhite = items.firstWhere((i) => i.slug == 'flat_white');
    final coldBrew = items.firstWhere((i) => i.slug == 'cold_brew');
    final affogato = items.firstWhere((i) => i.slug == 'affogato');

    setUp(() {
      repo = FakePronunciationRepository();
      player = FakeClipPlayer();
    });

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpApp(
      ProviderScope(
        overrides: pronunciationOverrides(repo, player),
        child: _onPhoto(child),
      ),
    );

    testWidgets('the pill prefetches, plays, shows playing and goes back '
        'when the clip ends', (tester) async {
      await pump(tester, ItemPronounce(item: flatWhite));
      expect(repo.prefetched, [
        'flat_white.barista.m4a',
        'flat_white.original.m4a',
      ]);

      await tester.tap(find.byKey(const Key('pronounce_original')));
      await tester.pump();
      expect(player.played.single.file, '/clips/flat_white.original.m4a');
      expect(find.byType(SoundBars), findsOneWidget);

      player.finish();
      await tester.pumpAndSettle();
      expect(find.byType(SoundBars), findsNothing);
    });

    testWidgets('slow speed reaches the player', (tester) async {
      await pump(tester, ItemPronounce(item: flatWhite));
      await tester.tap(find.byKey(const Key('pronounce_speed')));
      await tester.tap(find.byKey(const Key('pronounce_barista')));
      await tester.pump();
      expect(player.played.single.speed, 0.75);
    });

    testWidgets('only the voices with clips show', (tester) async {
      await pump(tester, ItemPronounce(item: coldBrew));
      expect(find.byKey(const Key('pronounce_barista')), findsOneWidget);
      expect(find.byKey(const Key('pronounce_original')), findsNothing);

      await pump(tester, ItemPronounce(item: affogato));
      expect(find.byKey(const Key('pronounce_speed')), findsNothing);
    });

    testWidgets('offline and never played: the note shows, then clears', (
      tester,
    ) async {
      repo.failures['flat_white.barista.m4a'] = const NetworkFailure();
      await pump(tester, ItemPronounce(item: flatWhite));
      await tester.tap(find.byKey(const Key('pronounce_barista')));
      await tester.pump();
      expect(find.text(l10nEn.pronounceOffline), findsOneWidget);

      await tester.pump(PronunciationController.failureShownFor);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.pronounceOffline), findsNothing);
    });

    testWidgets('the card button plays, then stops on a second tap', (
      tester,
    ) async {
      await pump(tester, ItemPlayButton(item: flatWhite));
      await tester.tap(find.byType(PlayNameButton));
      await tester.pump();
      expect(player.isPlaying, isTrue);
      expect(find.byIcon(AppIconsFill.speaker), findsOneWidget);

      await tester.tap(find.byType(PlayNameButton));
      await tester.pump();
      expect(player.isPlaying, isFalse);
      expect(find.byIcon(AppIcons.speaker), findsOneWidget);
    });

    testWidgets('no clips → no card button', (tester) async {
      await pump(tester, ItemPlayButton(item: affogato));
      expect(find.byType(PlayNameButton), findsNothing);
    });

    testWidgets('one name at a time across the screen', (tester) async {
      final latte = items.firstWhere((i) => i.slug == 'latte');
      await pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ItemPlayButton(item: flatWhite),
            ItemPlayButton(item: latte),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('play_flat_white')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('play_latte')));
      await tester.pump();
      expect(find.byIcon(AppIconsFill.speaker), findsOneWidget);
      expect(player.played.last.file, '/clips/latte.barista.m4a');
      unawaited(player.stop());
    });
  });
}
