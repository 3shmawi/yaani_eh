import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The slim bar pinned at the top of Home and the section pages: [leading],
/// the [chips] and a search button at the end. Like iOS, tapping the button
/// grows it into a full-width search field while the rest fades away; then
/// [onOpen] opens the search screen. With Reduce Motion it opens at once.
/// The bar is back to normal by the time the search screen is closed.
class ExpandingSearchBar extends StatefulWidget {
  const new({
    required this.chips,
    required this.onOpen,
    this.leading,
    super.key,
  });

  final Widget? leading;
  final Widget chips;
  final VoidCallback onOpen;

  @override
  State<ExpandingSearchBar> createState() => _ExpandingSearchBarState();
}

class _ExpandingSearchBarState extends State<ExpandingSearchBar> {
  bool _open = false;

  void _tap() {
    if (_open) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onOpen();
      return;
    }
    setState(() => _open = true);
    unawaited(
      Future<void>.delayed(AppMotion.searchExpand, () {
        if (!mounted) return;
        widget.onOpen();
        // Folded back behind the search screen as it slides in.
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _open = false);
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final full = box.maxWidth - AppDimens.space2 * 2;
        return TweenAnimationBuilder<double>(
          tween: Tween(end: _open ? 1 : 0),
          duration: AppMotion.searchExpand,
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => SizedBox(
            height: AppDimens.touchTarget,
            child: Stack(
              children: [
                // Everything else makes way, fading as the field grows.
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: t > 0.01,
                    child: Opacity(
                      opacity: 1 - t,
                      child: Row(
                        children: [
                          SizedBox(width: AppDimens.space2),
                          ?widget.leading,
                          Expanded(child: widget.chips),
                          // Room for the button.
                          SizedBox(
                            width: AppDimens.touchTarget + AppDimens.space2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: AppDimens.space2,
                  top: 0,
                  bottom: 0,
                  width:
                      AppDimens.touchTarget +
                      (full - AppDimens.touchTarget) * t,
                  child: t < 0.35
                      ? Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AppIconButton(
                            key: const Key('section_search_pinned'),
                            icon: AppIcons.search,
                            tooltip: l10n.searchLabel,
                            tone: GlassTone.dark,
                            onPressed: _tap,
                          ),
                        )
                      : ClipRect(
                          child: SearchField(
                            key: const Key('section_search_pinned_field'),
                            onTap: widget.onOpen,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
