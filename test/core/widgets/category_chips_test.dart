import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/widgets/category_chips.dart';

import '../../helpers/pump_app.dart';

void main() {
  group(CategoryChips, () {
    const options = <ChipOption>[
      (id: 'coffee', label: 'Coffee'),
      (id: 'iced', label: 'Iced coffee'),
    ];

    Future<void> pumpChips(
      WidgetTester tester, {
      List<ChipOption> items = options,
      String? selected = 'coffee',
      ValueChanged<String?>? onSelected,
      Locale locale = const Locale('en'),
    }) => tester.pumpApp(
      CategoryChips(
        options: items,
        selectedId: selected,
        onSelected: onSelected ?? (_) {},
      ),
      locale: locale,
    );

    testWidgets('one row, the picked chip selected', (tester) async {
      await pumpChips(tester);
      expect(
        tester.getCenter(find.text('Coffee')).dy,
        tester.getCenter(find.text('Iced coffee')).dy,
      );
      expect(
        tester.getSemantics(find.text('Coffee')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(find.text('Iced coffee'))
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
    });

    testWidgets('a tap reports the chip', (tester) async {
      final taps = <String?>[];
      await pumpChips(tester, onSelected: taps.add);
      await tester.tap(find.text('Iced coffee'));
      expect(taps, ['iced']);
    });

    testWidgets('Arabic: the first chip is at the right edge', (tester) async {
      await pumpChips(
        tester,
        items: const [(id: 'a', label: 'مشروبات'), (id: 'b', label: 'حلويات')],
        selected: 'a',
        locale: const Locale('ar'),
      );
      expect(
        tester.getCenter(find.text('مشروبات')).dx,
        greaterThan(tester.getCenter(find.text('حلويات')).dx),
      );
    });

    testWidgets('eight sections scroll sideways, the last is reachable', (
      tester,
    ) async {
      final picked = <String?>[];
      await pumpChips(
        tester,
        items: [for (var i = 0; i < 8; i++) (id: 's$i', label: 'Section $i')],
        selected: 's0',
        onSelected: picked.add,
      );
      expect(tester.takeException(), isNull);
      // Not even built until the row is dragged.
      expect(find.text('Section 7'), findsNothing);
      await tester.dragUntilVisible(
        find.text('Section 7'),
        find.byType(ListView),
        const Offset(-120, 0),
      );
      await tester.ensureVisible(find.text('Section 7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Section 7'));
      expect(picked, ['s7']);
    });
  });
}
