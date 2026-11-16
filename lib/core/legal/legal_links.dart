import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// The app's legal pages, published from `website/` with the app
/// (GitHub Pages). Settings → About links to them.
abstract final class LegalLinks {
  static final Uri privacy = Uri.parse(
    'https://3shmawi.github.io/yaani_eh/privacy.html',
  );
  static final Uri terms = Uri.parse(
    'https://3shmawi.github.io/yaani_eh/terms.html',
  );
}

/// Opens a URL in the browser; false when nothing could open it. Only ever
/// called with the fixed `LegalLinks`. Tests override it.
final openLinkProvider = Provider<Future<bool> Function(Uri url)>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);
