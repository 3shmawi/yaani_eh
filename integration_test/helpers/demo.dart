import 'package:flutter_test/flutter_test.dart';

/// True when recording a demo video (`--dart-define=DEMO=true`).
const isDemo = bool.fromEnvironment('DEMO');

/// What a demo prints at every [beat]: `scripts/record_demo_ios.sh` takes a
/// simulator screenshot when it sees it, and the Demo video workflow shows
/// them in the PR comment.
const shotMarker = 'DEMO_SHOT';

/// A short pause between steps so a recorded demo is easy to follow.
/// Each pause is also a screenshot (see [shotMarker]). Does nothing in
/// normal test runs, so CI stays fast.
Future<void> beat(WidgetTester tester, [int milliseconds = 900]) async {
  if (!isDemo) return;
  await tester.pump(Duration(milliseconds: milliseconds));
  // The screen has settled; the recorder shoots during the pause below.
  // ignore: avoid_print
  print(shotMarker);
  await Future<void>.delayed(Duration(milliseconds: milliseconds));
}
