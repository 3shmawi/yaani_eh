import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screenshots of real screens for review (`scripts/screens.sh`), off in
/// normal test runs. Fonts are the app's own, so text looks as on a phone;
/// glass draws its solid (Reduce Transparency) look, as in all widget tests.
const takeScreens = bool.fromEnvironment('SCREENS');

/// Loads the bundled fonts and the icon fonts; flutter_test otherwise
/// draws every glyph as a box.
Future<void> loadAppFonts() async {
  Future<void> load(String family, Iterable<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  const weights = [400, 500, 600, 700];
  await load('Plus Jakarta Sans', [
    for (final w in weights)
      'assets/fonts/PlusJakartaSans/PlusJakartaSans-$w.ttf',
  ]);
  await load('Readex Pro', [
    for (final w in weights) 'assets/fonts/ReadexPro/ReadexPro-$w.ttf',
  ]);
  await load('PhosphorRegular', ['assets/fonts/Phosphor/Phosphor.ttf']);
  final pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final cupertino = Directory('$pubCache/hosted/pub.dev')
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('cupertino_icons-'))
      .map((d) => File('${d.path}/assets/CupertinoIcons.ttf'))
      .where((f) => f.existsSync())
      .firstOrNull;
  if (cupertino != null) {
    await load('packages/cupertino_icons/CupertinoIcons', [cupertino.path]);
  }
}

/// Saves what's on screen to `build/screens/<name>.png`.
Future<void> shoot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byWidgetPredicate((w) => w is WidgetsApp).first,
    matchesGoldenFile(
      Uri.file('${Directory.current.path}/build/screens/$name.png'),
    ),
  );
}
