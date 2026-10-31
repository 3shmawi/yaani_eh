import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/features/welcome/presentation/welcome_controller.dart';
import 'package:yaani_eh/features/welcome/presentation/widgets/welcome_art.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The first-open welcome (design: Welcome 1–3): three pages on the header
/// band, swiped or moved with «التالي». «تخطّي» leaves from the first two;
/// the last offers «قولنا ذوقك» (the quiz) or the menu straight away.
class WelcomeView extends StatefulWidget {
  const new({required this.onExit, super.key});

  /// How it ended, and on which page (1–3), for analytics.
  final void Function(WelcomeExit exit, int page) onExit;

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  static const _pages = 3;
  final _controller = PageController();
  var _page = 0;

  bool get _last => _page == _pages - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(duration: AppMotion.step, curve: AppMotion.enter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Keeps the pages still while the buttons under them change.
    const reserved = SizedBox(height: AppDimens.touchTarget);
    return BandBackground(
      key: const Key('welcome'),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppDimens.space6,
            AppDimens.space2,
            AppDimens.space6,
            AppDimens.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _last
                    ? reserved
                    : AppButton(
                        key: const Key('welcome_skip'),
                        label: l10n.welcomeSkip,
                        kind: AppButtonKind.bandText,
                        onPressed: () =>
                            widget.onExit(WelcomeExit.skip, _page + 1),
                      ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _Page(
                      art: const WelcomeArt.menu(),
                      title: l10n.welcomeMenuTitle,
                      body: l10n.welcomeMenuBody,
                    ),
                    _Page(
                      art: const WelcomeArt.hear(),
                      title: l10n.welcomeHearTitle,
                      body: l10n.welcomeHearBody,
                    ),
                    _Page(
                      art: const WelcomeArt.taste(),
                      title: l10n.welcomeTasteTitle,
                      body: l10n.welcomeTasteBody,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppDimens.space4),
              _Dots(index: _page, count: _pages),
              SizedBox(height: AppDimens.space4),
              if (_last)
                AppButton(
                  key: const Key('welcome_taste'),
                  label: l10n.welcomeStartTaste,
                  kind: AppButtonKind.band,
                  expand: true,
                  onPressed: () => widget.onExit(WelcomeExit.taste, _pages),
                )
              else
                AppButton(
                  key: const Key('welcome_next'),
                  label: l10n.welcomeNext,
                  kind: AppButtonKind.band,
                  expand: true,
                  onPressed: _next,
                ),
              if (_last)
                AppButton(
                  key: const Key('welcome_menu'),
                  label: l10n.welcomeOpenMenu,
                  kind: AppButtonKind.bandText,
                  onPressed: () => widget.onExit(WelcomeExit.menu, _pages),
                )
              else
                reserved,
            ],
          ),
        ),
      ),
    );
  }
}

/// One page: the picture, as big as fits (at most 55% of the page, so the
/// text always has room), then the title and the text. Very large text
/// scrolls.
class _Page extends StatelessWidget {
  const new({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: math.min(
                AppDimens.welcomeArtHeight,
                box.maxHeight * 0.55,
              ),
              child: FittedBox(fit: BoxFit.scaleDown, child: art),
            ),
            SizedBox(height: AppDimens.space6),
            Semantics(
              header: true,
              child: Text(
                title,
                style: context
                    .text(TextRole.largeTitle)
                    .copyWith(color: AppColors.onHeader),
              ),
            ),
            SizedBox(height: AppDimens.space3),
            Text(
              body,
              style: context
                  .text(TextRole.body)
                  .copyWith(color: AppColors.onHeaderMuted),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Which page this is: the current one a wide warm-milk dash.
class _Dots extends StatelessWidget {
  const new({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.welcomePageOf(index + 1, count),
    child: ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(width: AppDimens.space1 * 1.5),
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.select,
              width: i == index
                  ? AppDimens.welcomeDotActive
                  : AppDimens.welcomeDot,
              height: AppDimens.welcomeDot,
              decoration: BoxDecoration(
                color: i == index
                    ? AppColors.selected
                    : AppColors.onHeaderFaint,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
