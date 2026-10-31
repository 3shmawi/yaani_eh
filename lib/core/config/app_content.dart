/// What the app shows of its content. Switches here hide a kind of
/// content everywhere at once, while it keeps syncing, so turning it back
/// on is one line.
abstract final class AppContent {
  /// Prices at cafés. Hidden: the app explains what a drink is, not what it
  /// costs (and prices change faster than we can check them).
  static const showPrices = false;
}
