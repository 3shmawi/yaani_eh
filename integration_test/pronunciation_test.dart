import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/play_name_button.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/pronounce_pill.dart';

import '../test/helpers/fake_catalog_remote.dart';
import 'helpers/demo.dart';
import 'helpers/demo_app.dart';

/// Demo: «بيتقال إزاي؟» — "How do you even say it?"
/// Hear the drink of the day from Home, then Flat White like the barista
/// says it, slower, and the original. In airplane mode a name you've heard
/// still plays; one you never heard says why it can't.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hear a name like the barista, slower, and offline', (
    tester,
  ) async {
    final app = await DemoApp.start(pageSize: 100);
    await pumpUntil(tester, find.byKey(const Key('drink_of_the_day')));
    await tester.pumpAndSettle();
    await beat(tester, 1200);

    // Waits on the player, not on the playing UI: in CI a name lasts
    // 0.4 s and a slow simulator frame can skip the whole playing state.
    Future<void> listen() async {
      final before = app.player.played.length;
      await waitFor(
        tester,
        () => app.player.played.length > before,
        'a name to start playing',
      );
      await waitFor(tester, () => !app.player.isPlaying, 'the name to end');
      await tester.pumpAndSettle();
    }

    // 1. Home: the drink of the day's speaker.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('drink_of_the_day')),
        matching: find.byType(PlayNameButton),
      ),
    );
    await listen();
    await beat(tester);
    expect(app.player.played, hasLength(1));

    // 2. Open Flat White: the pill sits on its photo.
    final menu = find.byKey(const Key('menu_list'));
    Future<void> open(String name) async {
      final card = find.widgetWithText(DrinkCard, name);
      await tester.dragUntilVisible(card, menu, const Offset(0, -200));
      await tester.pumpAndSettle();
      await beat(tester);
      await tester.tap(card);
      await tester.pumpAndSettle();
      await beat(tester, 1500);
    }

    await open('Flat White');
    expect(find.byType(PronouncePill), findsOneWidget);

    // 3. Like the barista says it.
    await tester.tap(find.byKey(const Key('pronounce_barista')));
    await listen();
    await beat(tester);

    // 4. Slower, then the original.
    await tester.tap(find.byKey(const Key('pronounce_speed')));
    await tester.pumpAndSettle();
    await beat(tester, 600);
    await tester.tap(find.byKey(const Key('pronounce_original')));
    await listen();
    await beat(tester);
    expect(app.player.played.last.speed, 0.75);
    expect(app.player.played.last.file, endsWith('flat_white.original.m4a'));

    // 5. Airplane mode: Flat White still plays, it's on the phone.
    await app.setOnline(tester, online: false);
    await beat(tester);
    await tester.tap(find.byKey(const Key('pronounce_barista')));
    await listen();
    await beat(tester);

    // 6. A drink never opened: it says why it can't play.
    await tester.tap(find.byKey(const Key('drink_back')).last);
    await tester.pumpAndSettle();
    await beat(tester);
    final unheard = sampleItems(withAudio: true).firstWhere(
      (d) =>
          d['slug'] != 'flat_white' &&
          d['audio_barista_path'] != null &&
          !app.clips.onDevice.contains(d['audio_barista_path']),
    );
    await open(unheard['menu_name']! as String);
    await tester.tap(find.byKey(const Key('pronounce_barista')));
    await pumpUntil(tester, find.byKey(const Key('pronounce_failure')));
    await beat(tester, 2200);

    // 7. Back online: it plays.
    await app.setOnline(tester, online: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pronounce_barista')));
    await listen();
    await beat(tester, 1200);
    expect(
      app.player.played.last.file,
      endsWith('${unheard['slug']}.barista.m4a'),
    );
  });
}
