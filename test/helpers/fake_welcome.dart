import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/welcome/domain/repositories/welcome_repository.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_controller.dart';

/// The welcome's "seen" flag in memory. Seen by default, so tests that
/// open Home don't land on the welcome. [failSave] makes saving fail.
class FakeWelcomeRepository implements WelcomeRepository {
  new({this.seen = true});

  @override
  bool seen;
  bool failSave = false;

  @override
  Future<Result<void>> markSeen() async {
    if (failSave) return const Failed(UnknownFailure());
    seen = true;
    return const Success(null);
  }
}

List<Override> welcomeOverrides([FakeWelcomeRepository? repository]) => [
  welcomeRepositoryProvider.overrideWithValue(
    repository ?? FakeWelcomeRepository(),
  ),
];
