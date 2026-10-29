import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/theme/app_text_styles.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// Loading / empty / error views every screen uses, so the states look the
/// same across the app (CLAUDE.md → every screen has all states).
class LoadingView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: context.l10n.loading,
      child: const CircularProgressIndicator.adaptive(),
    ),
  );
}

/// Says what's missing and offers the next step (Design System →
/// EmptyState). Copy is kind and specific; never "No data".
class EmptyView extends StatelessWidget {
  const new({
    required this.message,
    this.title,
    this.icon = AppIcons.coffee,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String? title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => StateMessage(
    icon: icon,
    title: title,
    message: message,
    action: actionLabel == null
        ? null
        : AppButton(label: actionLabel!, onPressed: onAction),
  );
}

/// Shown only when there's nothing cached to show; with cached data, keep
/// the content and let the OfflineBanner speak (Design System → ErrorState).
class ErrorView extends StatelessWidget {
  const new({
    required this.failure,
    this.onRetry,
    this.title,
    this.hint,
    super.key,
  });

  final AppFailure failure;
  final VoidCallback? onRetry;

  /// What failed, in words. Without it the failure message is the headline.
  final String? title;

  /// A footnote under the button, e.g. "We retry every 30 seconds".
  final String? hint;

  @override
  Widget build(BuildContext context) => StateMessage(
    icon: failure is NetworkFailure
        ? AppIcons.wifiSlash
        : AppIcons.warningCircle,
    iconColor: context.palette.danger,
    title: title,
    message: failure.message(context.l10n),
    hint: hint,
    action: onRetry == null
        ? null
        : AppButton(label: context.l10n.retry, onPressed: onRetry),
  );
}

/// The shared layout: a `brand-soft` badge, a headline, one sentence, one
/// action and an optional footnote, centered.
class StateMessage extends StatelessWidget {
  const new({
    required this.icon,
    required this.message,
    this.title,
    this.iconColor,
    this.action,
    this.hint,
    super.key,
  });

  final IconData icon;
  final Color? iconColor;
  final String? title;
  final String message;
  final Widget? action;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final badge = 72.r;
    final headline = title ?? message;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppDimens.space6,
          vertical: AppDimens.space8,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: p.brandSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32.r, color: iconColor ?? p.brand),
              ),
              SizedBox(height: AppDimens.space3),
              Semantics(
                header: true,
                child: Text(
                  headline,
                  style: context.text(TextRole.headline).copyWith(color: p.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              if (title != null) ...[
                SizedBox(height: AppDimens.space3),
                Text(
                  message,
                  style: context
                      .text(TextRole.body)
                      .copyWith(color: p.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                SizedBox(height: AppDimens.space4),
                action!,
              ],
              if (hint != null) ...[
                SizedBox(height: AppDimens.space3),
                Text(
                  hint!,
                  style: context
                      .text(TextRole.caption)
                      .copyWith(color: p.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// User-facing message for a failure, in the current language.
extension AppFailureMessage on AppFailure {
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    TimeoutFailure() => l10n.errorTimeout,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    NotFoundFailure() => l10n.errorNotFound,
    ValidationFailure() => l10n.errorValidation,
    ServerFailure() || UnknownFailure() => l10n.errorUnknown,
  };
}
