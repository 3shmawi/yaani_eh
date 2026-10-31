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
        'recipe': sampleRecipes[d.$1],
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

/// «طريقة التحضير» of two drinks, as in supabase/content/recipes.json
/// (a few minutes, and a night in the fridge); the others have none yet.
const sampleRecipes = <String, Map<String, Object?>>{
  'flat_white': {
    'minutes': 2,
    'layers': [
      {
        'tone': 'espresso',
        'ml': 60,
        'ar': 'قهوة مركّزة (شوتين)',
        'en': 'Strong coffee (2 shots)',
      },
      {'tone': 'milk', 'ml': 110, 'ar': 'لبن سخن ناعم', 'en': 'Silky hot milk'},
      {'tone': 'foam', 'ml': 10, 'ar': 'رغوة رفيعة', 'en': 'Thin foam'},
    ],
    'steps': [
      {
        'icon': 'grind',
        'title_ar': 'اطحن البن ناعم',
        'title_en': 'Grind the coffee fine',
        'note_ar': 'قريب من نعومة السكر الناعم.',
        'note_en': 'About as fine as caster sugar.',
        'amount_ar': '18 جرام بن',
        'amount_en': '18 g coffee',
      },
      {
        'icon': 'shot',
        'title_ar': 'اعمل شوتين قهوة مركّزة',
        'title_en': 'Pull two strong shots',
        'note_ar': 'لحد ما يطلع سائل تقيل عليه وش بني.',
        'note_en': 'Until a thick shot with a brown crema comes out.',
        'amount_ar': '60 مل',
        'amount_en': '60 ml',
      },
      {
        'icon': 'steam',
        'title_ar': 'سخّن اللبن لحد ما يبقى ناعم',
        'title_en': 'Steam the milk until silky',
        'note_ar': 'بالبخار، من غير ما يغلي. الرغوة تبقى رفيعة جدًا.',
        'note_en': 'Hot, never boiling. The foam stays very thin.',
        'amount_ar': '110 مل',
        'amount_en': '110 ml',
      },
      {
        'icon': 'pour',
        'title_ar': 'صب اللبن على القهوة من قريب',
        'title_en': 'Pour the milk in, close to the cup',
        'note_ar': 'ببطء في النص، وفي الآخر ارسم قلب صغير على الوش.',
        'note_en': 'Slowly, into the middle; finish with a small heart on top.',
        'amount_ar': 'في فنجان 180 مل',
        'amount_en': 'In a 180 ml cup',
      },
    ],
  },
  'cold_brew': {
    'minutes': 720,
    'layers': [
      {'tone': 'ice', 'ml': 100, 'ar': 'تلج', 'en': 'Ice'},
      {
        'tone': 'coffee',
        'ml': 250,
        'ar': 'قهوة متنقّعة في مية ساقعة',
        'en': 'Coffee steeped in cold water',
      },
    ],
    'steps': [
      {
        'icon': 'grind',
        'title_ar': 'اطحن البن خشن',
        'title_en': 'Grind the coffee coarse',
        'note_ar': 'خشن زي الملح الخشن.',
        'note_en': 'Like coarse salt.',
        'amount_ar': '80 جرام بن',
        'amount_en': '80 g coffee',
      },
      {
        'icon': 'steep',
        'title_ar': 'نقّعه في مية ساقعة في التلاجة',
        'title_en': 'Soak it in cold water in the fridge',
        'note_ar': 'طول الليل. المية الساقعة بتطلّع الطعم من غير المرارة.',
        'note_en':
            'Overnight. Cold water draws out the taste without the bitterness.',
        'amount_ar': 'لتر مية · 12 ساعة',
        'amount_en': '1 litre water · 12 hours',
      },
      {
        'icon': 'pour',
        'title_ar': 'صفّيه من البن',
        'title_en': 'Strain out the coffee',
        'note_ar': 'في فلتر قماش أو ورق.',
        'note_en': 'Through a cloth or paper filter.',
      },
      {
        'icon': 'ice',
        'title_ar': 'صبه على تلج',
        'title_en': 'Pour it over ice',
        'amount_ar': '250 مل',
        'amount_en': '250 ml',
      },
    ],
  },
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
