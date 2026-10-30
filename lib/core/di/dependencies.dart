import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaani_eh/core/backend/backend.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_database.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_local_data_source.dart';
import 'package:yaani_eh/features/catalog_sync/data/datasources/catalog_remote_data_source.dart';
import 'package:yaani_eh/features/catalog_sync/data/repositories/catalog_repository_impl.dart';
import 'package:yaani_eh/features/catalog_sync/domain/repositories/catalog_repository.dart';
import 'package:yaani_eh/features/pronunciation/data/datasources/audio_cache.dart';
import 'package:yaani_eh/features/pronunciation/data/datasources/just_audio_clip_player.dart';
import 'package:yaani_eh/features/pronunciation/data/repositories/pronunciation_repository_impl.dart';
import 'package:yaani_eh/features/pronunciation/domain/repositories/pronunciation_repository.dart';
import 'package:yaani_eh/features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'package:yaani_eh/features/settings/domain/repositories/settings_repository.dart';

/// Composition root: the only place that knows which implementation backs
/// each domain interface. Add new repositories / services here.
abstract final class Dependencies {
  static late SettingsRepository settingsRepository;
  static late CatalogRepository catalogRepository;
  static late PronunciationRepository pronunciationRepository;
  static late ClipPlayer clipPlayer;

  static Future<void> init([DependencyOverrides? overrides]) async {
    final prefs = await SharedPreferences.getInstance();
    settingsRepository = SharedPrefsSettingsRepository(prefs);
    catalogRepository = CatalogRepositoryImpl(
      overrides?.catalogRemote ??
          (Backend.isConfigured
              ? SupabaseCatalogRemote(Backend.client)
              : const UnconfiguredCatalogRemote()),
      CatalogLocalDataSource(overrides?.catalogDatabase ?? CatalogDatabase()),
      pageSize: overrides?.catalogPageSize ?? 100,
    );
    pronunciationRepository =
        overrides?.pronunciationRepository ??
        PronunciationRepositoryImpl(AudioCache.instance);
    clipPlayer = overrides?.clipPlayer ?? JustAudioClipPlayer();
  }
}

/// Swaps real services for fakes in integration tests and demos.
@immutable
class DependencyOverrides {
  const new({
    this.catalogRemote,
    this.catalogDatabase,
    this.catalogPageSize,
    this.pronunciationRepository,
    this.clipPlayer,
  });

  final CatalogRemoteDataSource? catalogRemote;

  /// e.g. `CatalogDatabase(NativeDatabase.memory())` for a fresh install.
  final CatalogDatabase? catalogDatabase;

  /// Smaller pages make the first-download progress visible in a demo.
  final int? catalogPageSize;

  /// Clips without Supabase (CI) and a player that doesn't need speakers.
  final PronunciationRepository? pronunciationRepository;
  final ClipPlayer? clipPlayer;
}
