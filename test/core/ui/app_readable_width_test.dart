import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';

void main() {
  Future<double> widthOn(WidgetTester tester, Size screen) async {
    tester.view
      ..physicalSize = screen * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: AppReadableWidth(child: SizedBox.expand(key: Key('c'))),
      ),
    );
    return tester.getSize(find.byKey(const Key('c'))).width;
  }

  testWidgets('a phone keeps its full width', (tester) async {
    expect(await widthOn(tester, const Size(375, 812)), 375);
  });

  testWidgets('a tablet centres the column at the readable width', (
    tester,
  ) async {
    expect(
      await widthOn(tester, const Size(1376, 1032)),
      AppDimens.readableWidth,
    );
    expect(tester.getCenter(find.byKey(const Key('c'))).dx, 1376 / 2);
  });

  testWidgets('slivers too', (tester) async {
    tester.view
      ..physicalSize = const Size(2064, 2752)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: [
            SliverAppReadableWidth(
              sliver: SliverToBoxAdapter(
                child: SizedBox(height: 10, key: Key('row')),
              ),
            ),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('row'))).width,
      AppDimens.readableWidth,
    );
  });
}
