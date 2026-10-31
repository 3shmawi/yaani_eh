import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/network/app_failure.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/core/widgets/drink_card.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/catalog_sync/presentation/catalog_sync_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/drink_preview.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_controller.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_page.dart';
import 'package:yaani_eh/features/favorites/presentation/favorites_view.dart';
import 'package:yaani_eh/features/favorites/presentation/widgets/favorite_button.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/fake_favorites.dart';
import '../../../helpers/fake_pronunciation.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final items = sampleCatalogItems(withAudio: true);
  final espresso = items.first;

  Future<FakeFavoritesRepository> pumpScoped(
    WidgetTester tester,
    Widget child, {
    Iterable<String> saved = const [],
    Locale locale = const Locale('en'),
    ThemeMode mode = ThemeMode.light,
  }) async {
    final repo = FakeFavoritesRepository(saved: saved);
    await tester.pumpApp(
      ProviderScope(
        overrides: [
          ...favoritesOverrides(repo),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(has: true, items: items),
          ),
          ...pronunciationOverrides(
            FakePronunciationRepository(),
            FakeClipPlayer(),
          ),
        ],
        child: child,
      ),
      locale: locale,
      themeMode: mode,
    );
    await tester.pumpAndSettle();
    return repo;
  }

  AppIconButton heart(WidgetTester tester, CatalogItem item) =>
      tester.widget<AppIconButton>(find.byKey(Key('favorite_${item.slug}')));

  group(FavoriteButton, () {
    Widget button() => Center(
      child: FavoriteButton(item: espresso, from: FavoriteSource.card),
    );

    testWidgets('a tap saves the drink; another removes it', (tester) async {
      final repo = await pumpScoped(tester, button());
      expect(heart(tester, espresso).selected, isFalse);
      expect(heart(tester, espresso).tooltip, l10nEn.favoriteAddOf('Espresso'));

      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();
      expect(repo.saved, {espresso.id});
      expect(heart(tester, espresso).selected, isTrue);
      expect(heart(tester, espresso).icon, AppIconsFill.heart);
      expect(heart(tester, espresso).selectedLook, AppSelectedLook.chosen);
      expect(
        heart(tester, espresso).tooltip,
        l10nEn.favoriteRemoveOf('Espresso'),
      );

      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();
      expect(repo.saved, isEmpty);
      expect(heart(tester, espresso).selected, isFalse);
      await tester.expectAccessible();
    });

    testWidgets('a write that fails leaves the heart as it was', (
      tester,
    ) async {
      final repo = await pumpScoped(tester, button());
      repo.fail = const UnknownFailure('disk full');
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();
      expect(repo.saved, isEmpty);
      expect(heart(tester, espresso).selected, isFalse);
    });
  });

  group(FavoritesView, () {
    Future<void> pumpView(
      WidgetTester tester, {
      List<CatalogItem>? drinks,
      VoidCallback? onOpenMenu,
      Locale locale = const Locale('en'),
      ThemeMode mode = ThemeMode.light,
    }) => tester.pumpApp(
      FavoritesView(drinks: drinks, onOpenMenu: onOpenMenu ?? () {}),
      locale: locale,
      themeMode: mode,
    );

    testWidgets('loading, then empty with a way to the menu', (tester) async {
      await pumpView(tester);
      expect(find.bySemanticsLabel(l10nEn.loading), findsOneWidget);

      var menu = 0;
      await pumpView(tester, drinks: const [], onOpenMenu: () => menu++);
      expect(find.byKey(const Key('favorites_empty')), findsOneWidget);
      expect(find.text(l10nEn.favoritesEmptyTitle), findsOneWidget);
      await tester.tap(find.text(l10nEn.favoritesEmptyAction));
      expect(menu, 1);
      await tester.expectAccessible();
    });

    testWidgets('saved drinks as cards, with how many', (tester) async {
      await pumpView(tester, drinks: items.take(3).toList());
      expect(find.text(l10nEn.favoritesTitle), findsOneWidget);
      expect(find.text(l10nEn.favoritesCount(3)), findsOneWidget);
      expect(find.byType(DrinkCard), findsNWidgets(3));
      await tester.expectAccessible();
    });

    for (final (name, locale, mode) in [
      ('Arabic', const Locale('ar'), ThemeMode.light),
      ('dark', const Locale('en'), ThemeMode.dark),
      ('Arabic dark', const Locale('ar'), ThemeMode.dark),
    ]) {
      testWidgets('works in $name', (tester) async {
        await pumpView(
          tester,
          drinks: items.take(2).toList(),
          locale: locale,
          mode: mode,
        );
        expect(tester.takeException(), isNull);
        await tester.expectAccessible();
      });
    }

    testWidgets('small phone with large text, and a tablet', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpView(tester, drinks: items, locale: const Locale('ar'));
      tester.view.physicalSize = const Size(960, 1704);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(2048, 2732);
      tester.view.devicePixelRatio = 2;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group(FavoritesPage, () {
    testWidgets('newest first; un-hearting a drink takes it off', (
      tester,
    ) async {
      // Saved in this order: espresso, then the third drink.
      await pumpScoped(
        tester,
        const FavoritesPage(),
        saved: [espresso.id, items[2].id],
      );
      final cards = tester
          .widgetList<DrinkCard>(find.byType(DrinkCard))
          .map((c) => c.item.slug)
          .toList();
      expect(cards, [items[2].slug, espresso.slug]);

      await tester.tap(find.byKey(Key('favorite_${espresso.slug}')));
      await tester.pumpAndSettle();
      expect(find.byType(DrinkCard), findsOneWidget);
      expect(find.text(l10nEn.favoritesCount(1)), findsOneWidget);
    });
  });

  group('long-press preview', () {
    // Like the app, where the tab bar's count always listens to the saved
    // drinks.
    Widget harness(ValueChanged<CatalogItem> onOpen) => Consumer(
      builder: (context, ref, _) {
        ref.watch(favoriteIdsProvider);
        return Center(
          child: SizedBox(
            width: 170,
            child: DrinkCard(
              item: espresso,
              onLongPress: () => showDrinkPreview(
                context,
                ref,
                espresso,
                onOpen: () => onOpen(espresso),
              ),
            ),
          ),
        );
      },
    );

    testWidgets('shows what it is, and saves, plays and opens it', (
      tester,
    ) async {
      final opened = <CatalogItem>[];
      final repo = await pumpScoped(tester, harness(opened.add));

      await tester.longPress(find.byType(DrinkCard));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drink_preview')), findsOneWidget);
      expect(find.text('A tiny, strong cup of coffee'), findsWidgets);
      expect(find.byKey(const Key('preview_hear')), findsOneWidget);
      // Espresso has no recipe yet.
      expect(find.byKey(const Key('preview_recipe')), findsNothing);
      await tester.expectAccessible();

      await tester.tap(find.byKey(const Key('preview_save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drink_preview')), findsNothing);
      expect(repo.saved, {espresso.id});

      // Saved: the row offers to remove it now.
      await tester.longPress(find.byType(DrinkCard));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.previewUnsave), findsOneWidget);
      await tester.tap(find.byKey(const Key('preview_open')));
      await tester.pumpAndSettle();
      expect(opened, [espresso]);
    });

    testWidgets("«how it's made» opens the recipe", (tester) async {
      final flatWhite = items.firstWhere((i) => i.slug == 'flat_white');
      await pumpScoped(
        tester,
        Consumer(
          builder: (context, ref, _) => Center(
            child: SizedBox(
              width: 170,
              child: DrinkCard(
                item: flatWhite,
                onLongPress: () =>
                    showDrinkPreview(context, ref, flatWhite, onOpen: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.longPress(find.byType(DrinkCard));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.previewNew), findsOneWidget);

      await tester.tap(find.byKey(const Key('preview_recipe')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drink_preview')), findsNothing);
      expect(find.byKey(const Key('recipe_view')), findsOneWidget);
    });

    testWidgets('a tap outside closes it', (tester) async {
      await pumpScoped(tester, harness((_) {}));
      await tester.longPress(find.byType(DrinkCard));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drink_preview')), findsNothing);
    });

    testWidgets('no clip, no «hear» row', (tester) async {
      await tester.pumpApp(const SizedBox());
      final quiet = sampleCatalogItems().first; // no audio paths
      final repo = FakeFavoritesRepository();
      await tester.pumpApp(
        ProviderScope(
          overrides: favoritesOverrides(repo),
          child: Consumer(
            builder: (context, ref, _) => Center(
              child: SizedBox(
                width: 170,
                child: DrinkCard(
                  item: quiet,
                  onLongPress: () =>
                      showDrinkPreview(context, ref, quiet, onOpen: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.longPress(find.byType(DrinkCard));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('preview_hear')), findsNothing);
      expect(find.byKey(const Key('preview_save')), findsOneWidget);
    });
  });
}
