import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/browse/domain/usecases/build_browse.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// One section on Home: its picture (the section's icon on the band's
/// espresso), name, how many items it has and the first few names. A
/// section without items yet says «جاي قريب»; it still opens (its page
/// says the same). Read as one button by screen readers.
class SectionCard extends StatelessWidget {
  const new({required this.section, required this.onTap, super.key});

  final HubSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final s = section.section;
    final name = arabic ? s.nameAr : s.nameEn;
    final detail = section.hasItems
        ? l10n.sectionItemCount(section.count)
        : l10n.comingSoonBadge;
    final examples = section.examples
        .map((i) => arabic ? i.menuNameAr : i.menuName)
        .join(arabic ? '، ' : ', ');
    final more = section.count > section.examples.length ? '…' : '';

    return Semantics(
      button: true,
      label: l10n.sectionCardLabel(name, detail),
      hint: section.hasItems ? examples : null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AppPressable(
          onTap: onTap,
          // Frosted like AppCard, but minimal glass: a list of cards
          // (docs/design.md), and the iOS simulator flagged slow frames
          // with every card at full quality under the tab bar.
          child: AppGlass(
            minimal: true,
            padding: EdgeInsets.all(AppDimens.space3),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimens.touchTarget,
              ),
              child: Row(
                children: [
                  _Art(section: section),
                  SizedBox(width: AppDimens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.forText(
                            name,
                            TextRole.headline,
                          ).copyWith(color: p.ink),
                        ),
                        if (section.hasItems) ...[
                          Text(
                            detail,
                            style: context
                                .text(TextRole.caption)
                                .copyWith(color: p.inkMuted),
                          ),
                          SizedBox(height: AppDimens.space1),
                          Text(
                            '$examples$more',
                            style: AppTextStyles.forText(
                              examples,
                              TextRole.callout,
                            ).copyWith(color: p.ink),
                          ),
                        ] else ...[
                          SizedBox(height: AppDimens.space1),
                          _SoonBadge(label: detail),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: AppDimens.space2),
                  Icon(
                    AppIcons.forward,
                    size: AppDimens.iconChip,
                    color: p.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The section's icon on a small espresso tile (faint when it's empty).
class _Art extends StatelessWidget {
  const new({required this.section});

  final HubSection section;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = AppDimens.sectionArt;
    final filled = section.hasItems;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        color: filled ? null : p.brandSoft,
        gradient: filled
            ? const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [AppColors.headerTop, AppColors.headerBottom],
              )
            : null,
      ),
      child: Icon(
        AppIcons.forSection(section.section.icon),
        size: AppDimens.sectionArtIcon,
        color: filled ? AppColors.selected : p.inkMuted,
      ),
    );
  }
}

class _SoonBadge extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      key: const Key('section_soon_badge'),
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppDimens.space2,
          vertical: AppDimens.space1 / 2,
        ),
        child: Text(
          label,
          style: context.text(TextRole.label).copyWith(color: p.brand),
        ),
      ),
    );
  }
}
