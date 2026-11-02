import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/widgets/category_chips.dart';

import '../../helpers/pump_app.dart';

void main() {
  group(CategoryChips, () {
    const sections = <ChipOption>[
      (id: 'cafe', label: 'Drinks'),
      (id: 'desserts', label: 'Desserts'),
    ];
    const categories = <ChipOption>[
      (id: 'coffee', label: 'Coffee'),
      (id: 'iced', label: 'Iced coffee'),
    ];

    Future<void> pumpChips(
      WidgetTester tester, {
      List<ChipOption> leading = sections,
      List<ChipOption> options = categories,
      String? selected = 'coffee',
      ValueChanged<String?>? onSelected,
      ValueChanged<String?>? onLeading,
      Locale locale = const Locale('en'),
    }) => tester.pumpApp(
      CategoryChips(
        leading: leading,
        leadingSelectedId: 'cafe',
        onLeadingSelected: onLeading,
        options: options,
        selectedId: selected,
        onSelected: onSelected ?? (_) {},
      ),
      locale: locale,
    );

    testWidgets('chips alone: one group, no divider', (tester) async {
      await pumpChips(tester, leading: const []);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.byKey(const Key('chips_divider')), findsNothing);
    });

    /// A wide screen, so nothing is past the edge of the row.
    Future<void> widen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(2400, 2436);
      await tester.pumpAndSettle();
    }

    testWidgets('a leading group and the options are one row', (tester) async {
      await pumpChips(tester);
      await widen(tester);
      expect(find.byType(ListView), findsOneWidget);
      // The sections first, then the divider, then the categories, all on
      // one line.
      final ys = {
        for (final t in ['Drinks', 'Desserts', 'Coffee', 'Iced coffee'])
          tester.getCenter(find.text(t)).dy,
      };
      expect(ys, hasLength(1));
      expect(find.byKey(const Key('chips_divider')), findsOneWidget);
      expect(
        tester.getCenter(find.text('Desserts')).dx,
        lessThan(tester.getCenter(find.byKey(const Key('chips_divider'))).dx),
      );
      expect(
        tester.getCenter(find.byKey(const Key('chips_divider'))).dx,
        lessThan(tester.getCenter(find.text('Coffee')).dx),
      );
    });

    testWidgets('each group selects on its own', (tester) async {
      final sectionTaps = <String?>[];
      final categoryTaps = <String?>[];
      await pumpChips(
        tester,
        onLeading: sectionTaps.add,
        onSelected: categoryTaps.add,
      );
      await widen(tester);
      await tester.tap(find.text('Desserts'));
      await tester.tap(find.text('Iced coffee'));
      expect(sectionTaps, ['desserts']);
      expect(categoryTaps, ['iced']);
      expect(
        tester.getSemantics(find.text('Drinks')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(find.text('Desserts')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
      expect(
        tester.getSemantics(find.text('Coffee')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
    });

    testWidgets('a section with no categories: the sections and no divider', (
      tester,
    ) async {
      await pumpChips(tester, options: const [], selected: null);
      expect(find.text('Drinks'), findsOneWidget);
      expect(find.byKey(const Key('chips_divider')), findsNothing);
    });

    testWidgets('the divider says nothing to screen readers', (tester) async {
      await pumpChips(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('chips_divider')),
          matching: find.byType(Semantics),
        ),
        findsNothing,
      );
    });

    testWidgets('Arabic: the sections start at the right edge', (tester) async {
      await pumpChips(
        tester,
        leading: const [(id: 'cafe', label: 'مشروبات')],
        options: const [(id: 'coffee', label: 'قهوة')],
        locale: const Locale('ar'),
      );
      expect(
        tester.getCenter(find.text('مشروبات')).dx,
        greaterThan(tester.getCenter(find.text('قهوة')).dx),
      );
    });

    testWidgets('eight sections scroll sideways, the last is reachable', (
      tester,
    ) async {
      final picked = <String?>[];
      await pumpChips(
        tester,
        leading: [for (var i = 0; i < 8; i++) (id: 's$i', label: 'Section $i')],
        onLeading: picked.add,
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
