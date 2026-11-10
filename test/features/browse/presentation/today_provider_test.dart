import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/features/browse/presentation/browse_controller.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';

import '../../../helpers/fake_catalog_remote.dart';
import '../../../helpers/fake_catalog_repository.dart';

void main() {
  tearDown(() => Dependencies.clock = DateTime.now);

  test('today is the real date by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final today = container.read(todayProvider);

    expect(DateTime.now().difference(today).inSeconds, lessThan(5));
  });

  test('today follows the clock Dependencies was given', () {
    Dependencies.clock = () => demoDay;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(todayProvider), demoDay);
  });

  // The pronunciation and catalog sync demos tap the item of the day's
  // speaker and look for "Iced Mocha" once in the list. On an Iced Mocha
  // day (no clip, its name twice on Home) both fail.
  test("the demo day's item of the day has a clip and isn't Iced Mocha", () {
    final model = const BuildBrowse()(
      slug: 'cafe',
      items: sampleCatalogItems(withAudio: true),
      categories: [
        for (final r in sampleCategories()) CatalogRows.category(r)!,
      ],
      today: demoDay,
    );

    final item = model!.itemOfTheDay!;
    expect(item.slug, isNot('iced_mocha'));
    expect(item.audioSpokenPath, isNotNull);
  });
}
