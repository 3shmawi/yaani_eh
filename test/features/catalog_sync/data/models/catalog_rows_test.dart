import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/data/models/catalog_rows.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';

import '../../../../helpers/fake_catalog_remote.dart';

void main() {
  final item = sampleItems().first;
  final category = sampleCategories().first;

  group('items', () {
    test('a valid row becomes an item', () {
      final parsed = CatalogRows.item(item)!;
      expect(parsed.menuName, 'Espresso');
      expect(parsed.menuNameAr, 'إسبريسو');
      expect(parsed.calories, 3);
      expect(parsed.traits['temp'], 'hot');
    });

    Map<String, Object?> withTraits(Map<String, Object?> traits) => {
      ...item,
      'traits': {...item['traits']! as Map, ...traits},
    };

    test('calories and size are traits; whole doubles are accepted', () {
      final parsed = CatalogRows.item(withTraits({'calories': 190.0}))!;
      expect(parsed.calories, 190);
      expect(parsed.sizeMl, 350);
    });

    final badNumbers = <String, Object?>{
      'calories is text': 'lots',
      'negative calories': -1,
      'absurd calories': 99999,
      'fractional calories': 1.5,
    };
    for (final MapEntry(:key, :value) in badNumbers.entries) {
      test('a bad trait is ignored, the item kept: $key', () {
        final parsed = CatalogRows.item(withTraits({'calories': value}));
        expect(parsed, isNotNull);
        expect(parsed!.calories, isNull);
      });
    }

    final hostile = <String, Map<String, Object?>>{
      'not a map': {},
      'missing id': {...item}..remove('id'),
      'id is not a uuid': {...item, 'id': "1' OR '1'='1"},
      'slug with SQL': {...item, 'slug': 'x; DROP TABLE items'},
      'slug with capitals': {...item, 'slug': 'Latte'},
      'empty name': {...item, 'menu_name': '   '},
      'name too long': {...item, 'menu_name': 'A' * 81},
      'explanation too long': {...item, 'explanation_ar': 'ق' * 301},
      'name is a number': {...item, 'menu_name': 42},
      'traits is a list': {
        ...item,
        'traits': <Object?>[1, 2],
      },
    };
    for (final MapEntry(:key, :value) in hostile.entries) {
      test('rejects: $key', () {
        expect(CatalogRows.item(key == 'not a map' ? 'nope' : value), isNull);
      });
    }

    group('«طريقة التحضير»', () {
      final flatWhite = sampleItems().firstWhere(
        (r) => r['slug'] == 'flat_white',
      );
      final good = sampleRecipes['flat_white']!;

      test('is read: layers bottom to top, steps in order', () {
        final recipe = CatalogRows.item(flatWhite)!.recipe!;
        expect(recipe.minutes, 2);
        expect(recipe.totalMl, 180);
        expect(recipe.layers.first.tone, RecipeTone.espresso);
        expect(recipe.layers.first.nameAr, 'قهوة مركّزة (شوتين)');
        expect(recipe.layers.last.tone, RecipeTone.foam);
        expect(recipe.steps, hasLength(4));
        expect(recipe.steps.first.icon, StepIcon.grind);
        expect(recipe.steps.first.amount(arabic: true), '18 جرام بن');
      });

      test('survives the trip to the phone and back', () {
        final recipe = CatalogRows.recipe(good)!;
        expect(CatalogRows.recipe(CatalogRows.recipeJson(recipe)), recipe);
      });

      test('a tone or icon this version does not know falls back', () {
        final recipe = CatalogRows.recipe({
          ...good,
          'layers': [
            {'tone': 'unicorn_milk', 'ml': 100, 'ar': 'لبن', 'en': 'Milk'},
          ],
          'steps': [
            {'icon': 'rocket', 'title_ar': 'اشرب', 'title_en': 'Drink'},
          ],
        })!;
        expect(recipe.layers.single.tone, RecipeTone.other);
        expect(recipe.steps.single.icon, StepIcon.other);
      });

      Map<String, Object?> layer([Map<String, Object?> change = const {}]) => {
        'tone': 'milk',
        'ml': 100,
        'ar': 'لبن',
        'en': 'Milk',
        ...change,
      };
      Map<String, Object?> step([Map<String, Object?> change = const {}]) => {
        'icon': 'pour',
        'title_ar': 'صب',
        'title_en': 'Pour',
        ...change,
      };
      final broken = <String, Object?>{
        'a string': 'make coffee',
        'a list': <Object?>[good],
        'no steps': {...good}..remove('steps'),
        'no layers': {...good, 'layers': <Object?>[]},
        'zero minutes': {...good, 'minutes': 0},
        'minutes as text': {...good, 'minutes': '2'},
        'too many steps': {
          ...good,
          'steps': [for (var i = 0; i < 9; i++) step()],
        },
        'a layer of 0 ml': {
          ...good,
          'layers': [
            layer({'ml': 0}),
          ],
        },
        'an absurd layer': {
          ...good,
          'layers': [
            layer({'ml': 1e9}),
          ],
        },
        'a nameless layer': {
          ...good,
          'layers': [
            layer({'ar': '  '}),
          ],
        },
        'a step that is a string': {
          ...good,
          'steps': ['<script>alert(1)</script>'],
        },
        'a title too long': {
          ...good,
          'steps': [
            step({'title_ar': 'ق' * 61}),
          ],
        },
        'a title that is a number': {
          ...good,
          'steps': [
            step({'title_en': 7}),
          ],
        },
      };
      for (final MapEntry(:key, :value) in broken.entries) {
        test('a broken recipe hides only the recipe: $key', () {
          final parsed = CatalogRows.item({
            ...flatWhite,
            'details': value is Map ? {'kind': 'recipe', ...value} : value,
          });
          expect(parsed, isNotNull);
          expect(parsed!.recipe, isNull);
        });
      }

      test('a note too long is dropped, the step kept', () {
        final recipe = CatalogRows.recipe({
          ...good,
          'steps': [
            step({'note_ar': 'ق' * 161}),
          ],
        })!;
        expect(recipe.steps.single.noteAr, isNull);
      });

      test('injection-like text stays text', () {
        const sneaky = "'; DROP TABLE items; --";
        final recipe = CatalogRows.recipe({
          ...good,
          'steps': [
            step({'title_en': sneaky}),
          ],
        })!;
        expect(recipe.steps.single.titleEn, sneaky);
      });
    });

    test('the «يعني» line is read; a broken one is dropped, the item kept', () {
      expect(
        CatalogRows.item({...item, 'gist_ar': ' قهوة بلبن كتير '})!.gistAr,
        'قهوة بلبن كتير',
      );
      for (final bad in <Object?>['', '   ', 'ق' * 61, 42, <Object?>[]]) {
        final parsed = CatalogRows.item({...item, 'gist_en': bad});
        expect(parsed, isNotNull, reason: '$bad');
        expect(parsed!.gistEn, isNull, reason: '$bad');
      }
      // Shown as plain text, never run: an injection-like line stays text.
      const sneaky = "<script>x</script>'; DROP TABLE items;--";
      expect(CatalogRows.item({...item, 'gist_en': sneaky})!.gistEn, sneaky);
    });

    test('unsafe media paths are dropped, the item is kept', () {
      for (final path in ['../secret', '/etc/passwd', 'a' * 301]) {
        final parsed = CatalogRows.item({...item, 'image_path': path})!;
        expect(parsed.imagePath, isNull, reason: path);
      }
      expect(
        CatalogRows.item({...item, 'image_path': 'latte.webp'})!.imagePath,
        'latte.webp',
      );
    });
  });

  group('details by kind', () {
    Map<String, Object?> step([Map<String, Object?> more = const {}]) => {
      'title_ar': 'الشرارة',
      'title_en': 'The spark',
      'date_ar': '٢٥ يناير ٢٠١١',
      'date_en': '25 January 2011',
      ...more,
    };
    Map<String, Object?> section([Map<String, Object?> more = const {}]) => {
      'title_ar': 'في جملة',
      'title_en': 'In a sentence',
      'lines_ar': ['السطر الأول'],
      'lines_en': ['The first line'],
      ...more,
    };
    ItemDetails? read(Object? details) => CatalogRows.details(details);

    test('a story: events in order, then sections', () {
      final story =
          read({
                'kind': 'story',
                'steps': [
                  step(),
                  step({'title_en': 'Then'}),
                ],
                'sections': [section()],
              })!
              as StoryDetails;
      expect(story.steps, hasLength(2));
      expect(story.steps.first.date(arabic: true), '٢٥ يناير ٢٠١١');
      expect(story.steps.first.icon, isNull, reason: 'events have no icon');
      expect(story.sections.single.lines(arabic: false), ['The first line']);
    });

    test('a story without sections is fine', () {
      final story = read({
        'kind': 'story',
        'steps': [step()],
      });
      expect(story, isA<StoryDetails>());
      expect(story!.sections, isEmpty);
    });

    test('usage: sections only', () {
      final usage = read({
        'kind': 'usage',
        'sections': [
          section(),
          section({'title_en': 'Opposite'}),
        ],
      });
      expect(usage, isA<UsageDetails>());
      expect(usage!.steps, isEmpty);
      expect(usage.sections, hasLength(2));
    });

    test('a kind newer than the app is kept as unknown', () {
      expect(
        read({'kind': 'map', 'pins': <Object?>[]}),
        const UnknownDetails('map'),
      );
    });

    test('every kind survives the trip to the phone and back', () {
      for (final details in [
        read({'kind': 'recipe', ...sampleRecipes['flat_white']!}),
        read({
          'kind': 'story',
          'steps': [step()],
          'sections': [section()],
        }),
        read({
          'kind': 'usage',
          'sections': [section()],
        }),
        read({'kind': 'quiz'}),
      ]) {
        expect(read(CatalogRows.detailsJson(details!)), details);
      }
    });

    final hostile = <String, Object?>{
      'a string': '<script>alert(1)</script>',
      'a list': <Object?>[1, 2],
      'no kind': {'steps': <Object?>[]},
      'kind is a number': {'kind': 7},
      'kind with SQL': {'kind': "story'; DROP TABLE items;--"},
      'a story without steps': {'kind': 'story', 'steps': <Object?>[]},
      'a story with 13 steps': {
        'kind': 'story',
        'steps': [for (var i = 0; i < 13; i++) step()],
      },
      'a step that is a string': {
        'kind': 'story',
        'steps': ['oops'],
      },
      'a step title too long': {
        'kind': 'story',
        'steps': [
          step({'title_ar': 'ق' * 61}),
        ],
      },
      'usage without sections': {'kind': 'usage', 'sections': <Object?>[]},
      'a section without lines': {
        'kind': 'usage',
        'sections': [
          section({'lines_ar': <Object?>[]}),
        ],
      },
      'a line that is a number': {
        'kind': 'usage',
        'sections': [
          section({
            'lines_en': [42],
          }),
        ],
      },
      'a line too long': {
        'kind': 'usage',
        'sections': [
          section({
            'lines_ar': ['ق' * 201],
          }),
        ],
      },
      'nine lines': {
        'kind': 'usage',
        'sections': [
          section({'lines_ar': List.filled(9, 'سطر')}),
        ],
      },
      'seven sections': {
        'kind': 'usage',
        'sections': List.filled(7, section()),
      },
    };
    for (final MapEntry(:key, :value) in hostile.entries) {
      test('broken details hide only the details: $key', () {
        expect(read(value), isNull);
        final parsed = CatalogRows.item({...item, 'details': value});
        expect(parsed, isNotNull);
        expect(parsed!.details, isNull);
      });
    }

    test('injection-like text stays text', () {
      const evil = "<img src=x onerror=alert(1)>'; DROP TABLE items;--";
      final usage = read({
        'kind': 'usage',
        'sections': [
          section({
            'lines_ar': [evil],
          }),
        ],
      })!;
      expect(usage.sections.single.linesAr.single, evil);
    });
  });

  group('categories', () {
    test('a section keeps its trait schema and kind of details', () {
      final parsed = CatalogRows.category(category)!;
      expect(parsed.isSection, isTrue);
      expect(parsed.traitSchema, isNotEmpty);
      expect(parsed.detailKind, DetailKind.recipe);
      expect(parsed.detailsTitle(arabic: true), 'طريقة التحضير');
    });

    test('an unknown kind of details is none; chips never have one', () {
      expect(
        CatalogRows.category({...category, 'detail_kind': 'map'})!.detailKind,
        isNull,
      );
      final chip = CatalogRows.category({
        ...sampleCategories()[1],
        'detail_kind': 'recipe',
        'details_title_ar': 'x',
      })!;
      expect(chip.isSection, isFalse);
      expect(chip.detailKind, isNull);
      expect(chip.detailsTitleAr, isNull);
    });

    test('rejects broken rows', () {
      expect(CatalogRows.category({...category, 'slug': 'Bad Slug'}), isNull);
      expect(CatalogRows.category({...category, 'name_ar': ''}), isNull);
      expect(
        CatalogRows.category({...category, 'trait_schema': 'oops'}),
        isNull,
      );
      expect(
        CatalogRows.category({...category, 'parent_id': 'not-a-uuid'}),
        isNull,
      );
    });
  });

  group('terms and removals', () {
    test('a valid term', () {
      final parsed = CatalogRows.term({
        'item_id': fakeId(1),
        'term': 'قهوة',
        'lang': 'ar',
        'kind': 'ingredient',
      })!;
      expect(parsed.$1, fakeId(1));
      expect(parsed.$2.lang, TermLang.ar);
      expect(parsed.$2.kind, TermKind.ingredient);
    });

    test('rejects unknown languages and long terms', () {
      expect(
        CatalogRows.term({'item_id': fakeId(1), 'term': 'x', 'lang': 'xx'}),
        isNull,
      );
      expect(
        CatalogRows.term({
          'item_id': fakeId(1),
          'term': 'x' * 61,
          'lang': 'en',
        }),
        isNull,
      );
    });

    test('removals are categories or items only', () {
      expect(CatalogRows.removed({'kind': 'item', 'id': fakeId(3)}), isNotNull);
      expect(CatalogRows.removed({'kind': 'user', 'id': fakeId(3)}), isNull);
      expect(CatalogRows.removed({'kind': 'item', 'id': 'x'}), isNull);
    });

    test('broken JSON decodes to null', () {
      expect(CatalogRows.decode('{oops'), isNull);
      expect(CatalogRows.decode(null), isNull);
      expect(CatalogRows.decode('{"a":1}'), {'a': 1});
    });
  });
}
