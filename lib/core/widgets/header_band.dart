import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_pattern.dart';

/// The espresso gradient that opens list screens (Home, Favorites, first
/// launch, errors), with the faint mashrabiya pattern behind it. It reads
/// the same in both themes and gives clear glass something to sit on;
/// controls inside use the dark tone.
class HeaderBand extends StatelessWidget {
  const new({
    this.title,
    this.eyebrow,
    this.subtitle,
    this.bottom,
    this.trailing,
    this.leading,
    this.compact = false,
    this.readable = false,
    super.key,
  });

  /// Null for bands that only hold controls (search).
  final String? title;
  final String? eyebrow;
  final String? subtitle;

  /// Search field and chips, under the titles.
  final Widget? bottom;

  /// A control at the end of the title row (clear glass, dark tone).
  final Widget? trailing;

  /// A control at the start of the title row (back), centred on it.
  final Widget? leading;

  /// A page under Home (a section): a smaller title next to [leading].
  final bool compact;

  /// Keep the band's content in [AppReadableWidth] (Home: one column of
  /// titles and search, centred on a tablet); the band itself still runs
  /// edge to edge.
  final bool readable;

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
      child: Stack(
        children: [
          if (!flat)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(bottom: radius),
                child: const HeaderPattern(),
              ),
            ),
          DecoratedBox(
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
              child: _Readable(
                on: readable,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: leading == null
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          SizedBox(width: AppDimens.space3),
                        ],
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
                              if (title != null)
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title!,
                                    style: context
                                        .text(
                                          compact
                                              ? TextRole.title
                                              : TextRole.largeTitle,
                                        )
                                        .copyWith(color: AppColors.onHeader),
                                  ),
                                ),
                              if (subtitle != null)
                                Text(subtitle!, style: muted),
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          SizedBox(width: AppDimens.space3),
                          trailing!,
                        ],
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
          ),
        ],
      ),
    );
  }
}

class _Readable extends StatelessWidget {
  const new({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      on ? AppReadableWidth(child: child) : child;
}

/// A whole screen on the header band's gradient and pattern (the
/// welcome): flat espresso when glass is lite. Text and controls
/// on it use the `onHeader` colours and the dark glass tone.
class BandBackground extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final flat = AppUi.isLite(context);
    return Material(
      color: AppColors.espresso,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: flat
              ? null
              : const LinearGradient(
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
        child: Stack(
          children: [
            if (!flat) const Positioned.fill(child: HeaderPattern()),
            child,
          ],
        ),
      ),
    );
  }
}

/// Wraps a scroll view that opens with a [HeaderBand]: when the list is
/// pulled down past its top (iOS's bounce), the gap above the band is
/// filled with the band's own colour, so the band seems to stretch instead
/// of showing the page behind it.
class HeaderOverscroll extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<HeaderOverscroll> createState() => _HeaderOverscrollState();
}

class _HeaderOverscrollState extends State<HeaderOverscroll> {
  final _stretch = ValueNotifier<double>(0);

  @override
  void dispose() {
    _stretch.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      _stretch.value = (n.metrics.minScrollExtent - n.metrics.pixels).clamp(
        0,
        double.infinity,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ValueListenableBuilder<double>(
        valueListenable: _stretch,
        builder: (context, stretch, _) => PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          // A little more than the gap, so no hairline shows at the seam.
          height: stretch > 0 ? stretch + AppDimens.radiusXl : 0,
          child: const ColoredBox(color: AppColors.headerTop),
        ),
      ),
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
    ],
  );
}

/// The slim espresso bar at the top of the screen once a band has
/// scrolled away (Home: search; a section: back, chips, search), like the
/// band's own bottom, under the status bar.
class PinnedBar extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.espresso,
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(AppDimens.radiusLg),
      ),
      boxShadow: context.palette.glassShadow,
    ),
    child: Padding(
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.paddingOf(context).top + AppDimens.space2,
        bottom: AppDimens.space2,
      ),
      child: child,
    ),
  );
}
