import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';

/// Where «ذوقي» is kept: on the phone, one profile per section.
abstract interface class TasteRepository {
  /// The saved profile for [section] (a section slug), or null when the
  /// quiz was never taken there.
  TasteProfile? load(String section);

  Future<Result<void>> save(String section, TasteProfile profile);
}
