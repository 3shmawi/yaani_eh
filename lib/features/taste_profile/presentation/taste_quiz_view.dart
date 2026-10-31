import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/header_pattern.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/usecases/match_taste.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// «ذوقي» (design: Quiz A): one question per screen on the header band,
/// big choice cards. Choosing one ticks, then moves on; «مش فارقة معايا»
/// skips it. The last answer finishes with every answer given.
class TasteQuizView extends StatefulWidget {
  const new({
    required this.questions,
    required this.onFinish,
    required this.onClose,
    this.initial = const TasteProfile({}),
    super.key,
  });

  final List<TasteQuestion> questions;
  final TasteProfile initial;
  final ValueChanged<TasteProfile> onFinish;

  /// ✕: leaves without saving; the question it was on, for analytics.
  final ValueChanged<int> onClose;

  @override
  State<TasteQuizView> createState() => _TasteQuizViewState();
}

class _TasteQuizViewState extends State<TasteQuizView> {
  late final Map<String, Object> _answers = {...widget.initial.answers};
  var _index = 0;
  Timer? _advance;

  TasteQuestion get _question => widget.questions[_index];

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _next() {
    if (_index == widget.questions.length - 1) {
      unawaited(HapticFeedback.mediumImpact());
      widget.onFinish(TasteProfile({..._answers}));
    } else {
      setState(() => _index++);
    }
  }

  void _choose(TasteOption option) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _answers[_question.key] = option.value);
    // A beat to see the choice land, then the next question.
    _advance?.cancel();
    _advance = Timer(
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.jump,
      _next,
    );
  }

  void _skip() {
    _advance?.cancel();
    _answers.remove(_question.key);
    _next();
  }

  void _back() {
    _advance?.cancel();
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final flat = AppUi.isLite(context);
    final q = _question;
    final total = widget.questions.length;
    return Material(
      key: const Key('taste_quiz'),
      color: AppColors.espresso,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: flat
              ? null
              : const LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [AppColors.headerTop, AppColors.headerBottom],
                ),
        ),
        child: Stack(
          children: [
            if (!flat) const Positioned.fill(child: HeaderPattern()),
            SafeArea(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppDimens.space5,
                  AppDimens.space2,
                  AppDimens.space5,
                  AppDimens.space4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Progress(done: _index + 1, total: total),
                        ),
                        SizedBox(width: AppDimens.space3),
                        AppIconButton(
                          key: const Key('taste_close'),
                          icon: AppIcons.close,
                          tooltip: l10n.tasteClose,
                          tone: GlassTone.dark,
                          onPressed: () => widget.onClose(_index),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsetsDirectional.only(
                          top: AppDimens.space8,
                          bottom: AppDimens.space4,
                        ),
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : AppMotion.select,
                          child: Column(
                            key: ValueKey(_index),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.tasteQuestionOf(_index + 1, total),
                                style: context
                                    .text(TextRole.label)
                                    .copyWith(color: AppColors.onHeaderMuted),
                              ),
                              SizedBox(height: AppDimens.space2),
                              Semantics(
                                header: true,
                                child: Text(
                                  q.question(arabic: arabic),
                                  style: context
                                      .text(TextRole.largeTitle)
                                      .copyWith(color: AppColors.onHeader),
                                ),
                              ),
                              SizedBox(height: AppDimens.space2),
                              Text(
                                l10n.tasteHint,
                                style: context
                                    .text(TextRole.callout)
                                    .copyWith(color: AppColors.onHeaderMuted),
                              ),
                              SizedBox(height: AppDimens.space6),
                              for (final (i, option) in q.options.indexed) ...[
                                if (i > 0) SizedBox(height: AppDimens.space3),
                                _Choice(
                                  key: Key('taste_option_${q.key}_$i'),
                                  label: option.label(arabic: arabic),
                                  icon: _iconFor(q, option),
                                  selected: _answers[q.key] == option.value,
                                  onTap: () => _choose(option),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        AnimatedOpacity(
                          opacity: _index == 0 ? 0 : 1,
                          duration: AppMotion.select,
                          child: IgnorePointer(
                            ignoring: _index == 0,
                            child: ExcludeSemantics(
                              excluding: _index == 0,
                              child: AppIconButton(
                                key: const Key('taste_previous'),
                                icon: AppIcons.back,
                                tooltip: l10n.tastePrevious,
                                tone: GlassTone.dark,
                                onPressed: _back,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimens.space3),
                        Expanded(
                          child: AppButton(
                            key: const Key('taste_skip'),
                            kind: AppButtonKind.band,
                            expand: true,
                            label: l10n.tasteNoPreference,
                            onPressed: _skip,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hot, iced or either: the question about temperature gets pictures.
  static IconData? _iconFor(TasteQuestion q, TasteOption option) =>
      switch (option.value) {
        'hot' => AppIcons.hot,
        'cold' => AppIcons.cold,
        MatchTaste.both => AppIcons.hotOrCold,
        _ => null,
      };
}

/// A segment per question; answered and current ones in warm milk.
class _Progress extends StatelessWidget {
  const new({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.tasteQuestionOf(done, total),
    liveRegion: true,
    excludeSemantics: true,
    child: Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: AppDimens.space1),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.select,
              height: AppDimens.progressHeight,
              decoration: BoxDecoration(
                color: i < done ? AppColors.selected : AppColors.onHeaderFaint,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// One answer: a big card; chosen → warm milk, like a selected chip.
class _Choice extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onSelected : AppColors.onHeader;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AppPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.select,
          constraints: BoxConstraints(minHeight: AppDimens.choiceHeight),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space4,
            vertical: AppDimens.space3,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.selected : AppColors.onHeaderFaint,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimens.icon, color: fg),
                SizedBox(width: AppDimens.space3),
              ],
              Expanded(
                child: Text(
                  label,
                  style: context.text(TextRole.headline).copyWith(color: fg),
                ),
              ),
              if (selected)
                Icon(AppIcons.check, size: AppDimens.icon, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
