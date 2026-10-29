import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/core/widgets/state_views.dart';

import '../../helpers/pump_app.dart';

void main() {
  group(ErrorView, () {
    testWidgets('shows a friendly message and retries', (tester) async {
      var retried = false;
      await tester.pumpApp(
        Scaffold(
          body: ErrorView(
            failure: const NetworkFailure(),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text(l10nEn.errorNetwork), findsOneWidget);
      await tester.tap(find.text(l10nEn.retry));
      expect(retried, isTrue);
      await tester.expectAccessible();
    });

    testWidgets('shows a title, the message and a hint', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: ErrorView(
            failure: const NetworkFailure(),
            title: 'Menu not loaded',
            hint: 'We retry every 30 seconds',
            onRetry: () {},
          ),
        ),
      );
      expect(find.text('Menu not loaded'), findsOneWidget);
      expect(find.text(l10nEn.errorNetwork), findsOneWidget);
      expect(find.text('We retry every 30 seconds'), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('reads well in Arabic and dark mode', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: ErrorView(failure: const TimeoutFailure(), onRetry: () {}),
        ),
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.expectAccessible();
    });

    testWidgets('never shows technical details', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: ErrorView(failure: UnknownFailure(StateError('db password'))),
        ),
      );
      expect(find.textContaining('db password'), findsNothing);
      expect(find.text(l10nEn.errorUnknown), findsOneWidget);
    });
  });

  group(EmptyView, () {
    testWidgets('shows its message and action', (tester) async {
      var acted = false;
      await tester.pumpApp(
        Scaffold(
          body: EmptyView(
            title: 'No "matcha" yet',
            message: 'Send it to us and we add it.',
            actionLabel: 'Send it',
            onAction: () => acted = true,
          ),
        ),
      );
      expect(find.text('No "matcha" yet'), findsOneWidget);
      expect(find.text('Send it to us and we add it.'), findsOneWidget);
      await tester.tap(find.text('Send it'));
      expect(acted, isTrue);
      await tester.expectAccessible();
    });

    testWidgets('works without an action', (tester) async {
      await tester.pumpApp(const Scaffold(body: EmptyView(message: 'Nothing')));
      expect(find.text('Nothing'), findsOneWidget);
    });
  });

  testWidgets('LoadingView has a screen-reader label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(const Scaffold(body: LoadingView()));
    expect(find.bySemanticsLabel(l10nEn.loading), findsOneWidget);
    handle.dispose();
  });

  group(OfflineBanner, () {
    testWidgets('shows offline, then "back online" for 3 seconds', (
      tester,
    ) async {
      final online = StreamController<bool>();
      addTearDown(online.close);
      await tester.pumpApp(
        const Scaffold(body: Column(children: [OfflineBanner()])),
        onlineChanges: online.stream,
      );

      expect(find.text(l10nEn.offlineBanner), findsNothing);

      online.add(false);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.offlineBanner), findsOneWidget);
      await tester.expectAccessible();

      online.add(true);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.offlineBanner), findsNothing);
      expect(find.text(l10nEn.backOnline), findsOneWidget);

      await tester.pump(ConnectionScope.backOnlineFor);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.backOnline), findsNothing);
    });

    testWidgets('says nothing when the app starts online', (tester) async {
      final online = StreamController<bool>();
      addTearDown(online.close);
      await tester.pumpApp(
        const Scaffold(body: Column(children: [OfflineBanner()])),
        onlineChanges: online.stream,
      );
      online.add(true);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.backOnline), findsNothing);
    });

    testWidgets('a quick reconnect cancels the hide timer', (tester) async {
      final online = StreamController<bool>();
      addTearDown(online.close);
      await tester.pumpApp(
        const Scaffold(body: Column(children: [OfflineBanner()])),
        onlineChanges: online.stream,
      );
      online
        ..add(false)
        ..add(true);
      await tester.pump();
      online.add(false);
      await tester.pump(ConnectionScope.backOnlineFor);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.offlineBanner), findsOneWidget);
    });
  });
}
