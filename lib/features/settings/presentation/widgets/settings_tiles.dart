import 'package:flutter/material.dart';
import 'package:yaani_eh/core/adaptive/adaptive.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';

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
        AppDimens.space1,
      ),
      child: Text(
        title,
        style: context
            .text(TextRole.label)
            .copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// A single-choice row with a check mark when selected.
class SettingsChoiceTile extends StatelessWidget {
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
    // Selection is shown by the check mark and weight, not by text color,
    // so the label keeps full contrast on any surface (glass included).
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        label,
        style: context
            .text(TextRole.body)
            .copyWith(
              color: scheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
      ),
      trailing: selected
          ? Icon(AdaptiveIcons.check(context), color: scheme.primary)
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
