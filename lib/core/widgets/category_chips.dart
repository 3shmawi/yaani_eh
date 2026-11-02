import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';

/// One chip: a category id and its label.
typedef ChipOption = ({String? id, String label});

/// A horizontal, single-select row of categories (Design System →
/// CategoryChips). Over the header band: clear glass, selected = solid
/// warm milk (`AppColors.selected`). Scrolls edge to edge; RTL starts from
/// the right.
///
/// Home puts its section tabs in the same row: [leading] is a second
/// single-select group drawn first, a thin divider between the two, so
/// both scroll together as one row.
class CategoryChips extends StatelessWidget {
  const new({
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.leading = const [],
    this.leadingSelectedId,
    this.onLeadingSelected,
    this.tone = GlassTone.dark,
    super.key,
  });

  final List<ChipOption> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  /// A first group before the divider (Home's sections).
  final List<ChipOption> leading;
  final String? leadingSelectedId;
  final ValueChanged<String?>? onLeadingSelected;
  final GlassTone tone;

  @override
  Widget build(BuildContext context) {
    // One row: the leading group, a divider, then the options.
    final items = <Widget Function()>[
      for (final option in leading)
        () => _Chip(
          label: option.label,
          selected: option.id == leadingSelectedId,
          tone: tone,
          onTap: () => onLeadingSelected?.call(option.id),
        ),
      if (leading.isNotEmpty && options.isNotEmpty)
        () => const _Divider(key: Key('chips_divider')),
      for (final option in options)
        () => _Chip(
          label: option.label,
          selected: option.id == selectedId,
          tone: tone,
          onTap: () => onSelected(option.id),
        ),
    ];
    return SizedBox(
      height: AppDimens.touchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: AppDimens.space4),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: AppDimens.space2),
        itemBuilder: (context, i) => items[i](),
      ),
    );
  }
}

/// A thin line between two groups of chips.
class _Divider extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: Container(
        width: 1,
        height: AppDimens.chipHeight * 0.6,
        color: AppColors.onHeaderMuted.withValues(alpha: 0.5),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final GlassTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = AppDimens.chipHeight;
    final text = Text(
      label,
      style: AppTextStyles.forText(label, TextRole.label),
      maxLines: 1,
    );
    final padding = EdgeInsetsDirectional.symmetric(
      horizontal: AppDimens.space4,
    );
    final face = selected
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.onSelected),
              child: Padding(
                padding: padding,
                child: Center(widthFactor: 1, child: text),
              ),
            ),
          )
        : AppGlass(
            kind: GlassKind.clear,
            tone: tone,
            radius: height / 2,
            padding: padding,
            child: Center(widthFactor: 1, child: text),
          );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppDimens.touchTarget,
              minHeight: AppDimens.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: SizedBox(height: height, child: face),
            ),
          ),
        ),
      ),
    );
  }
}
