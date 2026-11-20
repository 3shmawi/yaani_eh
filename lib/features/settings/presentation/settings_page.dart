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
      onOpenPrivacy: () => unawaited(open(LegalLinks.privacy)),
      onOpenTerms: () => unawaited(open(LegalLinks.terms)),
      onOpenLicenses: () => showLicensePage(context: context),
    );
  }
}
