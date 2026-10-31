import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/repositories/taste_repository.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_controller.dart';

/// «ذوقي» kept in memory. [failSave] makes the next save fail.
class FakeTasteRepository implements TasteRepository {
  new([Map<String, TasteProfile>? saved]) : saved = {...?saved};

  final Map<String, TasteProfile> saved;
  bool failSave = false;

  @override
  TasteProfile? load(String section) => saved[section];

  @override
  Future<Result<void>> save(String section, TasteProfile profile) async {
    if (failSave) return const Failed(UnknownFailure());
    saved[section] = profile;
    return const Success(null);
  }
}

List<Override> tasteOverrides([FakeTasteRepository? repository]) => [
  tasteRepositoryProvider.overrideWithValue(
    repository ?? FakeTasteRepository(),
  ),
];
