import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/widgets/brand_mark.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_page.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_view.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group(CatalogSyncView, () {
    testWidgets('downloading: progress, count and a tip', (tester) async {
      await tester.pumpApp(
        CatalogSyncView(
          progress: const SyncProgress(saved: 24, total: 60),
          failure: null,
          onRetry: () {},
        ),
      );
      expect(find.text(l10nEn.firstLoadTitle), findsOneWidget);
      expect(find.text(l10nEn.firstLoadProgress(24, 60)), findsOneWidget);
      expect(find.byType(BrandMark), findsOneWidget);
      expect(find.text(l10nEn.didYouKnow), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.4, 0.001));
      await tester.expectAccessible();
    });

    testWidgets('screen readers hear the progress', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        CatalogSyncView(
          progress: const SyncProgress(saved: 24, total: 60),
          failure: null,
          onRetry: () {},
        ),
      );
      expect(
        find.bySemanticsLabel(l10nEn.firstLoadProgressLabel(24, 60)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('before the total is known the bar is indeterminate', (
      tester,
    ) async {
      await tester.pumpApp(
        CatalogSyncView(progress: null, failure: null, onRetry: () {}),
      );
      await tester.pump();
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);
    });

    testWidgets('offline on first launch: says why, retries', (tester) async {
      var retried = 0;
      await tester.pumpApp(
        CatalogSyncView(
          progress: null,
          failure: const NetworkFailure(),
          onRetry: () => retried++,
        ),
      );
      expect(find.text(l10nEn.firstLoadOfflineTitle), findsOneWidget);
      expect(find.text(l10nEn.autoRetryHint), findsOneWidget);
      await tester.tap(find.text(l10nEn.retry));
      expect(retried, 1);
      await tester.expectAccessible();
    });

    testWidgets('other failures show their own message', (tester) async {
      await tester.pumpApp(
        CatalogSyncView(
          progress: null,
          failure: const ServerFailure(),
          onRetry: () {},
        ),
      );
      expect(find.text(l10nEn.firstLoadFailedTitle), findsOneWidget);
      expect(find.text(l10nEn.errorUnknown), findsOneWidget);
    });

    for (final (name, locale, mode) in [
      ('Arabic', const Locale('ar'), ThemeMode.light),
      ('dark', const Locale('en'), ThemeMode.dark),
      ('Arabic dark', const Locale('ar'), ThemeMode.dark),
    ]) {
      testWidgets('works in $name', (tester) async {
        await tester.pumpApp(
          CatalogSyncView(
            progress: const SyncProgress(saved: 5, total: 41),
            failure: null,
            onRetry: () {},
          ),
          locale: locale,
          themeMode: mode,
        );
        expect(tester.takeException(), isNull);
        await tester.expectAccessible();
      });
    }

    testWidgets('fits a small phone with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpApp(
        CatalogSyncView(
          progress: const SyncProgress(saved: 5, total: 41),
          failure: null,
          onRetry: () {},
        ),
        locale: const Locale('ar'),
      );
      tester.view.physicalSize = const Size(960, 1704); // 320×568
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group(CatalogSyncPage, () {
    Future<void> pumpPage(
      WidgetTester tester,
      FakeCatalogRepository repository,
    ) => tester.pumpApp(
      ProviderScope(
        overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
        child: const CatalogSyncPage(child: Text('the menu')),
      ),
    );

    testWidgets('shows the menu once the catalog is on the device', (
      tester,
    ) async {
      await pumpPage(tester, FakeCatalogRepository(has: true));
      await tester.pumpAndSettle();
      expect(find.text('the menu'), findsOneWidget);
    });

    testWidgets('first launch downloads, then shows the menu', (tester) async {
      await pumpPage(tester, FakeCatalogRepository());
      await tester.pumpAndSettle();
      expect(find.text('the menu'), findsOneWidget);
    });

    testWidgets('first launch offline shows the error', (tester) async {
      await pumpPage(
        tester,
        FakeCatalogRepository()..failWith = const NetworkFailure(),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text(l10nEn.firstLoadOfflineTitle), findsOneWidget);
      expect(find.text('the menu'), findsNothing);
    });
  });
}
