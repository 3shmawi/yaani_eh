import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/ui/glass_tone.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';

import '../../helpers/pump_app.dart';

ByteData _image(List<int> rgb, {int width = 2, int height = 2}) {
  final bytes = ByteData(width * height * 4);
  for (var i = 0; i < width * height; i++) {
    bytes
      ..setUint8(i * 4, rgb[0])
      ..setUint8(i * 4 + 1, rgb[1])
      ..setUint8(i * 4 + 2, rgb[2])
      ..setUint8(i * 4 + 3, 255);
  }
  return bytes;
}

void main() {
  group(GlassToneResolver, () {
    const all = Rect.fromLTWH(0, 0, 1, 1);

    test('white is light, espresso is dark', () {
      final white = GlassToneResolver.luminance(
        _image([255, 255, 255]),
        2,
        2,
        all,
      );
      final espresso = GlassToneResolver.luminance(
        _image([0x3B, 0x1F, 0x12]),
        2,
        2,
        all,
      );
      expect(white, closeTo(1, 0.001));
      expect(GlassToneResolver.toneFor(white), GlassTone.light);
      expect(GlassToneResolver.toneFor(espresso), GlassTone.dark);
    });

    test('the threshold is 0.40', () {
      expect(GlassToneResolver.toneFor(0.40), GlassTone.light);
      expect(GlassToneResolver.toneFor(0.399), GlassTone.dark);
    });

    test('measures only the region under the control', () {
      // Left column white, right column black.
      final bytes = ByteData(2 * 2 * 4);
      for (final (x, v) in [(0, 255), (1, 0)]) {
        for (var y = 0; y < 2; y++) {
          final i = (y * 2 + x) * 4;
          bytes
            ..setUint8(i, v)
            ..setUint8(i + 1, v)
            ..setUint8(i + 2, v)
            ..setUint8(i + 3, 255);
        }
      }
      final left = GlassToneResolver.luminance(
        bytes,
        2,
        2,
        const Rect.fromLTWH(0, 0, 0.5, 1),
      );
      final right = GlassToneResolver.luminance(
        bytes,
        2,
        2,
        const Rect.fromLTWH(0.5, 0, 0.5, 1),
      );
      expect(left, closeTo(1, 0.001));
      expect(right, closeTo(0, 0.001));
    });

    test('regions outside the image are clamped, never crash', () {
      final value = GlassToneResolver.luminance(
        _image([128, 128, 128]),
        2,
        2,
        const Rect.fromLTWH(-1, -1, 5, 5),
      );
      expect(value, inInclusiveRange(0, 1));
    });

    test('an unreadable image falls back without throwing', () async {
      GlassToneResolver.clearCache();
      final tone = await GlassToneResolver.resolve(
        MemoryImage(Uint8List.fromList([1, 2, 3])),
        const Rect.fromLTWH(0, 0, 1, 1),
      );
      expect(tone, GlassTone.dark);
    });
  });

  group(AppGlass, () {
    testWidgets('lite glass is a solid fill with ink content', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Center(
            child: AppGlass(
              kind: GlassKind.clear,
              tone: GlassTone.dark,
              child: Text('Iced'),
            ),
          ),
        ),
      );
      final fill = tester
          .widgetList<Material>(
            find.ancestor(
              of: find.text('Iced'),
              matching: find.byType(Material),
            ),
          )
          .map((m) => m.color);
      expect(fill, contains(AppPalette.light.glassFillLite));
      final style = DefaultTextStyle.of(tester.element(find.text('Iced')));
      expect(style.style.color, AppPalette.light.ink);
    });

    testWidgets('icon buttons keep a 48 hit area and a label', (tester) async {
      var tapped = 0;
      await tester.pumpApp(
        Scaffold(
          body: Center(
            child: AppIconButton(
              icon: AppIcons.heart,
              tooltip: 'Save',
              selected: false,
              onPressed: () => tapped++,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(AppIconButton)), const Size(48, 48));
      await tester.tap(find.byType(AppIconButton));
      expect(tapped, 1);
      await tester.expectAccessible();
    });

    testWidgets('a selected icon button uses the brand fill', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: Center(
            child: AppIconButton(
              icon: AppIconsFill.heart,
              tooltip: 'Saved',
              selected: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      final icon = IconTheme.of(
        tester.element(find.byIcon(AppIconsFill.heart)),
      );
      expect(icon.color, AppPalette.light.onBrand);
    });
  });

  group(AppButton, () {
    testWidgets('primary, clear and text buttons are tappable and labelled', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpApp(
        Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.espresso),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(label: 'Send', onPressed: () => taps.add('p')),
                  AppButton(
                    label: 'Listen',
                    kind: AppButtonKind.clear,
                    onPressed: () => taps.add('c'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Send'));
      await tester.tap(find.text('Listen'));
      expect(taps, ['p', 'c']);
      expect(
        tester.getSize(find.byType(AppButton).first).height,
        greaterThanOrEqualTo(48),
      );
      await tester.expectAccessible();
    });

    testWidgets('disabled buttons keep their label and ignore taps', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          body: Center(child: AppButton(label: 'Send', onPressed: null)),
        ),
      );
      expect(find.text('Send'), findsOneWidget);
      await tester.tap(find.text('Send'));
    });
  });

  group(HeaderBand, () {
    testWidgets('shows eyebrow, title and subtitle in both languages', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        await tester.pumpApp(
          const Scaffold(
            body: HeaderBand(
              eyebrow: 'يعني إيه؟',
              title: 'المنيو',
              subtitle: 'اطلب وإنت فاهم',
            ),
          ),
          locale: locale,
        );
        expect(find.text('المنيو'), findsOneWidget);
        expect(find.text('اطلب وإنت فاهم'), findsOneWidget);
        await tester.expectAccessible();
      }
    });

    testWidgets('the title is a heading for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const Scaffold(body: HeaderBand(title: 'Menu')));
      expect(
        tester.getSemantics(find.text('Menu')),
        matchesSemantics(label: 'Menu', isHeader: true),
      );
      handle.dispose();
    });
  });
}
