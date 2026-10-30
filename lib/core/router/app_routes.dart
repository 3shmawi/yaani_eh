/// Every route path in one place. Each path is also a deep link:
/// `yaanieh://<path>` and, once the domain is verified,
/// `https://example.com<path>`. Document new paths in
/// docs/deep_links.md.
abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';

  /// One drink: `/drink/flat_white`.
  static const drinkPattern = '/drink/:slug';
  static String drink(String slug) => '/drink/$slug';

  /// What a slug may look like (the same rule as the database).
  static final slugPattern = RegExp(r'^[a-z0-9_]{1,60}$');
}
