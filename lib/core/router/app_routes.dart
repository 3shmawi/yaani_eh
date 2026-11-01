/// Every route path in one place. Each path is also a deep link:
/// `yaanieh://<path>` and, once the domain is verified,
/// `https://example.com<path>`. Document new paths in
/// docs/deep_links.md.
abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';

  /// The first-open welcome. Home redirects here until it's been seen.
  static const welcome = '/welcome';

  /// The Favorites tab.
  static const favorites = '/favorites';

  /// One section of Home (drinks, terms, …), by its slug: `/section/cafe`.
  static const sectionPattern = '/section/:slug';
  static String section(String slug) => '/section/$slug';

  /// One item (a drink, a term, …): `/item/flat_white`.
  static const itemPattern = '/item/:slug';
  static String item(String slug) => '/item/$slug';

  /// An item's details, one step at a time:
  /// `/item/flat_white/steps` (over the item page).
  static const itemStepsSegment = 'steps';
  static String itemSteps(String slug) => '/item/$slug/$itemStepsSegment';

  /// The old item path from earlier versions. Links to `/drink/...` still
  /// work: the router sends them to the same place under `/item/...`.
  static const legacyItemPrefix = '/drink';

  /// `/drink/<rest>` → `/item/<rest>` (query kept); anything else → null.
  static String? fromLegacy(Uri uri) {
    final path = uri.path;
    if (path != legacyItemPrefix && !path.startsWith('$legacyItemPrefix/')) {
      return null;
    }
    final rest = path.substring(legacyItemPrefix.length);
    return uri.replace(path: '/item$rest').toString();
  }

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
