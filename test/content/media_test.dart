import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The photos and clips in supabase/content/media/ are uploaded by hand to
/// the item-images / item-audio buckets (docs/content.md). This keeps the
/// folder, the migrations that point at it and SOURCES.md in step, and the
/// files within the sizes the app and the buckets expect.
void main() {
  const root = 'supabase/content/media';
  final images = Directory('$root/item-images');
  final audio = Directory('$root/item-audio');

  List<File> files(Directory dir) => dir.existsSync()
      ? (dir.listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];
  String name(File f) => f.uri.pathSegments.last;

  final photos = files(images)
      .where((f) => !name(f).endsWith('.thumb.webp'))
      .toList();
  final clips = files(audio);
  final slugs = File('supabase/content/drinks/drinks.csv')
      .readAsLinesSync()
      .skip(1)
      .where((l) => l.trim().isNotEmpty)
      .map((l) => l.split(',').first)
      .toSet();
  final migrations = Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .map((f) => f.readAsStringSync())
      .join('\n');
  final sources = File('$root/SOURCES.md').existsSync()
      ? File('$root/SOURCES.md').readAsStringSync()
      : '';

  test('every photo is a WebP under 300 KB with its thumbnail', () {
    final problems = <String>[];
    for (final photo in photos) {
      final n = name(photo);
      if (!n.endsWith('.webp')) problems.add('$n: not .webp');
      if (photo.lengthSync() > 300 * 1024) problems.add('$n: over 300 KB');
      final thumb = File(
        photo.path.replaceFirst(RegExp(r'\.webp$'), '.thumb.webp'),
      );
      if (!thumb.existsSync()) {
        problems.add('$n: no thumbnail');
      } else if (thumb.lengthSync() > 40 * 1024) {
        problems.add('$n: thumbnail over 40 KB');
      }
    }
    expect(problems, isEmpty);
  });

  test('every clip is a short M4A named <slug>.<voice>.m4a', () {
    final problems = <String>[];
    for (final clip in clips) {
      final n = name(clip);
      if (!RegExp(r'^[a-z0-9_]+\.(barista|original)\.m4a$').hasMatch(n)) {
        problems.add('$n: bad name');
      }
      if (clip.lengthSync() > 50 * 1024) problems.add('$n: over 50 KB');
    }
    expect(problems, isEmpty);
  });

  test('every file belongs to a drink, a migration and SOURCES.md', () {
    final problems = <String>[];
    for (final file in [...photos, ...clips]) {
      final n = name(file);
      if (!slugs.contains(n.split('.').first)) {
        problems.add('$n: no such drink');
      }
      if (!migrations.contains("'$n'")) {
        problems.add('$n: no migration sets it');
      }
      if (!sources.contains('`$n`')) problems.add('$n: not in SOURCES.md');
    }
    expect(problems, isEmpty);
  });

  test('migrations only point at media files that exist', () {
    final referenced = RegExp(
      r"'([a-z0-9_]+(?:\.(?:barista|original))?\.(?:webp|m4a))'",
    ).allMatches(migrations).map((m) => m.group(1)!).toSet();
    final present = {
      for (final f in [...photos, ...clips]) name(f),
    };
    expect(referenced.difference(present), isEmpty);
  });
}
