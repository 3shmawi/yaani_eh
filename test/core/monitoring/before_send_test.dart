import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yaani_eh/core/monitoring/monitoring.dart';

void main() {
  group('beforeSend', () {
    test('drops an outage Sentry caught by itself', () {
      final event = SentryEvent(
        throwable: const PostgrestException(message: '', code: '504'),
      );
      expect(Monitoring.dropOutages(event, Hint()), isNull);
    });

    test('keeps a real bug', () {
      final event = SentryEvent(throwable: StateError('bug'));
      expect(Monitoring.dropOutages(event, Hint()), same(event));
    });

    test('keeps an event without an error (a native crash, a message)', () {
      final event = SentryEvent();
      expect(Monitoring.dropOutages(event, Hint()), same(event));
    });
  });
}
