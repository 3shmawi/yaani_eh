import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/result.dart';
import 'package:yaani_eh/core/router/app_router.dart';
import 'package:yaani_eh/core/router/app_routes.dart';
import 'package:yaani_eh/core/theme/app_dimens.dart';
import 'package:yaani_eh/core/theme/app_theme.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/core/widgets/offline_banner.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/domain/repositories/catalog_repository.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/l10n/l10n.dart';

import '../helpers/fake_favorites.dart';
import '../helpers/fake_pronunciation.dart';
import '../helpers/fake_taste.dart';
import '../helpers/fake_welcome.dart';
import '../helpers/screens.dart';

/// The raw screens for the store listings (`scripts/store_shots.sh` frames
/// them): the real launch content from `build/store/catalog.json`
/// (tool/store/catalog_fixture.py), on one device size and language:
///   --dart-define=STORE_DEVICE=440x956@3 --dart-define=STORE_LANG=ar
/// Off in normal runs.
void main() {
  const device = String.fromEnvironment(
    'STORE_DEVICE',
    defaultValue: '440x956@3',
  );
  const lang = String.fromEnvironment('STORE_LANG', defaultValue: 'ar');
  const out = String.fromEnvironment('STORE_OUT', defaultValue: 'raw');
  final size = device.split('@').first.split('x').map(double.parse).toList();
  final ratio = double.parse(device.split('@').last);
  const ar = lang == 'ar';

  late _Catalog catalog;

  Future<void> open(
    WidgetTester tester,
    String path, {
    Iterable<String> saved = const [],
  }) async {
    tester.view
      ..physicalSize = Size(size[0] * ratio, size[1] * ratio)
      ..devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(catalog),
          ...welcomeOverrides(),
          ...tasteOverrides(),
          ...favoritesOverrides(FakeFavoritesRepository(saved: saved)),
          ...pronunciationOverrides(
            FakePronunciationRepository(),
            FakeClipPlayer(),
          ),
        ],
        child: AppUi.testWrap(
          ScreenUtilInit(
            designSize: AppDimens.designFor(Size(size[0], size[1])),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              locale: const Locale(lang),
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

  Future<void> center(WidgetTester tester, String name) async {
    final card = find.widgetWithText(DrinkCard, name).first;
    await tester.dragUntilVisible(
      card,
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await Scrollable.ensureVisible(tester.element(card), alignment: 0.45);
    await tester.pumpAndSettle();
  }

  String id(String slug) => catalog.items.firstWhere((i) => i.slug == slug).id;

  group('store', () {
    // Inside the group, so a normal run (everything skipped) never reads
    // the fixture, which only scripts/store_shots.sh makes.
    setUpAll(() async {
      await loadAppFonts();
      catalog = _Catalog.load('build/store/catalog.json');
    });

    testWidgets('1 home', (tester) async {
      await open(tester, AppRoutes.home);
      await shoot(tester, '$out/1_home');
    });

    testWidgets('2 drink', (tester) async {
      await open(tester, AppRoutes.drink('flat_white'));
      await tester.drag(
        find.byType(Scrollable).first,
        Offset(0, -size[1] * 0.3),
      );
      await shoot(tester, '$out/2_drink');
    });

    testWidgets('3 preview', (tester) async {
      await open(tester, AppRoutes.home);
      await center(tester, 'Caramel Frappé');
      await tester.longPress(
        find.widgetWithText(DrinkCard, 'Caramel Frappé').first,
      );
      await shoot(tester, '$out/3_preview');
    });

    testWidgets('4 recipe', (tester) async {
      await open(tester, AppRoutes.drink('cappuccino'));
      final row = find.byKey(const Key('drink_recipe'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await shoot(tester, '$out/4_recipe');
    });

    testWidgets('5 steps', (tester) async {
      await open(tester, AppRoutes.drinkSteps('flat_white'));
      await tester.tap(find.byKey(const Key('steps_next')));
      await shoot(tester, '$out/5_steps');
    });

    testWidgets('6 search', (tester) async {
      await open(
        tester,
        AppRoutes.searchFor(ar ? 'حاجة ساقعة بالشوكولاتة' : 'iced chocolate'),
      );
      await shoot(tester, '$out/6_search');
    });

    testWidgets('7 favorites', (tester) async {
      await open(
        tester,
        AppRoutes.favorites,
        saved: [
          id('turkish_coffee'),
          id('iced_spanish_latte'),
          id('mango_juice'),
          id('flat_white'),
        ],
      );
      await shoot(tester, '$out/7_favorites');
    });
  }, skip: !takeScreens);
}

/// The launch catalog, read once from the fixture.
class _Catalog implements CatalogRepository {
  new(this.categories, this.items);

  factory load(String path) {
    final json =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    return _Catalog(
      [for (final r in json['categories'] as List) CatalogRows.category(r)!],
      [for (final r in json['items'] as List) CatalogRows.item(r)!],
    );
  }

  final List<CatalogCategory> categories;
  final List<CatalogItem> items;

  @override
  Future<bool> hasCatalog() async => true;

  @override
  Future<Result<SyncReport>> sync({
    void Function(SyncProgress)? onProgress,
  }) async => const Success(
    SyncReport(changed: 0, removed: 0, skipped: 0, firstSync: false),
  );

  @override
  Stream<List<CatalogItem>> watchItems() => Stream.value(items);

  @override
  Stream<List<CatalogCategory>> watchCategories() => Stream.value(categories);
}
