import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaani_eh/app/app.dart';
import 'package:yaani_eh/bootstrap.dart';
import 'package:yaani_eh/core/di/dependencies.dart';
import 'package:yaani_eh/core/network/connectivity.dart';
import 'package:yaani_eh/core/ui/app_ui.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_database.dart';

import '../../test/helpers/fake_catalog_remote.dart';
import 'demo.dart';

/// Starts the real app as a fresh install, with the menu served by
/// [FakeCatalogRemote] (CI has no Supabase) and connectivity under the
/// test's control, so flows like "go offline" are scripted.
class DemoApp {
  new _(this.remote, this._online);

  final FakeCatalogRemote remote;
  final StreamController<bool> _online;

  static Future<DemoApp> start({int pageSize = 4}) async {
    final remote = FakeCatalogRemote()
      // Slow enough for the download to be seen in a recorded demo.
      ..pageDelay = const Duration(milliseconds: isDemo ? 700 : 30);
    final online = StreamController<bool>.broadcast();
    ConnectivityStatus.override = online.stream;
    await bootstrap(
      () => const App(),
      overrides: DependencyOverrides(
        catalogRemote: remote,
        catalogDatabase: CatalogDatabase(NativeDatabase.memory()),
        catalogPageSize: pageSize,
      ),
    );
    return DemoApp._(remote, online);
  }

  /// Airplane mode on / off.
  Future<void> setOnline(WidgetTester tester, {required bool online}) async {
    remote.online = online;
    _online.add(online);
    await tester.pump();
  }

  /// Closes the app and opens it again (the device keeps its data).
  Future<void> relaunch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(AppUi.wrap(const App()));
    await tester.pump();
  }
}

/// Pumps until [finder] shows up (async work like a sync), or fails.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
