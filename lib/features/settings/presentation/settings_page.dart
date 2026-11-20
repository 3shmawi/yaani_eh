import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/legal/legal_links.dart';
import 'package:yaani_eh/features/settings/presentation/settings_controller.dart';
import 'package:yaani_eh/features/settings/presentation/settings_view.dart';

class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);
    final open = ref.read(openLinkProvider);
    return SettingsView(
      settings: ref.watch(settingsControllerProvider),
      onLocaleChanged: controller.setLocale,
      onThemeModeChanged: controller.setThemeMode,
<<<<<<< yours
      onOpenPrivacy: () => unawaited(open(LegalLinks.privacy)),
      onOpenTerms: () => unawaited(open(LegalLinks.terms)),
=======
      onOpenPrivacy: _open(LegalLinks.privacy),
      onOpenTerms: _open(LegalLinks.terms),
>>>>>>> kit 765ff42
      onOpenLicenses: () => showLicensePage(context: context),
    );
  }
}

/// Opens [url] in the browser; null (row hidden) while there's no website.
VoidCallback? _open(Uri? url) =>
    url == null ? null : () => unawaited(openLegalPage(url));
