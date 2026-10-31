import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/smart_search/presentation/search_controller.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/usecases/taste_questions.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_page.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_quiz_view.dart';
import 'package:yaani_eh/features/taste_profile/presentation/taste_row.dart';

import '../../../helpers/fake_catalog_remote.dart';
import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_favorites.dart';
import '../../../helpers/fake_taste.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final questions = const TasteQuestions()(cafeTraitSchema);

  /// Haptics sent to the platform.
  List<Object?> recordHaptics(WidgetTester tester) {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return haptics;
  }

  Future<void> pick(WidgetTester tester, String key, int option) async {
    await tester.tap(find.byKey(Key('taste_option_${key}_$option')));
    await tester.pump(AppMotion.jump);
    await tester.pumpAndSettle();
  }

  group(TasteQuizView, () {
    Future<({List<TasteProfile> done, List<int> closed})> pumpQuiz(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      TasteProfile initial = const TasteProfile({}),
    }) async {
      final done = <TasteProfile>[];
      final closed = <int>[];
      await tester.pumpApp(
        TasteQuizView(
          questions: questions,
          initial: initial,
          onFinish: done.add,
          onClose: closed.add,
        ),
        locale: locale,
      );
      await tester.pumpAndSettle();
      return (done: done, closed: closed);
    }

    testWidgets('one question at a time; a choice moves on by itself', (
      tester,
    ) async {
      final haptics = recordHaptics(tester);
      final (:done, :closed) = await pumpQuiz(tester);
      expect(find.text('Question 1 of 4'), findsOneWidget);
      expect(find.text('Hot or iced?'), findsOneWidget);
      expect(find.byKey(const Key('taste_previous')), findsOneWidget);
      await tester.expectAccessible();

      await pick(tester, 'temp', 1); // Iced
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
      expect(find.text('How sweet do you like it?'), findsOneWidget);

      await pick(tester, 'sweetness', 2); // Sweet
      // «Doesn't matter» skips milk.
      await tester.tap(find.byKey(const Key('taste_skip')));
      await tester.pumpAndSettle();
      expect(find.text('Question 4 of 4'), findsOneWidget);

      await pick(tester, 'caffeine', 1); // Light
      expect(done, [
        const TasteProfile({'temp': 'cold', 'sweetness': 2, 'caffeine': 1}),
      ]);
      expect(haptics, contains('HapticFeedbackType.mediumImpact'));
      expect(closed, isEmpty);
    });

    testWidgets('back one question keeps the answer, and shows it', (
      tester,
    ) async {
      await pumpQuiz(tester);
      await pick(tester, 'temp', 0);
      await tester.tap(find.byKey(const Key('taste_previous')));
      await tester.pumpAndSettle();
      expect(find.text('Question 1 of 4'), findsOneWidget);
      final hot = tester.getSemantics(
        find.byKey(const Key('taste_option_temp_0')),
      );
      expect(hot.flagsCollection.isSelected, Tristate.isTrue);
    });

    testWidgets('changing an old taste starts from it', (tester) async {
      final (:done, closed: _) = await pumpQuiz(
        tester,
        initial: const TasteProfile({'temp': 'hot', 'milk': false}),
      );
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('taste_skip')));
        await tester.pumpAndSettle();
      }
      // Skipping clears an answer: «doesn't matter» is an answer too.
      expect(done, [const TasteProfile({})]);
    });

    testWidgets('✕ leaves without saving, saying where', (tester) async {
      final (:done, :closed) = await pumpQuiz(tester);
      await pick(tester, 'temp', 2);
      await tester.tap(find.byKey(const Key('taste_close')));
      expect(closed, [1]);
      expect(done, isEmpty);
    });

    testWidgets('Arabic, and a small phone with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpQuiz(tester, locale: const Locale('ar'));
      tester.view.physicalSize = const Size(960, 1704);
      await tester.pumpAndSettle();
      expect(find.text('بتحب مشروبك سخن ولا ساقع؟'), findsOneWidget);
      expect(find.text('مش فارقة معايا'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.expectAccessible();
    });
  });

  group('wired', () {
    Future<FakeTasteRepository> pumpScoped(
      WidgetTester tester,
      Widget child, {
      FakeTasteRepository? taste,
      Locale locale = const Locale('en'),
    }) async {
      final repo = taste ?? FakeTasteRepository();
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(has: true),
            ),
            ...tasteOverrides(repo),
            ...favoritesOverrides(FakeFavoritesRepository()),
          ],
          // On Home's surface, as in the app.
          child: Scaffold(body: child),
        ),
        locale: locale,
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('the page saves the answers', (tester) async {
      final repo = await pumpScoped(tester, const TastePage(section: 'cafe'));
      expect(find.byType(TasteQuizView), findsOneWidget);
      await pick(tester, 'temp', 1);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('taste_skip')));
        await tester.pumpAndSettle();
      }
      expect(repo.saved['cafe'], const TasteProfile({'temp': 'cold'}));
    });

    testWidgets('a save that fails says so and keeps the quiz open', (
      tester,
    ) async {
      final repo = FakeTasteRepository()..failSave = true;
      await pumpScoped(tester, const TastePage(section: 'cafe'), taste: repo);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('taste_skip')));
        await tester.pumpAndSettle();
      }
      expect(find.text(l10nEn.tasteSaveFailed), findsOneWidget);
      expect(find.byType(TasteQuizView), findsOneWidget);
      expect(repo.saved, isEmpty);
    });

    testWidgets('an unknown or question-less section falls back to drinks', (
      tester,
    ) async {
      await pumpScoped(tester, const TastePage(section: 'desserts'));
      expect(find.byType(TasteQuizView), findsOneWidget);
      await pumpScoped(tester, const TastePage(section: 'no_such_section'));
      expect(find.byType(TasteQuizView), findsOneWidget);
    });

    testWidgets('before the quiz, Home invites to take it', (tester) async {
      await pumpScoped(
        tester,
        SingleChildScrollView(
          child: TasteRow(section: 'cafe', onOpenItem: (_) {}),
        ),
      );
      expect(find.byKey(const Key('taste_invite')), findsOneWidget);
      expect(find.text(l10nEn.tastePromptTitle), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('after: the drinks that fit, with why, best first', (
      tester,
    ) async {
      final opened = <String>[];
      await pumpScoped(
        tester,
        SingleChildScrollView(
          child: TasteRow(
            section: 'cafe',
            onOpenItem: (i) => opened.add(i.slug),
          ),
        ),
        taste: FakeTasteRepository({
          'cafe': const TasteProfile({'temp': 'cold', 'milk': true}),
        }),
      );
      expect(find.byKey(const Key('taste_row')), findsOneWidget);
      expect(find.text(l10nEn.tasteForYou), findsOneWidget);
      // Iced coffees first; no hot drink fits «cold».
      final first = find.byKey(const Key('taste_match_iced_latte'));
      expect(first, findsOneWidget);
      expect(find.byKey(const Key('taste_match_espresso')), findsNothing);
      expect(find.text('Iced · With milk'), findsWidgets);
      await tester.tap(first);
      expect(opened, ['iced_latte']);
      await tester.expectAccessible();
    });

    testWidgets('nothing fits: says so, with the way to change it', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        SingleChildScrollView(
          child: TasteRow(section: 'cafe', onOpenItem: (_) {}),
        ),
        taste: FakeTasteRepository({
          'cafe': const TasteProfile({'milk': false, 'temp': 'cold'}),
        }),
      );
      expect(find.text(l10nEn.tasteNoMatches), findsOneWidget);
      expect(find.byKey(const Key('taste_change')), findsOneWidget);
    });

    testWidgets('a section without questions shows nothing', (tester) async {
      await pumpScoped(
        tester,
        TasteRow(section: 'desserts', onOpenItem: (_) {}),
      );
      expect(find.byKey(const Key('taste_invite')), findsNothing);
      expect(find.byKey(const Key('taste_row')), findsNothing);
    });
  });

  group('search', () {
    test(
      'drinks that fit come first; nothing changes before the quiz',
      () async {
        ProviderContainer container(FakeTasteRepository taste) {
          final c = ProviderContainer(
            overrides: [
              catalogRepositoryProvider.overrideWithValue(
                FakeCatalogRepository(has: true),
              ),
              ...tasteOverrides(taste),
            ],
          );
          addTearDown(c.dispose);
          return c;
        }

        Future<List<String>> results(ProviderContainer c) async {
          c
            ..listen(searchResultsProvider, (_, _) {})
            ..read(searchQueryProvider.notifier).set('latte');
          await c.read(catalogItemsProvider.future);
          await c.read(catalogCategoriesProvider.future);
          return [
            for (final h in c.read(searchResultsProvider)!.hits) h.item.slug,
          ];
        }

        final before = await results(container(FakeTasteRepository()));
        final after = await results(
          container(
            FakeTasteRepository({
              'cafe': const TasteProfile({'temp': 'cold'}),
            }),
          ),
        );
        expect(
          after.indexOf('iced_latte'),
          lessThan(before.indexOf('iced_latte')),
        );
      },
    );
  });
}
