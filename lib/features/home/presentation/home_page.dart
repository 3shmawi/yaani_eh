import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/adaptive/adaptive.dart';
import 'package:yaani_eh/core/config/app_flavor.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/l10n/l10n.dart';

class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flavor = AppFlavor.current;
    return AppScaffold(
      title: l10n.appTitle,
      actions: [
        AppIconButton(
          key: const Key('home_settings_button'),
          tooltip: l10n.settingsTitle,
          icon: AdaptiveIcons.settings(context),
          onPressed: () => unawaited(context.push<void>(AppRoutes.settings)),
        ),
      ],
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.homeWelcome,
                style: context.text(TextRole.title),
                textAlign: TextAlign.center,
              ),
              if (!flavor.isProd) ...[
                SizedBox(height: AppDimens.space4),
                Chip(label: Text(flavor.name.toUpperCase())),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
