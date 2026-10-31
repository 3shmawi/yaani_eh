import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_sheet.dart';
import 'package:yaani_eh/features/recipes/presentation/recipe_view.dart';
import 'package:yaani_eh/features/recipes/presentation/step_by_step_page.dart';
import 'package:yaani_eh/features/recipes/presentation/step_by_step_view.dart';
import 'package:yaani_eh/features/recipes/presentation/widgets/recipe_cup.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final items = sampleCatalogItems();
  final flatWhite = items.firstWhere((i) => i.slug == 'flat_white');
  final coldBrew = items.firstWhere((i) => i.slug == 'cold_brew');
  final recipe = flatWhite.recipe!;

  /// Haptics sent to the platform, e.g. `HapticFeedbackType.selectionClick`.
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

  group(RecipeView, () {
    /// Opens the sheet for [item] from a button, under a router (for «خطوة
    /// بخطوة»). Returns the paths it pushed.
    Future<List<String>> openSheet(
      WidgetTester tester,
      CatalogItem item, {
      Locale locale = const Locale('en'),
      ThemeMode mode = ThemeMode.light,
    }) async {
      final pushed = <String>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Center(
              child: ElevatedButton(
                onPressed: () =>
                    showRecipeSheet(context, item, from: RecipeSource.preview),
                child: const Text('open'),
              ),
            ),
            routes: [
              GoRoute(
                path: 'drink/:slug/steps',
                builder: (context, state) {
                  pushed.add(state.uri.path);
                  return const Text('steps');
                },
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpApp(
        Router.withConfig(config: router),
        locale: locale,
        themeMode: mode,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return pushed;
    }

    testWidgets('the cup, what is in it, the facts and the steps', (
      tester,
    ) async {
      await openSheet(tester, flatWhite);

      expect(find.byKey(const Key('recipe_view')), findsOneWidget);
      expect(find.text('Flat White'), findsOneWidget);
      expect(find.text("How it's made · 180 ml"), findsOneWidget);
      expect(find.text('Silky hot milk'), findsOneWidget);
      // In the legend, and as the amount of the milk step.
      expect(find.text('110 ml'), findsNWidgets(2));
      expect(find.text('Hot'), findsOneWidget);
      expect(find.text('2 min'), findsOneWidget);
      for (final (i, step) in recipe.steps.indexed) {
        expect(find.byKey(Key('recipe_step_$i')), findsOneWidget);
        expect(find.text(step.titleEn), findsOneWidget);
      }
      expect(find.text('18 g coffee'), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('the cup reads its layers aloud, bottom to top', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester, flatWhite);
      expect(
        find.bySemanticsLabel(
          'The cup, bottom to top: Strong coffee (2 shots) 60 ml, '
          'Silky hot milk 110 ml, Thin foam 10 ml',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('^Step 1')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Arabic and dark', (tester) async {
      await openSheet(
        tester,
        flatWhite,
        locale: const Locale('ar'),
        mode: ThemeMode.dark,
      );
      expect(find.text('إزاي بيتعمل · 180 مل'), findsOneWidget);
      expect(find.text('دقيقتين'), findsOneWidget);
      expect(find.text('سخن'), findsOneWidget);
      expect(find.text('اطحن البن ناعم'), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('a night in the fridge reads as hours, iced', (tester) async {
      await openSheet(tester, coldBrew);
      expect(find.text('12 hours'), findsOneWidget);
      expect(find.text('Iced'), findsOneWidget);
    });

    testWidgets('close, and «step by step» opens the steps', (tester) async {
      final haptics = recordHaptics(tester);
      final pushed = await openSheet(tester, flatWhite);
      expect(haptics, contains('HapticFeedbackType.lightImpact'));

      await tester.tap(find.byKey(const Key('recipe_close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe_view')), findsNothing);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('recipe_step_by_step')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('recipe_view')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(const Key('recipe_step_by_step')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe_view')), findsNothing);
      expect(pushed, [AppRoutes.drinkSteps('flat_white')]);
    });

    testWidgets('a drink without a recipe opens nothing', (tester) async {
      await openSheet(tester, items.firstWhere((i) => i.slug == 'latte'));
      expect(find.byKey(const Key('recipe_view')), findsNothing);
    });

    testWidgets('small phone with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSheet(tester, flatWhite);
      tester.view.physicalSize = const Size(960, 1704);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group(RecipeCup, () {
    test('the cup fits what it holds', () {
      expect(CupShape.forMl(30), CupShape.small);
      expect(CupShape.forMl(180), CupShape.cup);
      expect(CupShape.forMl(250), CupShape.cup);
      expect(CupShape.forMl(400), CupShape.glass);
    });

    testWidgets('fills in, and is full at once with Reduce Motion', (
      tester,
    ) async {
      CupPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(RecipeCup),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as CupPainter;

      await tester.pumpApp(
        Center(
          child: RecipeCup(recipe: recipe, semanticLabel: 'cup'),
        ),
      );
      expect(painter().progress, 0);
      await tester.pumpAndSettle();
      expect(painter().progress, 1);

      await tester.pumpApp(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(
            child: RecipeCup(
              key: const Key('still'),
              recipe: recipe,
              semanticLabel: 'cup',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(painter().progress, 1);
    });
  });

  group(StepByStepView, () {
    Future<({List<String> events})> pumpSteps(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      final events = <String>[];
      await tester.pumpApp(
        StepByStepView(
          item: flatWhite,
          recipe: recipe,
          onClose: () => events.add('close'),
          onFinished: () => events.add('finished'),
        ),
        locale: locale,
      );
      await tester.pumpAndSettle();
      return (events: events);
    }

    testWidgets('one step at a time, to the end', (tester) async {
      final haptics = recordHaptics(tester);
      final (:events) = await pumpSteps(tester);

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Grind the coffee fine'), findsOneWidget);
      expect(find.text('Next step'), findsOneWidget);
      await tester.expectAccessible();

      await tester.tap(find.byKey(const Key('steps_next')));
      await tester.pumpAndSettle();
      expect(find.text('Pull two strong shots'), findsOneWidget);
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.selectionClick']);

      await tester.tap(find.byKey(const Key('steps_previous')));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 4'), findsOneWidget);

      // Swiping works too.
      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byKey(const Key('steps_pages')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Done, enjoy'), findsOneWidget);

      await tester.tap(find.byKey(const Key('steps_next')));
      await tester.tap(find.byKey(const Key('steps_close')));
      expect(events, ['finished', 'close']);
    });

    testWidgets('Arabic: right to left, swiped the other way', (tester) async {
      await pumpSteps(tester, locale: const Locale('ar'));
      expect(find.text('خطوة 1 من 4'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('steps_pages')),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('اعمل شوتين قهوة مركّزة'), findsOneWidget);
      expect(find.text('الخطوة الجاية'), findsOneWidget);
      await tester.expectAccessible();
    });

    testWidgets('small phone with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpSteps(tester);
      tester.view.physicalSize = const Size(960, 1704);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group(StepByStepPage, () {
    Future<void> pumpPage(WidgetTester tester, String slug) async {
      await tester.pumpApp(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(has: true),
            ),
          ],
          child: StepByStepPage(slug: slug),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a drink with a recipe', (tester) async {
      await pumpPage(tester, 'flat_white');
      expect(find.byType(StepByStepView), findsOneWidget);
    });

    testWidgets('no recipe yet, or no such drink, says so', (tester) async {
      for (final slug in ['latte', 'no_such_drink']) {
        await pumpPage(tester, slug);
        expect(find.byKey(const Key('steps_missing')), findsOneWidget);
        expect(find.text(l10nEn.recipeMissingTitle), findsOneWidget);
      }
      await tester.expectAccessible();
    });
  });
}
