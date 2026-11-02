import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group(AppTapHaptics, () {
    List<Object?> recordHaptics(WidgetTester tester) {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return haptics;
    }

    Future<void> pumpList(WidgetTester tester) => tester.pumpApp(
      Material(
        child: AppTapHaptics(
          child: ListView(
            key: const Key('list'),
            children: [
              for (var i = 0; i < 30; i++)
                ListTile(
                  key: Key('row_$i'),
                  title: Text('Row $i'),
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
    );

    testWidgets('a tap ticks once', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpList(tester);
      await tester.tap(find.byKey(const Key('row_0')));
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('a tap on nothing in particular still ticks', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpList(tester);
      await tester.tapAt(const Offset(2, 2));
      await tester.pump();
      expect(haptics, hasLength(1));
    });

    testWidgets('scrolling does not tick', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpList(tester);
      await tester.drag(find.byKey(const Key('list')), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);
    });

    testWidgets('a long press does not tick on release', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpList(tester);
      // The test pointer has no clock: give the events their own times.
      final at = tester.getCenter(find.byKey(const Key('row_0')));
      tester.binding.handlePointerEvent(PointerDownEvent(position: at));
      tester.binding.handlePointerEvent(
        PointerUpEvent(position: at, timeStamp: const Duration(seconds: 1)),
      );
      await tester.pump();
      expect(haptics, isEmpty);
    });

    testWidgets('two fingers tick once each', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpList(tester);
      await tester.tap(find.byKey(const Key('row_0')));
      await tester.tap(find.byKey(const Key('row_1')));
      await tester.pump();
      expect(haptics, hasLength(2));
    });
  });
}
