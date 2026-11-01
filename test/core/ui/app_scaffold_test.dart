import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_theme.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/l10n/l10n.dart';

const _home = Key('home');

/// The bar as the phone draws it (full glass, not the lite look), on a
/// 320-wide phone with a home indicator, opened over another page so it has
/// a back button.
Future<void> _pumpGlass(
  WidgetTester tester,
  Widget screen, {
  required TextDirection direction,
}) async {
  tester.view
    ..physicalSize = const Size(960, 1704)
    ..devicePixelRatio = 3
    ..padding = const FakeViewPadding(top: 141, bottom: 102);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: AppDimens.designSize,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.dark,
        locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            key: _home,
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => screen)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_home));
  await tester.pumpAndSettle();
}

Widget _button(String key, IconData icon) =>
    AppIconButton(key: Key(key), icon: icon, tooltip: key, onPressed: () {});

void main() {
  // From flutter-project-kit: the glass bar's buttons once drew past their
  // slots and covered the title.
  for (final direction in TextDirection.values) {
    testWidgets('glass bar: back, title and actions never overlap '
        '(${direction.name})', (tester) async {
      const title = 'A long title that has to be cut off at the end';
      await _pumpGlass(
        tester,
        AppScaffold(
          title: title,
          actions: [
            _button('a1', Icons.flag_outlined),
            _button('a2', Icons.more_horiz),
          ],
          body: const SizedBox.expand(),
        ),
        direction: direction,
      );
      expect(tester.takeException(), isNull);

      final width = tester.view.physicalSize.width / 3;
      final rects = {
        'back': tester.getRect(find.byType(AppIconButton).first),
        'a1': tester.getRect(find.byKey(const Key('a1'))),
        'a2': tester.getRect(find.byKey(const Key('a2'))),
        'title': tester.getRect(find.text(title)),
      };
      for (final MapEntry(key: name, value: r) in rects.entries) {
        expect(r.left, greaterThanOrEqualTo(0), reason: name);
        expect(r.right, lessThanOrEqualTo(width), reason: name);
        if (name != 'title') {
          expect(
            r.size,
            const Size.square(AppDimens.touchTarget),
            reason: name,
          );
        }
      }
      final names = rects.keys.toList();
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          final overlap = rects[names[i]]!.intersect(rects[names[j]]!);
          expect(
            overlap.width <= 0 || overlap.height <= 0,
            isTrue,
            reason: '${names[i]} overlaps ${names[j]}',
          );
        }
      }
      // Back sits at the start edge, the actions at the end, and the title
      // is really shown (centred like iOS: on a 320-pt phone with two
      // actions it gets about two buttons' width).
      final ltr = direction == TextDirection.ltr;
      final back = rects['back']!;
      final a2 = rects['a2']!;
      expect(ltr ? back.left : width - back.right, lessThan(width / 4));
      expect(ltr ? width - a2.right : a2.left, lessThan(width / 4));
      expect(
        rects['title']!.width,
        greaterThan(AppDimens.touchTarget),
        reason: 'title shown',
      );
    });
  }

  test('the CupertinoIcons font ships with the app', () async {
    // Without the cupertino_icons package every iOS icon is a "?" box.
    final manifest = await rootBundle.loadString('FontManifest.json');
    const icon = CupertinoIcons.settings;
    expect(
      manifest,
      contains('"packages/${icon.fontPackage}/${icon.fontFamily}"'),
    );
  });
}
