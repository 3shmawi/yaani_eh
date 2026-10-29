import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/text/bidi.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/brand_mark.dart';
import 'package:yaani_eh/core/widgets/header_band.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// First launch, before anything is on the device (Loading / Error
/// artboards). Only data and callbacks; the page wires the state.
class CatalogSyncView extends StatelessWidget {
  const new({
    required this.progress,
    required this.failure,
    required this.onRetry,
    this.tipIndex = 0,
    super.key,
  });

  /// Download progress; null while the total isn't known yet.
  final SyncProgress? progress;

  /// Set when the download failed (shows the error state).
  final AppFailure? failure;
  final VoidCallback onRetry;

  /// Which «تعرف إن…» tip to show.
  final int tipIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: context.palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderBand(
            eyebrow: l10n.appEyebrow,
            title: l10n.welcomeTitle,
            subtitle: l10n.welcomeSubtitle,
          ),
          Expanded(
            child: failure == null
                ? _Downloading(progress: progress, tipIndex: tipIndex)
                : _Failed(failure: failure!, onRetry: onRetry),
          ),
        ],
      ),
    );
  }
}

class _Downloading extends StatelessWidget {
  const new({required this.progress, required this.tipIndex});

  final SyncProgress? progress;
  final int tipIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final progress = this.progress;
    final status = progress == null || progress.total == 0
        ? l10n.firstLoadTitle
        : l10n.firstLoadProgressLabel(progress.saved, progress.total);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppDimens.space4,
              AppDimens.space10,
              AppDimens.space4,
              AppDimens.space10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  container: true,
                  liveRegion: true,
                  label: status,
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        BrandMark(size: 132.r, fill: progress?.fraction ?? 0),
                        SizedBox(height: AppDimens.space3),
                        Text(
                          l10n.firstLoadTitle,
                          style: context
                              .text(TextRole.title)
                              .copyWith(color: p.ink),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppDimens.space3),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 300.w),
                          child: Text(
                            l10n.firstLoadBody,
                            style: context
                                .text(TextRole.body)
                                .copyWith(color: p.inkMuted),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: AppDimens.space4),
                        _ProgressBar(progress: progress),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppDimens.space8),
                _TipCard(index: tipIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const new({required this.progress});

  final SyncProgress? progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = this.progress;
    return SizedBox(
      width: 220.w,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            child: LinearProgressIndicator(
              value: progress == null || progress.total == 0
                  ? null
                  : progress.fraction,
              minHeight: 8,
              color: p.brand,
              backgroundColor: p.line,
            ),
          ),
          SizedBox(height: AppDimens.space2),
          Text(
            progress == null || progress.total == 0
                ? ' '
                : context.l10n.firstLoadProgress(
                    progress.saved,
                    progress.total,
                  ),
            style: context
                .text(TextRole.caption)
                .copyWith(
                  color: p.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}

/// «تعرف إن…»: a small fact about a drink name while the menu downloads.
class _TipCard extends StatelessWidget {
  const new({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final tips = [
      ('Cortado', l10n.tipCortado),
      ('Affogato', l10n.tipAffogato),
      ('Macchiato', l10n.tipMacchiato),
    ];
    final (name, text) = tips[index % tips.length];
    final body = context.text(TextRole.body).copyWith(color: p.ink);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.didYouKnow,
            style: context
                .text(TextRole.caption)
                .copyWith(color: p.brand, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppDimens.space1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: Bidi.ltr(name),
                  style: AppTextStyles.forText(
                    name,
                    TextRole.body,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' $text'),
              ],
            ),
            style: body,
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = failure is NetworkFailure || failure is TimeoutFailure;
    return StateMessage(
      icon: offline ? AppIcons.wifiSlash : AppIcons.warningCircle,
      iconColor: context.palette.danger,
      title: offline ? l10n.firstLoadOfflineTitle : l10n.firstLoadFailedTitle,
      message: offline ? l10n.firstLoadOfflineBody : failure.message(l10n),
      action: AppButton(label: l10n.retry, onPressed: onRetry),
      hint: l10n.autoRetryHint,
    );
  }
}
