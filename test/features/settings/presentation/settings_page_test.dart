import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaani_eh/core/legal/legal_links.dart';
import 'package:yaani_eh/features/settings/domain/entities/app_settings.dart';
import 'package:yaani_eh/features/settings/domain/repositories/settings_repository.dart';
import 'package:yaani_eh/features/settings/presentation/settings_controller.dart';
import 'package:yaani_eh/features/settings/presentation/settings_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'app',
      packageName: 'com.example.app',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  testWidgets('opens the website legal pages', (tester) async {
    final opened = <Uri>[];
    await tester.pumpApp(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(_Settings()),
          openLinkProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        child: const SettingsPage(),
      ),
    );

    await tester.tap(find.text(l10nEn.settingsPrivacy));
    await tester.tap(find.text(l10nEn.settingsTerms));
    expect(opened, [LegalLinks.privacy, LegalLinks.terms]);
  });
}

class _Settings implements SettingsRepository {
  @override
  AppSettings load() => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}
