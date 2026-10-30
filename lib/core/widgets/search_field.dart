import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The hero control (Design System → SearchField): one clear-glass pill,
/// 48 tall, magnifying glass at the start, a clear (×) once there's text.
/// With [onTap] and no [controller] it's an entry point (Home header) that
/// opens the search screen instead of taking input.
class SearchField extends StatelessWidget {
  const new({
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.tone = GlassTone.dark,
    super.key,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Entry-point mode: the whole pill is a button.
  final VoidCallback? onTap;
  final bool autofocus;
  final GlassTone tone;

  /// Queries longer than this are cut (search only reads 60 characters).
  static const maxLength = 60;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lite = AppUi.isLite(context);
    final content = lite || tone == GlassTone.light
        ? (lite ? context.palette.ink : AppColors.onGlassLight)
        : AppColors.onGlassDark;
    final style = context
        .text(TextRole.body)
        .copyWith(color: content, fontWeight: FontWeight.w500);
    final hint = context
        .text(TextRole.body)
        .copyWith(color: content.withValues(alpha: 0.75));
    final controller = this.controller;

    final input = controller == null
        ? Text(l10n.searchPlaceholder, style: hint, maxLines: 1)
        : TextField(
            controller: controller,
            autofocus: autofocus,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            cursorColor: content,
            style: style,
            // Fills the 48-tall pill, so the whole pill is the tap target.
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.center,
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            decoration: InputDecoration.collapsed(
              hintText: l10n.searchPlaceholder,
              hintStyle: hint,
            ).copyWith(semanticCounterText: ''),
          );

    final pill = AppGlass(
      kind: GlassKind.clear,
      tone: tone,
      radius: AppDimens.searchHeight / 2,
      padding: EdgeInsetsDirectional.only(start: AppDimens.space4),
      child: SizedBox(
        height: AppDimens.searchHeight,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                AppIcons.search,
                size: AppDimens.icon,
                color: content,
              ),
            ),
            SizedBox(width: AppDimens.space3),
            Expanded(child: input),
            if (controller != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? SizedBox(width: AppDimens.space4)
                    : IconButton(
                        key: const Key('search_clear'),
                        tooltip: l10n.clearSearch,
                        icon: Icon(AppIcons.close, color: content, size: 20),
                        onPressed: () {
                          controller.clear();
                          onChanged?.call('');
                        },
                      ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return Semantics(textField: true, label: l10n.searchLabel, child: pill);
    }
    return Semantics(
      button: true,
      label: l10n.searchLabel,
      hint: l10n.searchPlaceholder,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          key: const Key('search_entry'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: pill,
        ),
      ),
    );
  }
}
