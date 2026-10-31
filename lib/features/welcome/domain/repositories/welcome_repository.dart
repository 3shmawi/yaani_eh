import 'package:yaani_eh/core/network/result.dart';

/// Whether the first-open welcome was seen on this phone.
abstract interface class WelcomeRepository {
  /// True once the welcome was finished or skipped.
  bool get seen;

  Future<Result<void>> markSeen();
}
