import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/widgets/expanding_search_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  group(ExpandingSearchBar, () {
    var opened = 0;

    Future<void> pumpBar(WidgetTester tester, {bool reduceMotion = false}) {
      opened = 0;
      return tester.pumpApp(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Material(
            child: ExpandingSearchBar(
              leading: const SizedBox(key: Key('lead'), width: 48, height: 48),
              chips: const SizedBox(key: Key('chips'), height: 48),
              onOpen: () => opened++,
            ),
          ),
        ),
      );
    }

    final button = find.byKey(const Key('section_search_pinned'));
    final field = find.byKey(const Key('section_search_pinned_field'));

    testWidgets('rests as a button next to the chips', (tester) async {
      await pumpBar(tester);
      expect(button, findsOneWidget);
      expect(field, findsNothing);
      expect(tester.getSize(button).width, AppDimens.touchTarget);
      expect(opened, 0);
    });

    testWidgets('a tap grows it into a full-width field, then opens', (
      tester,
    ) async {
      await pumpBar(tester);
      await tester.tap(button);
      // Not yet: the animation comes first.
      await tester.pump(const Duration(milliseconds: 20));
      expect(opened, 0);

      await tester.pump(
        AppMotion.searchExpand - const Duration(milliseconds: 40),
      );
      // Nearly there: a field, wider than the button, chips fading out.
      expect(field, findsOneWidget);
      expect(
        tester.getSize(field).width,
        greaterThan(AppDimens.touchTarget * 3),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(opened, 1);
      // Full width, less the bar's side padding.
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getSize(field).width,
        closeTo(width - AppDimens.space2 * 2, 1),
      );
      // Settled, and back to a button once the search screen has covered it.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(button, findsOneWidget);
      expect(field, findsNothing);
    });

    testWidgets('the chips and back make way, and can’t be tapped', (
      tester,
    ) async {
      await pumpBar(tester);
      await tester.tap(button);
      await tester.pump(); // the animation starts
      await tester.pump(AppMotion.searchExpand);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(const Key('chips')),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0);
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(
                    of: find.byKey(const Key('chips')),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('tapping twice opens once', (tester) async {
      await pumpBar(tester);
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(AppMotion.searchExpand * 2);
      expect(opened, 1);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Reduce Motion: opens at once, nothing grows', (tester) async {
      await pumpBar(tester, reduceMotion: true);
      await tester.tap(button);
      await tester.pump();
      expect(opened, 1);
      expect(field, findsNothing);
    });

    testWidgets('the field itself opens search too', (tester) async {
      await pumpBar(tester);
      await tester.tap(button);
      await tester.pump(); // the animation starts
      await tester.pump(
        AppMotion.searchExpand - const Duration(milliseconds: 40),
      );
      expect(field, findsOneWidget);
      await tester.tap(field);
      expect(opened, 1);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
