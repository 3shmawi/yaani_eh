import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/item_details/domain/usecases/describe_item.dart';
import 'package:yaani_eh/features/item_details/presentation/details_view.dart';
import 'package:yaani_eh/features/item_details/presentation/item_view.dart';
import 'package:yaani_eh/l10n/gen/app_localizations.dart';

import '../../../helpers/fake_catalog_remote.dart';
import '../../../helpers/pump_app.dart';

Map<String, Object?> _section(String en, String ar, List<String> lines) => {
  'title_en': en,
  'title_ar': ar,
  'lines_en': lines,
  'lines_ar': lines,
};

/// An item of another section, with [details] (server shape).
CatalogItem _item(Map<String, Object?> details) => CatalogRows.item({
  ...sampleItems().first,
  'slug': 'bureaucracy',
  'menu_name': 'Bureaucracy',
  'menu_name_ar': 'بيروقراطية',
  'traits': <String, Object?>{},
  'details': details,
})!;

final CatalogItem _usage = _item({
  'kind': 'usage',
  'sections': [
    _section('In a sentence', 'في جملة', ['The papers took a month.']),
    _section('Opposite', 'عكسها', ['Getting it done in a day.']),
  ],
});

final CatalogItem _story = _item({
  'kind': 'story',
  'steps': [
    {
      'title_en': 'The crossing',
      'title_ar': 'العبور',
      'date_en': '6 October 1973',
      'date_ar': '٦ أكتوبر ١٩٧٣',
    },
    {'title_en': 'The ceasefire', 'title_ar': 'وقف إطلاق النار'},
  ],
  'sections': [
    _section('Results', 'النتايج', ['Sinai came back.']),
  ],
});

final CatalogItem _newer = _item({'kind': 'map', 'pins': <Object?>[]});

final AppLocalizations l10nAr = lookupAppLocalizations(const Locale('ar'));

void main() {
  Future<void> pumpView(
    WidgetTester tester,
    CatalogItem item, {
    String? title,
    VoidCallback? onOpen,
    VoidCallback? onUpdate,
    Locale locale = const Locale('en'),
  }) => tester.pumpApp(
    ItemView(
      item: item,
      facts: const DescribeItem()(
        item: item,
        traitSchema: null,
        lang: locale.languageCode,
        now: DateTime(2026, 11),
      ),
      similar: const [],
      onBack: () {},
      onOpenItem: (_) {},
      detailsTitle: title,
      onOpenDetails: onOpen ?? () {},
      onUpdateApp: onUpdate ?? () {},
    ),
    locale: locale,
  );

  group('the details row', () {
    testWidgets('a term: the section names it, its sections preview it', (
      tester,
    ) async {
      var opened = 0;
      await pumpView(
        tester,
        _usage,
        title: 'How to use it',
        onOpen: () => opened++,
      );
      expect(find.byKey(const Key('item_details')), findsOneWidget);
      expect(find.text('In a sentence · Opposite'), findsOneWidget);
      await tester.tap(find.byKey(const Key('item_details')));
      expect(opened, 1);
      await tester.expectAccessible();
    });

    testWidgets('a story counts its events; no title → the app default', (
      tester,
    ) async {
      await pumpView(tester, _story);
      expect(find.text(l10nEn.detailsStory), findsOneWidget);
      expect(find.text(l10nEn.detailsEvents(2)), findsOneWidget);
    });

    testWidgets('details newer than the app ask to update', (tester) async {
      var updates = 0;
      await pumpView(tester, _newer, onUpdate: () => updates++);
      expect(find.byKey(const Key('item_details')), findsNothing);
      expect(find.text(l10nEn.detailsNeedUpdate), findsOneWidget);
      await tester.tap(find.byKey(const Key('item_update')));
      expect(updates, 1);
      await tester.expectAccessible();
    });

    testWidgets('Arabic', (tester) async {
      await pumpView(tester, _newer, locale: const Locale('ar'));
      expect(find.text(l10nAr.detailsNeedUpdate), findsOneWidget);
      await pumpView(tester, _story, locale: const Locale('ar'));
      expect(find.text(l10nAr.detailsEvents(2)), findsOneWidget);
    });

    testWidgets('no details, no row', (tester) async {
      await pumpView(tester, _item({'kind': 'usage'}));
      expect(find.byKey(const Key('item_details')), findsNothing);
      expect(find.byKey(const Key('item_update')), findsNothing);
    });
  });

  group(DetailsView, () {
    Future<List<String>> pumpDetails(
      WidgetTester tester,
      CatalogItem item, {
      Locale locale = const Locale('en'),
      double textScale = 1,
    }) async {
      final events = <String>[];
      await tester.pumpApp(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Material(
            child: DetailsView(
              item: item,
              details: item.details!,
              title: 'The story',
              onClose: () => events.add('close'),
              onStepByStep: item.details!.steps.isEmpty
                  ? null
                  : () => events.add('steps'),
            ),
          ),
        ),
        locale: locale,
      );
      await tester.pumpAndSettle();
      return events;
    }

    testWidgets('a story: dated events in order, then its sections', (
      tester,
    ) async {
      final events = await pumpDetails(tester, _story);
      expect(find.text('6 October 1973'), findsOneWidget);
      expect(find.text('The crossing'), findsOneWidget);
      expect(find.byKey(const Key('details_step_1')), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Sinai came back.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('details_step_by_step')));
      await tester.tap(find.byKey(const Key('details_step_by_step')));
      await tester.tap(find.byKey(const Key('details_close')));
      expect(events, ['steps', 'close']);
      await tester.expectAccessible();
    });

    testWidgets('a term: sections only, no step by step', (tester) async {
      await pumpDetails(tester, _usage);
      expect(find.text('The papers took a month.'), findsOneWidget);
      expect(find.byKey(const Key('details_step_by_step')), findsNothing);
    });

    testWidgets('Arabic, large text (1.6×)', (tester) async {
      await pumpDetails(
        tester,
        _story,
        locale: const Locale('ar'),
        textScale: 1.6,
      );
      expect(find.text('٦ أكتوبر ١٩٧٣'), findsOneWidget);
      expect(find.text('النتايج'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
