import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/features/welcome/data/repositories/shared_prefs_welcome_repository.dart';

void main() {
  Future<SharedPrefsWelcomeRepository> create([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPrefsWelcomeRepository(await SharedPreferences.getInstance());
  }

  test('a fresh install has not seen the welcome', () async {
    expect((await create()).seen, isFalse);
  });

  test('marks it seen, and it stays seen', () async {
    final repository = await create();
    expect(await repository.markSeen(), isA<Success<void>>());
    expect(repository.seen, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(SharedPrefsWelcomeRepository(prefs).seen, isTrue);
  });

  test('an odd stored value means not seen, never a crash', () async {
    for (final value in <Object>[false, 'true', 1, 'yes', '<script>']) {
      final repository = await create({'welcome.seen': value});
      expect(repository.seen, isFalse, reason: '$value');
    }
  });
}
