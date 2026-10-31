import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaani_eh/core/analytics/analytics.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/features/welcome/domain/repositories/welcome_repository.dart';

/// Override in tests: `welcomeRepositoryProvider.overrideWithValue(fake)`.
final welcomeRepositoryProvider = Provider<WelcomeRepository>(
  (ref) => Dependencies.welcomeRepository,
);

/// Whether Home may open, or the welcome comes first.
final welcomeSeenProvider = NotifierProvider<WelcomeSeen, bool>(
  WelcomeSeen.new,
);

/// How the welcome ended.
enum WelcomeExit {
  /// «تخطّي» on the first pages.
  skip,

  /// «افتح المنيو على طول» on the last page.
  menu,

  /// «قولنا ذوقك» on the last page: the quiz next.
  taste,
}

class WelcomeSeen extends Notifier<bool> {
  @override
  bool build() => ref.read(welcomeRepositoryProvider).seen;

  /// Marks the welcome seen at once (so Home opens right away) and keeps it.
  /// Saving can fail; the worst case is seeing the welcome once more.
  void finish(WelcomeExit exit, {required int page}) {
    state = true;
    unawaited(ref.read(welcomeRepositoryProvider).markSeen());
    unawaited(
      Analytics.capture(
        exit == WelcomeExit.skip ? 'welcome_skipped' : 'welcome_completed',
        {'page': page, if (exit != WelcomeExit.skip) 'next': exit.name},
      ),
    );
  }
}
