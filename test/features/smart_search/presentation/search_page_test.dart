import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/widgets/search_field.dart';
import 'package:yaani_eh/features/browse_menu/presentation/menu_controller.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_page.dart';
import 'package:yaani_eh/features/smart_search/presentation/widgets/answer_card.dart';
import 'package:yaani_eh/features/smart_search/presentation/widgets/result_row.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpSearch(
    WidgetTester tester, {
    String query = '',
    Locale locale = const Locale('en'),
    ThemeMode mode = ThemeMode.light,
  }) async {
    await tester.pumpApp(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(has: true),
          ),
          todayProvider.overrideWithValue(DateTime(2026, 10, 30)),
        ],
        child: SearchPage(initialQuery: query),
      ),
      locale: locale,
      themeMode: mode,
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(SearchPage.debounce);
    await tester.pumpAndSettle();
  }

  testWidgets('before typing: what search understands, with examples', (
    tester,
  ) async {
    await pumpSearch(tester);
    expect(find.text(l10nEn.searchIdleTitle), findsOneWidget);
    expect(find.text('milk and coffee'), findsOneWidget);
    await tester.expectAccessible();
  });

  testWidgets('a name gets the answer card, then related drinks', (
    tester,
  ) async {
    await pumpSearch(tester);
    await type(tester, 'latte');
    expect(find.byType(AnswerCard), findsOneWidget);
    expect(find.text(l10nEn.youTyped('latte')), findsOneWidget);
    expect(find.text(l10nEn.searchMoreWith('latte')), findsOneWidget);
    expect(find.byType(ResultRow), findsWidgets);
    await tester.expectAccessible();
  });

  testWidgets('a description gets a ranked list with highlights', (
    tester,
  ) async {
    await pumpSearch(tester);
    await tester.tap(find.text('milk and coffee'));
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCard), findsNothing);
    expect(find.byType(ResultRow), findsWidgets);
    var highlighted = false;
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        if (span.style?.fontWeight == FontWeight.w700) highlighted = true;
        return !highlighted;
      });
    }
    expect(highlighted, isTrue);
  });

  testWidgets('nothing found: says so and suggests drinks', (tester) async {
    await pumpSearch(tester);
    await type(tester, 'spanish cortado');
    expect(find.text(l10nEn.searchNothing('spanish cortado')), findsOneWidget);
    expect(find.text(l10nEn.didYouMean), findsOneWidget);
    await tester.expectAccessible();
  });

  testWidgets('a result shows calories, never a price', (tester) async {
    final base = sampleCatalogItems().first;
    final priced = CatalogItem(
      id: base.id,
      categoryId: base.categoryId,
      slug: base.slug,
      menuName: base.menuName,
      menuNameAr: base.menuNameAr,
      explanationAr: base.explanationAr,
      explanationEn: base.explanationEn,
      calories: 5,
      priceMinEgp: 40,
      priceMaxEgp: 70,
    );
    await tester.pumpApp(Material(child: ResultRow(item: priced)));
    expect(find.text(l10nEn.calories(5)), findsOneWidget);
    expect(find.textContaining('EGP'), findsNothing);
  });

  testWidgets('the clear button empties the field', (tester) async {
    await pumpSearch(tester, query: 'latte');
    expect(find.byType(AnswerCard), findsOneWidget);
    await tester.tap(find.byKey(const Key('search_clear')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.searchIdleTitle), findsOneWidget);
  });

  testWidgets('a deep-link query is pre-filled', (tester) async {
    await pumpSearch(tester, query: 'cortado');
    expect(find.text('cortado'), findsWidgets);
    expect(find.byType(AnswerCard), findsOneWidget);
  });

  for (final (name, locale, mode) in [
    ('Arabic', const Locale('ar'), ThemeMode.light),
    ('Arabic dark', const Locale('ar'), ThemeMode.dark),
  ]) {
    testWidgets('works in $name', (tester) async {
      await pumpSearch(tester, locale: locale, mode: mode);
      await tester.expectAccessible();
      await type(tester, 'لاتيه');
      expect(find.byType(AnswerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      // After typing, a 5-letter word in the wide field leaves too few text
      // pixels for the pixel-sampling contrast check; the field colors
      // themselves are covered by the token contrast tests.
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  group('hostile input', () {
    for (final text in [
      "'; DROP TABLE items; --",
      '<script>alert(1)</script>',
      '😀☕️🧋',
      r'.*+?^${}()|[]\',
      'ـــــــ',
    ]) {
      testWidgets(text, (tester) async {
        await pumpSearch(tester);
        await type(tester, text);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the field stops at 60 characters', (tester) async {
      await pumpSearch(tester);
      await tester.enterText(find.byType(TextField), 'a' * 500);
      await tester.pump(SearchPage.debounce);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, SearchField.maxLength);
    });
  });

  group('links: AppRoutes.cleanQuery', () {
    test('removes control and direction characters, trims, caps', () {
      expect(AppRoutes.cleanQuery('  latte  '), 'latte');
      expect(AppRoutes.cleanQuery('\u202Eetal\u202C'), 'etal');
      expect(AppRoutes.cleanQuery('lat\u0000te\n'), 'latte');
      expect(AppRoutes.cleanQuery('a' * 200).length, 60);
      expect(AppRoutes.cleanQuery(null), '');
    });

    test('builds a safe search link', () {
      expect(
        AppRoutes.searchFor('لبن وقهوة'),
        '/search?q=%D9%84%D8%A8%D9%86+%D9%88%D9%82%D9%87%D9%88%D8%A9',
      );
    });
  });
}
