import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show HttpExceptionWithStatus;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Every error the UI can show, independent of where it came from
/// (Supabase, HTTP, platform). Repositories return these inside a `Result`
/// instead of throwing.
@immutable
sealed class AppFailure {
  const new([this.cause]);

  /// The original error, for logs and monitoring — never shown to users.
  final Object? cause;

  /// Worth retrying automatically (the device or server may recover).
  bool get isRetryable => false;

  /// Maps any thrown error to a failure.
  static AppFailure from(Object error) => switch (error) {
    AppFailure() => error,
    // A file download (photos, clips) that the server answered.
    HttpExceptionWithStatus(statusCode: 401 || 403) => UnauthorizedFailure(
      error,
    ),
    HttpExceptionWithStatus(:final statusCode)
        when statusCode >= 400 && statusCode < 500 =>
      NotFoundFailure(error),
    HttpExceptionWithStatus(:final statusCode) when statusCode >= 500 =>
      ServerFailure(error),
    SocketException() || HttpException() => NetworkFailure(error),
    TimeoutException() => TimeoutFailure(error),
    AuthException() => UnauthorizedFailure(error),
    PostgrestException(code: 'PGRST116') => NotFoundFailure(error),
    PostgrestException(code: '42501') => UnauthorizedFailure(error),
    PostgrestException(:final String code) when code.startsWith('22') =>
      ValidationFailure(error),
    PostgrestException() => ServerFailure(error),
    FormatException() => ValidationFailure(error),
    _ => UnknownFailure(error),
  };
}

/// No internet or the host can't be reached.
final class NetworkFailure extends AppFailure {
  const new([super.cause]);

  @override
  bool get isRetryable => true;
}

final class TimeoutFailure extends AppFailure {
  const new([super.cause]);

  @override
  bool get isRetryable => true;
}

/// Not signed in, session expired, or not allowed (RLS).
final class UnauthorizedFailure extends AppFailure {
  const new([super.cause]);
}

final class NotFoundFailure extends AppFailure {
  const new([super.cause]);
}

/// Invalid input or data in an unexpected shape.
final class ValidationFailure extends AppFailure {
  const new([super.cause]);
}

final class ServerFailure extends AppFailure {
  const new([super.cause]);

  @override
  bool get isRetryable => true;
}

final class UnknownFailure extends AppFailure {
  const new([super.cause]);
}
