import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/router/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('items live under /item', () {
      expect(AppRoutes.item('latte'), '/item/latte');
      expect(AppRoutes.itemSteps('latte'), '/item/latte/steps');
    });

    group('fromLegacy', () {
      String? from(String link) => AppRoutes.fromLegacy(Uri.parse(link));

      test('sends old /drink links to /item, query kept', () {
        expect(from('/drink/latte'), '/item/latte');
        expect(from('/drink/latte/steps'), '/item/latte/steps');
        expect(from('/drink/latte/steps?step=2'), '/item/latte/steps?step=2');
        expect(from('/drink'), '/item');
      });

      test('leaves every other path alone', () {
        for (final link in [
          '/',
          '/item/latte',
          '/drinks/latte',
          '/drinkx',
          '/search?q=/drink/latte',
          '/favorites',
        ]) {
          expect(from(link), isNull, reason: link);
        }
      });
    });
  });
}
