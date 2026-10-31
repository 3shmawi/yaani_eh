import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

CatalogItem _item({String? gistAr, String? gistEn}) => CatalogItem(
  id: 'i',
  categoryId: 'c',
  slug: 'frappe',
  menuName: 'Frappé',
  menuNameAr: 'فرابيه',
  explanationAr: 'قهوة متخفوقة بالتلج واللبن، زي الميلك شيك. حلوة.',
  explanationEn: 'Coffee blended with ice! Like a milkshake.',
  gistAr: gistAr,
  gistEn: gistEn,
);

void main() {
  group('gist', () {
    test('the «يعني» line in the asked language', () {
      final item = _item(
        gistAr: 'قهوة باللبن متخفوقة بالتلج',
        gistEn: 'A coffee shake',
      );
      expect(item.gist(arabic: true), 'قهوة باللبن متخفوقة بالتلج');
      expect(item.gist(arabic: false), 'A coffee shake');
    });

    test("without one, the explanation's first sentence", () {
      final item = _item();
      expect(
        item.gist(arabic: true),
        'قهوة متخفوقة بالتلج واللبن، زي الميلك شيك',
      );
      expect(item.gist(arabic: false), 'Coffee blended with ice');
    });

    test('one language missing falls back on its own', () {
      final item = _item(gistAr: 'قهوة باللبن متخفوقة بالتلج');
      expect(item.gist(arabic: false), 'Coffee blended with ice');
    });
  });
}
