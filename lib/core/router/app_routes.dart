/// Every route path in one place. Each path is also a deep link:
/// `yaanieh://<path>` and, once the domain is verified,
/// `https://example.com<path>`. Document new paths in
/// docs/deep_links.md.
abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';

  /// The Favorites tab.
  static const favorites = '/favorites';

  /// One drink: `/drink/flat_white`.
  static const drinkPattern = '/drink/:slug';
  static String drink(String slug) => '/drink/$slug';

  /// Search, optionally with a query: `/search?q=latte`.
  static const search = '/search';
  static String searchFor(String query) =>
      Uri(path: search, queryParameters: {'q': query}).toString();

  /// A query from a link, made safe: control and direction characters
  /// removed, trimmed, at most 60 characters.
  static String cleanQuery(String? raw) {
    final text = (raw ?? '')
        .replaceAll(
          RegExp(
            r'[\u0000-\u001F\u007F\u200E\u200F\u202A-\u202E\u2066-\u2069]',
          ),
          '',
        )
        .trim();
    return text.length > 60 ? text.substring(0, 60) : text;
  }

  /// What a slug may look like (the same rule as the database).
  static final slugPattern = RegExp(r'^[a-z0-9_]{1,60}$');
}
