import 'dart:async';
import 'dart:io';

import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_remote_data_source.dart';

/// An in-memory server for the catalog: rows shaped like Supabase's,
/// filtered like the real queries (published rows changed after `since`).
/// Flip [online] to simulate airplane mode; [pageDelay] slows the download
/// so a demo can show the progress.
class FakeCatalogRemote implements CatalogRemoteDataSource {
  new({
    List<Map<String, Object?>>? categories,
    List<Map<String, Object?>>? items,
  }) : categoryRows = categories ?? sampleCategories(),
       itemRows = items ?? sampleItems();

  final List<Map<String, Object?>> categoryRows;
  final List<Map<String, Object?>> itemRows;
  final termRows = <Map<String, Object?>>[];
  final removedRows = <Map<String, Object?>>[];

  bool online = true;
  Duration pageDelay = Duration.zero;
  int itemPageCalls = 0;

  Future<void> _call() async {
    if (!online) throw const SocketException('offline (fake)');
    if (pageDelay > Duration.zero) await Future<void>.delayed(pageDelay);
  }

  static bool _after(Map<String, Object?> row, DateTime since) {
    final at = DateTime.tryParse('${row['updated_at']}');
    return at == null || at.isAfter(since);
  }

  static bool _published(Map<String, Object?> row) =>
      row['is_published'] != false;

  @override
  Future<List<Object?>> categories({required DateTime since}) async {
    await _call();
    return [
      for (final r in categoryRows)
        if (_published(r) && _after(r, since)) r,
    ];
  }

  @override
  Future<int> countItems({required DateTime since}) async {
    await _call();
    return itemRows.where((r) => _published(r) && _after(r, since)).length;
  }

  @override
  Future<List<Object?>> items({
    required DateTime since,
    required int offset,
    required int limit,
  }) async {
    await _call();
    itemPageCalls++;
    final rows = [
      for (final r in itemRows)
        if (_published(r) && _after(r, since)) r,
    ];
    return rows.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Object?>> terms({required List<String> itemIds}) async {
    await _call();
    return [
      for (final t in termRows)
        if (itemIds.contains(t['item_id'])) t,
    ];
  }

  @override
  Future<List<Object?>> removed({required DateTime since}) async {
    await _call();
    return [
      for (final r in categoryRows)
        if (!_published(r) && _after(r, since))
          {'kind': 'category', 'id': r['id']},
      for (final r in itemRows)
        if (!_published(r) && _after(r, since)) {'kind': 'item', 'id': r['id']},
      ...removedRows,
    ];
  }
}

/// A uuid for test row [n] (stable, valid).
String fakeId(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

const cafeId = '00000000-0000-4000-8000-0000000c0000';
const coffeeId = '00000000-0000-4000-8000-0000000c0001';
const coldId = '00000000-0000-4000-8000-0000000c0002';

/// A section with no drinks yet: Home shows it as coming soon.
const dessertsId = '00000000-0000-4000-8000-0000000c0003';

List<Map<String, Object?>> sampleCategories() => [
  {
    'id': cafeId,
    'parent_id': null,
    'slug': 'cafe',
    'name_ar': 'مشروبات',
    'name_en': 'Drinks',
    'icon': 'coffee',
    'trait_schema': cafeTraitSchema,
    'sort_order': 0,
    'updated_at': '2026-10-01T10:00:00Z',
  },
  {
    'id': coffeeId,
    'parent_id': cafeId,
    'slug': 'coffee',
    'name_ar': 'قهوة',
    'name_en': 'Coffee',
    'icon': 'coffee',
    'trait_schema': null,
    'sort_order': 0,
    'updated_at': '2026-10-01T10:00:00Z',
  },
  {
    'id': coldId,
    'parent_id': cafeId,
    'slug': 'iced_coffee',
    'name_ar': 'قهوة ساقعة',
    'name_en': 'Iced coffee',
    'icon': 'ice_cream',
    'trait_schema': null,
    'sort_order': 1,
    'updated_at': '2026-10-01T10:00:00Z',
  },
  {
    'id': dessertsId,
    'parent_id': null,
    'slug': 'desserts',
    'name_ar': 'حلويات',
    'name_en': 'Desserts',
    'icon': 'cake',
    'trait_schema': null,
    'sort_order': 1,
    'updated_at': '2026-10-01T10:00:00Z',
  },
];

/// Twelve real drinks from the launch content.
/// The sample drinks. [withAudio]: pronunciation clips for most of them
/// (none for Affogato and Iced Mocha; Cold Brew has only the barista one).
List<Map<String, Object?>> sampleItems({bool withAudio = false}) {
  const drinks = [
    (
      'espresso',
      'Espresso',
      'إسبريسو',
      'قهوة مركزة صغيرة، شفطة أو اتنين.',
      'A small, strong shot of coffee.',
      3,
      false,
    ),
    (
      'cortado',
      'Cortado',
      'كورتادو',
      'إسبريسو مقطوع بشوية لبن سخن بالنص.',
      'Espresso cut with an equal splash of warm milk.',
      60,
      false,
    ),
    (
      'flat_white',
      'Flat White',
      'فلات وايت',
      'إسبريسو دوبل بلبن ناعم قليل. أقوى من اللاتيه.',
      'A double espresso with a little silky milk. Stronger than a latte.',
      110,
      false,
    ),
    (
      'cappuccino',
      'Cappuccino',
      'كابتشينو',
      'إسبريسو ولبن سخن ورغوة كتير.',
      'Espresso, hot milk and lots of foam.',
      130,
      false,
    ),
    (
      'latte',
      'Latte',
      'لاتيه',
      'إسبريسو بلبن سخن كتير ورغوة خفيفة.',
      'Espresso with lots of hot milk and a little foam.',
      190,
      false,
    ),
    (
      'spanish_latte',
      'Spanish Latte',
      'سبانيش لاتيه',
      'لاتيه بلبن مكثف محلّي.',
      'A latte sweetened with condensed milk.',
      240,
      false,
    ),
    (
      'mocha',
      'Mocha',
      'موكا',
      'لاتيه بشوكولاتة.',
      'A latte with chocolate.',
      290,
      false,
    ),
    (
      'affogato',
      'Affogato',
      'أفوجاتو',
      'بولة آيس كريم غرقانة في شوت إسبريسو.',
      'A scoop of ice cream drowned in espresso.',
      150,
      false,
    ),
    (
      'iced_latte',
      'Iced Latte',
      'آيس لاتيه',
      'لاتيه ساقع على تلج.',
      'A latte over ice.',
      130,
      true,
    ),
    (
      'iced_spanish_latte',
      'Iced Spanish Latte',
      'آيس سبانيش لاتيه',
      'لاتيه ساقع بلبن مكثف محلّي.',
      'An iced latte with condensed milk.',
      250,
      true,
    ),
    (
      'cold_brew',
      'Cold Brew',
      'كولد برو',
      'قهوة متنقعة في مية ساقعة ساعات طويلة.',
      'Coffee steeped in cold water for hours.',
      5,
      true,
    ),
    (
      'iced_mocha',
      'Iced Mocha',
      'آيس موكا',
      'موكا ساقعة على تلج.',
      'A mocha over ice.',
      250,
      true,
    ),
  ];
  return [
    for (final (i, d) in drinks.indexed)
      {
        'id': fakeId(i + 1),
        'category_id': d.$7 ? coldId : coffeeId,
        'slug': d.$1,
        'menu_name': d.$2,
        'menu_name_ar': d.$3,
        'explanation_ar': d.$4,
        'explanation_en': d.$5,
        'gist_ar': _gists[d.$1]?.$1,
        'gist_en': _gists[d.$1]?.$2,
        'calories': d.$6,
        'size_ml': 350,
        'price_min_egp': null,
        'price_max_egp': null,
        'price_updated_at': null,
        'image_path': null,
        'audio_barista_path': withAudio && !_noAudio.contains(d.$1)
            ? '${d.$1}.barista.m4a'
            : null,
        'audio_original_path':
            withAudio && !_noAudio.contains(d.$1) && d.$1 != 'cold_brew'
            ? '${d.$1}.original.m4a'
            : null,
        'traits': {'temp': d.$7 ? 'cold' : 'hot', 'milk': true},
        'sort_order': i,
        'is_published': true,
        'updated_at':
            '2026-10-01T10:00:${(i + 10).toString().padLeft(2, '0')}Z',
      },
  ];
}

const _noAudio = {'affogato', 'iced_mocha'};

/// The «يعني» line of some drinks; the others fall back to the first
/// sentence of their explanation.
const _gists = {
  'espresso': ('فنجان قهوة صغير ومركّز', 'A tiny, strong cup of coffee'),
  'flat_white': (
    'قهوة باللبن تقيلة في فنجان صغير',
    'Strong milky coffee in a small cup',
  ),
};

/// The Café section's traits, as in supabase/content/build_seed.py.
const cafeTraitSchema = <Object?>[
  {
    'key': 'temp',
    'type': 'enum',
    'options': [
      {'value': 'hot', 'ar': 'سخن', 'en': 'Hot'},
      {'value': 'cold', 'ar': 'ساقع', 'en': 'Iced'},
      {'value': 'both', 'ar': 'سخن أو ساقع', 'en': 'Hot or iced'},
    ],
  },
  {
    'key': 'sweetness',
    'type': 'scale',
    'labels': {
      'ar': ['سادة', 'مظبوط', 'حلو', 'حلو أوي'],
      'en': ['Not sweet', 'A little sweet', 'Sweet', 'Very sweet'],
    },
  },
  {
    'key': 'milk',
    'type': 'bool',
    'labels': {
      'ar': ['من غير لبن', 'بلبن'],
      'en': ['No milk', 'With milk'],
    },
  },
  {
    'key': 'caffeine',
    'type': 'scale',
    'labels': {
      'ar': ['من غير كافيين', 'خفيف', 'متوسط', 'قوي'],
      'en': ['No caffeine', 'Light', 'Medium', 'Strong'],
    },
  },
];
