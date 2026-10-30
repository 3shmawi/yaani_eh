import 'package:flutter/material.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/text/bidi.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/pronunciation/domain/entities/pronunciation.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// What one segment of the pill is doing.
enum SegmentState { idle, loading, playing, failed }

/// The PronounceButton (Design System): a clear-glass pill over the drink
/// photo with a segment per recorded voice («زي الباريستا», «الأصلي») and
/// a `0.75×` speed toggle. The playing segment fills `brand` with moving
/// bars; tapping it stops. A failure shows its reason in a frosted note
/// under the pill. Only takes data and callbacks.
class PronouncePill extends StatelessWidget {
  const new({
    required this.name,
    required this.voices,
    required this.speed,
    required this.onToggle,
    required this.onToggleSpeed,
    this.states = const {},
    this.failure,
    this.tone = GlassTone.dark,
    super.key,
  });

  /// The drink's menu name, for screen readers.
  final String name;

  /// The voices that have a clip, in order. Empty: nothing is drawn.
  final List<Voice> voices;

  /// Voices that aren't idle.
  final Map<Voice, SegmentState> states;
  final PlaybackSpeed speed;

  /// Why the last tap failed, shown under the pill.
  final AppFailure? failure;
  final ValueChanged<Voice> onToggle;
  final VoidCallback onToggleSpeed;
  final GlassTone tone;

  @override
  Widget build(BuildContext context) {
    if (voices.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final failure = this.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGlass(
          kind: GlassKind.clear,
          tone: tone,
          radius: AppDimens.radiusPill,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final voice in voices)
                Flexible(
                  child: _Segment(
                    key: Key('pronounce_${voice.name}'),
                    label: switch (voice) {
                      Voice.barista => l10n.pronounceBarista,
                      Voice.original => l10n.pronounceOriginal,
                    },
                    semanticsLabel: switch ((voice, states[voice])) {
                      (_, SegmentState.playing || SegmentState.loading) =>
                        l10n.pronounceStopOf(name),
                      (Voice.barista, _) => l10n.pronounceBaristaOf(name),
                      (Voice.original, _) => l10n.pronounceOriginalOf(name),
                    },
                    state: states[voice] ?? SegmentState.idle,
                    onTap: () => onToggle(voice),
                  ),
                ),
              _SpeedToggle(
                slow: speed == PlaybackSpeed.slow,
                onTap: onToggleSpeed,
              ),
            ],
          ),
        ),
        if (failure != null) ...[
          SizedBox(height: AppDimens.space2),
          PronounceFailureNote(failure: failure),
        ],
      ],
    );
  }
}

/// The reason a clip didn't play, in a frosted note; announced to screen
/// readers when it appears.
class PronounceFailureNote extends StatelessWidget {
  const new({required this.failure, super.key});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AppGlass(
      key: const Key('pronounce_failure'),
      radius: AppDimens.radiusMd,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space3,
        vertical: AppDimens.space2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            failure is NetworkFailure || failure is TimeoutFailure
                ? AppIcons.wifiSlash
                : AppIcons.warningCircle,
            size: AppDimens.iconChip,
          ),
          SizedBox(width: AppDimens.space2),
          Flexible(
            child: Text(
              pronounceFailureMessage(context, failure),
              style: context.text(TextRole.caption),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The words for a failed clip: offline, missing, or something else.
String pronounceFailureMessage(BuildContext context, AppFailure failure) {
  final l10n = context.l10n;
  return switch (failure) {
    NetworkFailure() || TimeoutFailure() => l10n.pronounceOffline,
    NotFoundFailure() => l10n.pronounceMissing,
    _ => l10n.pronounceError,
  };
}

class _Segment extends StatelessWidget {
  const new({
    required this.label,
    required this.semanticsLabel,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final SegmentState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = state == SegmentState.playing || state == SegmentState.loading;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          state == SegmentState.failed
              ? AppIcons.warningCircle
              : AppIcons.speaker,
          size: AppDimens.iconChip,
        ),
        SizedBox(width: AppDimens.space2),
        // Shrinks before it overflows (small phones, large text).
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text(TextRole.label),
          ),
        ),
        if (state == SegmentState.playing) ...[
          SizedBox(width: AppDimens.space2),
          const SoundBars(),
        ],
        if (state == SegmentState.loading) ...[
          SizedBox(width: AppDimens.space2),
          SizedBox.square(
            dimension: AppDimens.space4,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(p.onBrand),
            ),
          ),
        ],
      ],
    );
    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(minHeight: AppDimens.pronounceSegment),
      padding: EdgeInsetsDirectional.only(
        start: AppDimens.space3,
        end: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: on ? p.brand : p.brand.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: on
          ? IconTheme.merge(
              data: IconThemeData(color: p.onBrand),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: p.onBrand),
                child: content,
              ),
            )
          : content,
    );
    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppDimens.touchTarget),
            child: Center(widthFactor: 1, child: face),
          ),
        ),
      ),
    );
  }
}

class _SpeedToggle extends StatelessWidget {
  const new({required this.slow, required this.onTap});

  final bool slow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = DefaultTextStyle.of(context).style.color ?? p.ink;
    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(
        minHeight: AppDimens.pronounceSegment,
        minWidth: AppDimens.space10,
      ),
      alignment: Alignment.center,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppDimens.space2),
      decoration: BoxDecoration(
        color: slow ? p.brand : p.brand.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: slow ? p.brand : color),
      ),
      child: Text(
        Bidi.ltr('0.75×'),
        style: context
            .text(TextRole.caption)
            .copyWith(
              fontWeight: FontWeight.w600,
              color: slow ? p.onBrand : color,
            ),
      ),
    );
    return Semantics(
      button: true,
      toggled: slow,
      label: context.l10n.pronounceSlower,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          key: const Key('pronounce_speed'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.touchTarget,
              minWidth: AppDimens.touchTarget,
            ),
            child: Center(child: face),
          ),
        ),
      ),
    );
  }
}

/// Three bars that move while a name plays; still with Reduce Motion.
class SoundBars extends StatefulWidget {
  const new({super.key});

  @override
  State<SoundBars> createState() => _SoundBarsState();
}

class _SoundBarsState extends State<SoundBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Resting heights from the design (6, 14, 9 of 16).
  static const List<double> _rest = [6 / 16, 14 / 16, 9 / 16];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? context.palette.onBrand;
    final height = AppDimens.space4;
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, rest) in _rest.indexed) ...[
              if (i > 0) const SizedBox(width: AppDimens.soundBarGap),
              Container(
                width: AppDimens.soundBarWidth,
                height:
                    height *
                    (0.3 + 0.7 * ((rest + _controller.value * (i + 1)) % 1)),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppDimens.soundBarGap),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
