import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/repositories/taste_repository.dart';

/// [TasteRepository] in SharedPreferences: `taste.<section>` holds the
/// answers as JSON. Nothing leaves the phone.
class SharedPrefsTasteRepository implements TasteRepository {
  new(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String section) => 'taste.$section';

  @override
  TasteProfile? load(String section) {
    final raw = _prefs.getString(_key(section));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return TasteProfile({
        for (final MapEntry(:key, :value) in json.entries)
          if (key is String &&
              (value is String || value is int || value is bool))
            key: value as Object,
      });
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Result<void>> save(String section, TasteProfile profile) => guard(
    () => _prefs.setString(_key(section), jsonEncode(profile.answers)),
    retries: 0,
  );
}
