import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/router/app_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_theme.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/settings/domain/entities/app_settings.dart';
import 'package:yaani_eh/features/settings/domain/repositories/settings_repository.dart';
import 'package:yaani_eh/features/settings/presentation/settings_controller.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/l10n/l10n.dart';

import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_favorites.dart';
import '../helpers/fake_pronunciation.dart';
import '../helpers/fake_taste.dart';
import '../helpers/fake_welcome.dart';
import '../helpers/screens.dart';

/// The app's main screens as PNGs in build/screens/, for reviewing a change
/// by eye (the agent does this before opening a PR). Off in normal runs:
///   scripts/screens.sh                 # iPhone 15, Arabic + English, dark
///   scripts/screens.sh 430x932         # another size in points (Pro Max)
void main() {
  const size = String.fromEnvironment('SCREENS_SIZE', defaultValue: '393x852');
  final points = size.split('x').map(double.parse).toList();

  setUpAll(loadAppFonts);

  Future<void> open(
    WidgetTester tester,
    String lang,
    String path, {
    Map<String, TasteProfile> taste = const {},
  }) async {
    tester.view
      ..physicalSize = Size(points[0] * 3, points[1] * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(has: true),
          ),
          ...welcomeOverrides(),
          ...tasteOverrides(FakeTasteRepository(taste)),
          ...favoritesOverrides(FakeFavoritesRepository()),
          ...pronunciationOverrides(
            FakePronunciationRepository(),
            FakeClipPlayer(),
          ),
          settingsRepositoryProvider.overrideWithValue(
            _Settings(AppSettings(locale: Locale(lang))),
          ),
        ],
        child: AppUi.testWrap(
          ScreenUtilInit(
            designSize: AppDimens.designFor(Size(points[0], points[1])),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: AppTheme.modeFor(ThemeMode.dark),
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => AppTheme.localize(
                context,
                ConnectionScope(
                  onlineChanges: const Stream.empty(),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    appRouter.go(path);
    await tester.pumpAndSettle();
  }

  for (final lang in ['ar', 'en']) {
    group(lang, () {
      testWidgets('home', (tester) async {
        await open(tester, lang, AppRoutes.home);
        await shoot(tester, '${lang}_01_home');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await shoot(tester, '${lang}_02_home_cards');
      });

      testWidgets('long press', (tester) async {
        await open(tester, lang, AppRoutes.home);
        final card = find.widgetWithText(DrinkCard, 'Flat White');
        await tester.dragUntilVisible(
          card,
          find.byType(Scrollable).first,
          const Offset(0, -200),
        );
        // In the middle, clear of the pinned chips.
        await Scrollable.ensureVisible(tester.element(card), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.longPress(card);
        await shoot(tester, '${lang}_03_preview');
      });

      testWidgets('drink and recipe', (tester) async {
        await open(tester, lang, AppRoutes.drink('flat_white'));
        await shoot(tester, '${lang}_04_drink');
        final recipe = find.byKey(const Key('drink_recipe'));
        await tester.ensureVisible(recipe);
        await shoot(tester, '${lang}_05_drink_scrolled');
        await tester.tap(recipe);
        await shoot(tester, '${lang}_06_recipe');
      });

      testWidgets('step by step', (tester) async {
        await open(tester, lang, AppRoutes.drinkSteps('flat_white'));
        await tester.tap(find.byKey(const Key('steps_next')));
        await shoot(tester, '${lang}_07_steps');
      });

      testWidgets('search', (tester) async {
        await open(tester, lang, AppRoutes.searchFor('latte'));
        await shoot(tester, '${lang}_08_search');
      });

      testWidgets('favorites', (tester) async {
        await open(tester, lang, AppRoutes.favorites);
        await shoot(tester, '${lang}_09_favorites_empty');
      });

      testWidgets('taste quiz', (tester) async {
        await open(tester, lang, AppRoutes.taste);
        await tester.tap(find.byKey(const Key('taste_option_temp_1')));
        await tester.pumpAndSettle();
        await shoot(tester, '${lang}_11_taste_quiz');
      });

      testWidgets('home on your taste', (tester) async {
        await open(
          tester,
          lang,
          AppRoutes.home,
          taste: {
            'cafe': const TasteProfile({'temp': 'cold', 'milk': true}),
          },
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
        await shoot(tester, '${lang}_12_home_taste');
      });

      testWidgets('welcome', (tester) async {
        await open(tester, lang, AppRoutes.welcome);
        await shoot(tester, '${lang}_13_welcome_menu');
        await tester.tap(find.byKey(const Key('welcome_next')));
        await tester.pumpAndSettle();
        await shoot(tester, '${lang}_14_welcome_hear');
        await tester.tap(find.byKey(const Key('welcome_next')));
        await tester.pumpAndSettle();
        await shoot(tester, '${lang}_15_welcome_taste');
      });

      testWidgets('settings', (tester) async {
        await open(tester, lang, AppRoutes.settings);
        await shoot(tester, '${lang}_10_settings');
      });
    }, skip: !takeScreens);
  }
}

class _Settings implements SettingsRepository {
  new(this._settings);

  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}
