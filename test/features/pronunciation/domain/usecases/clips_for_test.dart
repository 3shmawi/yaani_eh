import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/catalog.dart';
import 'package:yaani_eh/features/pronunciation/domain/entities/pronunciation.dart';
import 'package:yaani_eh/features/pronunciation/domain/usecases/clips_for.dart';

CatalogItem _item({String? barista, String? original}) => CatalogItem(
  id: '1',
  categoryId: 'c',
  slug: 'flat_white',
  menuName: 'Flat White',
  menuNameAr: 'فلات وايت',
  explanationAr: 'ا',
  explanationEn: 'e',
  audioBaristaPath: barista,
  audioOriginalPath: original,
);

void main() {
  const clips = ClipsFor();

  test('barista first, then original', () {
    expect(clips(_item(barista: 'b.m4a', original: 'o.m4a')), const [
      Clip(voice: Voice.barista, path: 'b.m4a'),
      Clip(voice: Voice.original, path: 'o.m4a'),
    ]);
  });

  test('a missing or blank clip has no button', () {
    expect(clips(_item(original: 'o.m4a')), const [
      Clip(voice: Voice.original, path: 'o.m4a'),
    ]);
    expect(clips(_item(barista: '', original: '   ')), isEmpty);
    expect(clips(_item()), isEmpty);
  });

  test('paths are trimmed', () {
    expect(clips(_item(barista: ' b.m4a ')).single.path, 'b.m4a');
  });

  test('one voice', () {
    final item = _item(barista: 'b.m4a');
    expect(clips.voice(item, Voice.barista)?.path, 'b.m4a');
    expect(clips.voice(item, Voice.original), isNull);
  });

  test('speeds', () {
    expect(PlaybackSpeed.normal.factor, 1);
    expect(PlaybackSpeed.slow.factor, 0.75);
  });
}
