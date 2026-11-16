import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// A group's name above its card: small, bold, muted (the iOS settings
/// layout).
class SettingsSectionHeader extends StatelessWidget {
  const new(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.space4,
        AppDimens.space6,
        AppDimens.space4,
        AppDimens.space2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: context
              .text(TextRole.label)
              .copyWith(color: context.palette.inkMuted),
        ),
      ),
    );
  }
}

/// A card of [SettingsRow]s with hairlines between them.
class SettingsGroup extends StatelessWidget {
  const new({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space1,
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppDimens.icon + AppDimens.space3,
                color: p.line,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// One settings row, at least 52 high: an icon, the label at the start,
/// the current value at the end, and a chevron when it opens something.
class SettingsRow extends StatelessWidget {
  const new({
    required this.label,
    this.icon,
    this.value,
    this.valueKey,
    this.valueDirection,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final String? value;

  /// For tests that read the value.
  final Key? valueKey;

  /// LTR for numbers like `1.2.3 (45)`, which would read reversed in Arabic.
  final TextDirection? valueDirection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = context.text(TextRole.body);
    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: math.max(AppDimens.touchTarget, AppDimens.settingsRow),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: AppDimens.space2),
        child: Row(
          spacing: AppDimens.space3,
          children: [
            if (icon case final icon?)
              Icon(icon, size: AppDimens.icon, color: p.brand),
            Expanded(
              child: Text(
                label,
                style: body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
              ),
            ),
            // Next to the chevron at the end edge; a long value wraps.
            if (value case final value?)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: AppDimens.settingsValue),
                child: Text(
                  value,
                  key: valueKey,
                  textDirection: valueDirection,
                  textAlign: TextAlign.end,
                  style: body.copyWith(color: p.inkMuted),
                ),
              ),
            // Mirrors in RTL: points to the end edge in both languages.
            if (onTap != null)
              Icon(
                AppIcons.forward,
                size: AppDimens.iconChip,
                color: p.inkMuted,
              ),
          ],
        ),
      ),
    );
    if (onTap == null) return MergeSemantics(child: row);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: row,
        ),
      ),
    );
  }
}

/// A row of the choice sheet: the label, and a check mark when [selected].
/// Selection is shown by the check and weight, not by colour, so the label
/// keeps full contrast on glass.
class SettingsChoiceRow extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(AppDimens.touchTarget, AppDimens.settingsRow),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space2,
              ),
              child: Row(
                spacing: AppDimens.space3,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context
                          .text(TextRole.body)
                          .copyWith(
                            color: p.ink,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                  ),
                  if (selected)
                    Icon(AppIcons.check, size: AppDimens.icon, color: p.brand),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a sheet to pick one of [choices] (language, theme). Returns the
/// picked index, or null when it's closed without a pick.
Future<int?> showSettingsChoice(
  BuildContext context, {
  required String title,
  required List<String> choices,
  required int selected,
}) async {
  int? picked;
  await showAppSheet(
    context,
    closeLabel: context.l10n.recipeClose,
    builder: (sheet) => SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.space4,
        0,
        AppDimens.space4,
        AppDimens.space6,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppDimens.space1,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space2,
                vertical: AppDimens.space2,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: sheet
                      .text(TextRole.headline)
                      .copyWith(color: sheet.palette.ink),
                ),
              ),
            ),
            for (final (i, label) in choices.indexed)
              SettingsChoiceRow(
                key: Key('settings_choice_$i'),
                label: label,
                selected: i == selected,
                onTap: () {
                  picked = i;
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
  return picked;
}

/// The installed app version and build number, e.g. `1.2.3 (45)`. Read from
/// the platform (pubspec `version: 1.2.3+45`), so it always matches what the
/// stores and the update gate see. Empty until it loads.
class SettingsVersionTile extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return SettingsRow(
          label: l10n.settingsVersion,
          icon: AppIcons.info,
          valueKey: const Key('settings_version'),
          valueDirection: TextDirection.ltr,
          value: info == null
              ? null
              : l10n.settingsVersionValue(info.version, info.buildNumber),
        );
      },
    );
  }
}
