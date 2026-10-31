import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/taste_profile/domain/entities/taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/usecases/match_taste.dart';
import 'package:yaani_eh/features/taste_profile/domain/usecases/taste_questions.dart';

import '../../../helpers/fake_catalog_remote.dart';

CatalogItem _drink(String slug, Map<String, Object?> traits) => CatalogItem(
  id: slug,
  categoryId: 'c',
  slug: slug,
  menuName: slug,
  menuNameAr: slug,
  explanationAr: 'ق',
  explanationEn: 'x',
  traits: traits,
);

void main() {
  final questions = const TasteQuestions()(cafeTraitSchema);

  group(TasteQuestions, () {
    test('reads the four questions of the drinks, in order', () {
      expect(questions.map((q) => q.key), [
        'temp',
        'sweetness',
        'milk',
        'caffeine',
      ]);
      final temp = questions.first;
      expect(temp.kind, TasteKind.choice);
      expect(temp.question(arabic: true), 'بتحب مشروبك سخن ولا ساقع؟');
      expect(temp.options.map((o) => o.value), ['hot', 'cold', 'both']);
      final sweet = questions[1];
      expect(sweet.kind, TasteKind.scale);
      expect(sweet.options.map((o) => o.value), [0, 1, 2, 3]);
      expect(sweet.options[2].label(arabic: true), 'حلو');
      final milk = questions[2];
      expect(milk.kind, TasteKind.yesNo);
      // Yes first, the way people say it.
      expect(milk.options.map((o) => o.value), [true, false]);
      expect(milk.options.first.label(arabic: false), 'With milk');
    });

    test('no schema, no questions', () {
      expect(const TasteQuestions()(null), isEmpty);
      expect(const TasteQuestions()(const []), isEmpty);
    });

    final good = cafeTraitSchema.first! as Map<String, Object?>;
    final hostile = <String, Object?>{
      'not a map': 'temp',
      'no key': {...good}..remove('key'),
      'key is a number': {...good, 'key': 7},
      'a huge key': {...good, 'key': 'k' * 41},
      'no question': {...good}..remove('question'),
      'question in one language': {
        ...good,
        'question': {'ar': 'سخن؟'},
      },
      'an empty question': {
        ...good,
        'question': {'ar': '  ', 'en': 'Hot?'},
      },
      'a question too long': {
        ...good,
        'question': {'ar': 'ق' * 81, 'en': 'Hot?'},
      },
      'unknown type': {...good, 'type': 'slider'},
      'one option': {
        ...good,
        'options': [
          {'value': 'hot', 'ar': 'سخن', 'en': 'Hot'},
        ],
      },
      'options not a list': {...good, 'options': 'hot,cold'},
      'too many options': {
        ...good,
        'options': [
          for (var i = 0; i < 7; i++) {'value': 'v$i', 'ar': 'ق', 'en': 'x'},
        ],
      },
      'scale labels of different lengths': {
        'key': 'sweetness',
        'type': 'scale',
        'question': {'ar': 'حلو؟', 'en': 'Sweet?'},
        'labels': {
          'ar': ['سادة', 'حلو'],
          'en': ['Plain'],
        },
      },
      'yes/no with three labels': {
        'key': 'milk',
        'type': 'bool',
        'question': {'ar': 'لبن؟', 'en': 'Milk?'},
        'labels': {
          'ar': ['لا', 'آه', 'يمكن'],
          'en': ['No', 'Yes', 'Maybe'],
        },
      },
    };
    for (final MapEntry(:key, :value) in hostile.entries) {
      test('skips a broken entry: $key', () {
        expect(const TasteQuestions()([value]), isEmpty);
      });
    }

    test('options with a broken label are left out, the rest kept', () {
      final q = const TasteQuestions()([
        {
          ...good,
          'options': [
            {'value': 'hot', 'ar': 'سخن', 'en': 'Hot'},
            {'value': 'cold', 'ar': 'ساقع', 'en': 'Iced'},
            {'value': 1, 'ar': 'ق', 'en': 'x'},
            {'value': 'odd', 'ar': '<script>', 'en': 7},
          ],
        },
      ]);
      expect(q.single.options.map((o) => o.value), ['hot', 'cold']);
    });

    test('injection-like text stays text', () {
      const sneaky = "'; DROP TABLE items; --";
      final q = const TasteQuestions()([
        {
          ...good,
          'question': {'ar': sneaky, 'en': sneaky},
        },
      ]);
      expect(q.single.questionEn, sneaky);
    });

    test('at most eight questions', () {
      final many = [
        for (var i = 0; i < 12; i++) {...good, 'key': 'k$i'},
      ];
      expect(const TasteQuestions()(many), hasLength(8));
    });
  });

  group(MatchTaste, () {
    const match = MatchTaste();
    const iced = TasteProfile({'temp': 'cold', 'sweetness': 2, 'milk': true});
    final icedSpanish = _drink('iced_spanish', {
      'temp': 'cold',
      'sweetness': 2,
      'milk': true,
    });
    final espresso = _drink('espresso', {
      'temp': 'hot',
      'sweetness': 0,
      'milk': false,
    });
    final latte = _drink('latte', {
      'temp': 'both',
      'sweetness': 1,
      'milk': true,
    });

    test('a perfect fit scores 1, with every answer as a reason', () {
      final m = match.score(icedSpanish, iced, questions);
      expect(m.score, 1);
      expect(m.why.map((o) => o.label(arabic: true)), ['ساقع', 'حلو', 'بلبن']);
    });

    test('the opposite scores low, with no reasons', () {
      final m = match.score(espresso, iced, questions);
      expect(m.score, lessThan(0.3));
      expect(m.why, isEmpty);
    });

    test('«سخن أو ساقع» fits either way; sweetness by distance', () {
      final m = match.score(latte, iced, questions);
      // temp 1 (both), sweetness 1 − 1/3, milk 1.
      expect(m.score, closeTo((1 + 2 / 3 + 1) / 3, 1e-9));
      expect(m.why, hasLength(3));
      final either = match.score(
        espresso,
        const TasteProfile({'temp': 'both'}),
        questions,
      );
      expect(either.score, 1);
    });

    test('a drink without the trait counts as half a fit', () {
      final m = match.score(
        _drink('x', const {}),
        const TasteProfile({'milk': true}),
        questions,
      );
      expect(m.score, 0.5);
      expect(m.why, isEmpty);
    });

    test('«مش فارقة معايا» everywhere: nothing to rank by', () {
      expect(
        match.rank([icedSpanish, espresso], const TasteProfile({}), questions),
        isEmpty,
      );
    });

    test('ranks best first, drops poor fits, keeps the menu order on ties', () {
      final twin = _drink('twin', {
        'temp': 'cold',
        'sweetness': 2,
        'milk': true,
      });
      final ranked = match.rank(
        [latte, espresso, icedSpanish, twin],
        iced,
        questions,
      );
      expect(ranked.map((m) => m.item.slug), ['iced_spanish', 'twin', 'latte']);
      expect(
        match.rank([latte, icedSpanish, twin], iced, questions, limit: 1),
        hasLength(1),
      );
    });

    test('a wrong-typed trait or answer never crashes', () {
      final odd = _drink('odd', {
        'sweetness': 'very',
        'temp': 3,
        'milk': 'yes',
      });
      final m = match.score(odd, iced, questions);
      expect(m.score, inInclusiveRange(0, 1));
    });
  });
}
