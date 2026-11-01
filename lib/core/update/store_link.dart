import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaani_eh/core/update/update_service.dart';

/// Opens this app's store page (to update). Returns false when there's no
/// link (offline, not configured). Tests override it.
final openStoreProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final url = await UpdateService.storeUrl();
    if (url == null) return false;
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  },
);
