import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/welcome/domain/repositories/welcome_repository.dart';

/// [WelcomeRepository] in SharedPreferences (`welcome.seen`). Anything but
/// `true` there (missing, another type) means not seen yet.
class SharedPrefsWelcomeRepository implements WelcomeRepository {
  new(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'welcome.seen';

  @override
  bool get seen {
    final value = _prefs.get(_key);
    return value is bool && value;
  }

  @override
  Future<Result<void>> markSeen() =>
      guard(() => _prefs.setBool(_key, true), retries: 0);
}
