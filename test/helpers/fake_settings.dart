import 'package:yaani_eh/features/settings/domain/entities/app_settings.dart';
import 'package:yaani_eh/features/settings/domain/repositories/settings_repository.dart';

/// Settings kept in memory, for router and screen tests (Settings is a tab,
/// so any test that builds the tabs reads them).
class FakeSettingsRepository implements SettingsRepository {
  new([this._settings = const AppSettings()]);

  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}
