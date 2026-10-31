import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_controller.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_quiz_view.dart';
import 'package:yaani_eh/l10n/l10n.dart';

/// `/taste` (`?section=<slug>`): wires «ذوقي» to [TasteQuizView]. Without a
/// section, or with one that has no questions, it uses the first section
/// that has them; none at all says so.
class TastePage extends ConsumerWidget {
  const new({this.section, super.key});

  /// From the link; already checked against the slug rule by the router.
  final String? section;

  void _close(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      Navigator.maybePop(context);
    } else if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loading = ref.watch(catalogCategoriesProvider).value == null;
    final asked = section;
    final slug =
        asked != null && ref.watch(tasteQuestionsProvider(asked)).isNotEmpty
        ? asked
        : ref.watch(defaultTasteSectionProvider);
    final questions = slug == null
        ? null
        : ref.watch(tasteQuestionsProvider(slug));
    if (slug == null || questions == null || questions.isEmpty) {
      return Material(
        color: context.palette.surface,
        child: SafeArea(
          child: loading
              ? const LoadingView()
              : EmptyView(
                  key: const Key('taste_unavailable'),
                  icon: AppIcons.taste,
                  message: l10n.tasteNoQuestions,
                  actionLabel: l10n.tasteClose,
                  onAction: () => _close(context),
                ),
        ),
      );
    }
    return TasteQuizView(
      questions: questions,
      initial: ref.watch(tasteProvider(slug)) ?? const TasteProfile({}),
      onClose: (at) {
        unawaited(
          Analytics.capture('taste_quiz_closed', {
            'section': slug,
            'at': at + 1,
          }),
        );
        _close(context);
      },
      onFinish: (profile) async {
        final saved = await ref
            .read(tasteProvider(slug).notifier)
            .save(profile);
        if (!context.mounted) return;
        if (saved) {
          _close(context);
        } else {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(l10n.tasteSaveFailed)));
        }
      },
    );
  }
}
