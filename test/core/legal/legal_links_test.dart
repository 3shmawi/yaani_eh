import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/core/legal/legal_links.dart';

void main() {
  group(LegalLinks, () {
    for (final (name, url) in [
      ('privacy', LegalLinks.privacy),
      ('terms', LegalLinks.terms),
    ]) {
      test('$name is an https page that website/ publishes', () {
        expect(url.scheme, 'https');
        expect(url.host, '3shmawi.github.io');
        expect(url.pathSegments.first, 'yaani_eh');
        expect(File('website/${url.pathSegments.last}').existsSync(), isTrue);
      });
    }
  });
}
