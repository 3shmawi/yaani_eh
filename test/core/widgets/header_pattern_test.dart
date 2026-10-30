import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/header_pattern.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the band has the mashrabiya; the flat band leaves it out', (
    tester,
  ) async {
    // pumpApp runs with Reduce Transparency (the flat, high-contrast band).
    await tester.pumpApp(const HeaderBand(title: 'يعني إيه؟'));
    expect(find.byType(HeaderPattern), findsNothing);

    await tester.pumpApp(
      const GlassAccessibilityScope(
        reduceTransparency: false,
        child: HeaderBand(title: 'يعني إيه؟'),
      ),
    );
    expect(find.byType(HeaderPattern), findsOneWidget);
    // Decorative: nothing for screen readers.
    expect(
      find.descendant(
        of: find.byType(HeaderPattern),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
  });

  test('the painter repaints only when its tile or colour changes', () {
    const a = MashrabiyaPainter(tile: 28);
    expect(a.shouldRepaint(const MashrabiyaPainter(tile: 28)), isFalse);
    expect(a.shouldRepaint(const MashrabiyaPainter(tile: 32)), isTrue);
  });

  test('the painter draws a lattice without failing at any size', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (final size in [Size.zero, const Size(375, 300), const Size(1, 1)]) {
      const MashrabiyaPainter(tile: 28).paint(canvas, size);
    }
    const MashrabiyaPainter(tile: 0).paint(canvas, const Size(375, 300));
    expect(recorder.endRecording(), isNotNull);
  });
}
