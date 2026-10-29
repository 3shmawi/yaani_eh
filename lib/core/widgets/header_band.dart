import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';

/// The espresso gradient that opens list screens (Home, Favorites, first
/// launch, errors). It reads the same in both themes and gives clear glass
/// something to sit on; controls inside use the dark tone.
class HeaderBand extends StatelessWidget {
  const new({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.bottom,
    this.trailing,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;

  /// Search field and chips, under the titles.
  final Widget? bottom;

  /// A control at the end of the title row (clear glass, dark tone).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(AppDimens.radiusXl);
    final top = MediaQuery.paddingOf(context).top;
    final muted = context
        .text(TextRole.callout)
        .copyWith(color: AppColors.onHeaderMuted);
    // Reduce Transparency / Increase Contrast (and tests): a flat espresso
    // band, the plainest and highest-contrast version.
    final flat = AppUi.isLite(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: radius),
        color: flat ? AppColors.espresso : null,
        gradient: flat
            ? null
            : const LinearGradient(
                // 165° in CSS: top, leaning slightly toward the end edge.
                begin: Alignment(-0.26, -1),
                end: Alignment(0.26, 1),
                colors: [
                  AppColors.headerTop,
                  AppColors.espresso,
                  AppColors.headerBottom,
                ],
                stops: [0, 0.55, 1],
              ),
      ),
      child: DecoratedBox(
        // The soft crema glow in the top-end corner.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: radius),
          gradient: flat
              ? null
              : RadialGradient(
                  center: AlignmentDirectional.topEnd.resolve(
                    Directionality.of(context),
                  ),
                  radius: 0.9,
                  colors: const [Color(0x8CC9874F), Color(0x00C9874F)],
                ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppDimens.space4,
            top + AppDimens.space3,
            AppDimens.space4,
            AppDimens.space5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null)
                          Text(
                            eyebrow!,
                            style: context
                                .text(TextRole.label)
                                .copyWith(color: AppColors.onHeaderMuted),
                          ),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: context
                                .text(TextRole.largeTitle)
                                .copyWith(color: AppColors.onHeader),
                          ),
                        ),
                        if (subtitle != null) Text(subtitle!, style: muted),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (bottom != null) ...[
                SizedBox(height: AppDimens.space4),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
