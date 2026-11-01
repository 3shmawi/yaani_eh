import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/update/update_service.dart';

void main() {
  group('UpdateService.safeStoreUrl', () {
    test('accepts the App Store and Google Play over https', () {
      for (final url in [
        'https://apps.apple.com/app/id6828498341',
        'https://play.google.com/store/apps/details?id=com.mohager.yaanieh',
      ]) {
        expect(UpdateService.safeStoreUrl(url), Uri.parse(url), reason: url);
      }
    });

    test('rejects anything else', () {
      for (final value in <Object?>[
        null,
        42,
        '',
        'http://apps.apple.com/app/id6828498341',
        'https://evil.example.com/apps.apple.com',
        'https://apps.apple.com.evil.example.com/app/id1',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'intent://play.google.com#Intent;end',
      ]) {
        expect(UpdateService.safeStoreUrl(value), isNull, reason: '$value');
      }
    });
  });
}
