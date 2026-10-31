import 'package:meta/meta.dart';

/// A drink the user saved, and when.
@immutable
class Favorite {
  const new({required this.itemId, required this.savedAt});

  final String itemId;
  final DateTime savedAt;

  @override
  bool operator ==(Object other) =>
      other is Favorite && other.itemId == itemId && other.savedAt == savedAt;

  @override
  int get hashCode => Object.hash(itemId, savedAt);
}
