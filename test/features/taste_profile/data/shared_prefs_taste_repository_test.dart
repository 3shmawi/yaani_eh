import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/taste_profile/data/repositories/shared_prefs_taste_repository.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';

void main() {
  Future<SharedPrefsTasteRepository> create([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPrefsTasteRepository(await SharedPreferences.getInstance());
  }

  test('nothing saved: no taste yet', () async {
    expect((await create()).load('cafe'), isNull);
  });

  test('saves and loads, per section', () async {
    final repository = await create();
    const taste = TasteProfile({'temp': 'cold', 'sweetness': 2, 'milk': true});
    expect(await repository.save('cafe', taste), isA<Success<void>>());
    expect(repository.load('cafe'), taste);
    expect(repository.load('desserts'), isNull);
  });

  test('every answer «مش فارقة» is still a taken quiz', () async {
    final repository = await create();
    await repository.save('cafe', const TasteProfile({}));
    expect(repository.load('cafe'), const TasteProfile({}));
  });

  test('a broken or hostile stored value means no taste', () async {
    for (final raw in ['not json', '[1, 2]', '"cold"']) {
      final repository = await create({'taste.cafe': raw});
      expect(repository.load('cafe'), isNull, reason: raw);
    }
  });

  test('answers of an odd type are dropped, the rest kept', () async {
    final repository = await create({
      'taste.cafe': '{"temp": "cold", "x": {"a": 1}, "y": [1], "z": null}',
    });
    expect(repository.load('cafe'), const TasteProfile({'temp': 'cold'}));
  });
}
