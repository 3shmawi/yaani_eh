import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show HttpExceptionWithStatus;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yaani_eh/core/network/app_failure.dart';

void main() {
  group('isOutage: not a bug, not reported', () {
    test('no network, a timeout, a gateway or server that is down', () {
      for (final e in <Object>[
        const SocketException('no route'),
        ClientException("SocketException: Failed host lookup: 'x'"),
        TimeoutException('slow'),
        AuthRetryableFetchException(message: 'Failed host lookup'),
        const PostgrestException(message: '', code: '504'),
        const PostgrestException(message: '', code: '503'),
        const PostgrestException(message: '', code: '502'),
        const HttpExceptionWithStatus(504, 'Invalid statusCode: 504'),
        const FunctionException(status: 503),
        const StorageException('down', statusCode: '502'),
        const NetworkFailure(),
      ]) {
        expect(isOutage(e), isTrue, reason: '$e');
      }
    });

    test('everything else is still reported', () {
      for (final e in <Object>[
        const PostgrestException(message: 'boom', code: '500'),
        const PostgrestException(message: 'denied', code: '42501'),
        const PostgrestException(message: 'none', code: 'PGRST116'),
        const HttpExceptionWithStatus(500, 'Invalid statusCode: 500'),
        const HttpExceptionWithStatus(404, 'Invalid statusCode: 404'),
        const FunctionException(status: 500),
        const StorageException('missing', statusCode: '404'),
        const FormatException('bad'),
        StateError('bug'),
        ArgumentError('bug'),
      ]) {
        expect(isOutage(e), isFalse, reason: '$e');
      }
    });

    test('a ClientException is a network failure', () {
      expect(
        AppFailure.from(ClientException('Connection closed')),
        isA<NetworkFailure>(),
      );
    });
  });
}
