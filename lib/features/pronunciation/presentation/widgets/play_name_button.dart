import 'package:flutter/material.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/pronunciation/presentation/widgets/pronounce_pill.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// The round «اسمع الاسم» button on cards (Home artboard: the drink of the
/// day): a clear-glass IconButton with the speaker. Playing: `brand` fill
/// with the filled speaker; tapping it stops. A failure shows its icon and
/// says why to screen readers. Only takes data and a callback.
class PlayNameButton extends StatelessWidget {
  const new({
    required this.name,
    required this.state,
    required this.onPressed,
    this.failure,
    this.tone = GlassTone.auto,
    super.key,
  });

  /// The drink's menu name, for screen readers.
  final String name;
  final SegmentState state;
  final AppFailure? failure;
  final VoidCallback onPressed;
  final GlassTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = this.failure;
    final active =
        state == SegmentState.playing || state == SegmentState.loading;
    final button = AppIconButton(
      icon: switch (state) {
        SegmentState.playing || SegmentState.loading => AppIconsFill.speaker,
        SegmentState.failed when failure is NetworkFailure =>
          AppIcons.wifiSlash,
        SegmentState.failed => AppIcons.warningCircle,
        SegmentState.idle => AppIcons.speaker,
      },
      tooltip: active ? l10n.pronounceStopOf(name) : l10n.pronounceHearOf(name),
      selected: active,
      tone: tone,
      onPressed: onPressed,
    );
    if (state != SegmentState.failed || failure == null) return button;
    return Semantics(
      liveRegion: true,
      hint: pronounceFailureMessage(context, failure),
      child: button,
    );
  }
}
