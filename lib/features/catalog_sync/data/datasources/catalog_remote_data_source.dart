import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw catalog rows from the server, changed after a point in time.
/// Rows are JSON maps; `CatalogRows` validates them.
abstract interface class CatalogRemoteDataSource {
  Future<List<Object?>> categories({required DateTime since});

  /// How many published items changed after [since].
  Future<int> countItems({required DateTime since});

  /// One page of published items changed after [since], oldest first.
  Future<List<Object?>> items({
    required DateTime since,
    required int offset,
    required int limit,
  });

  /// All search terms of [itemIds].
  Future<List<Object?>> terms({required List<String> itemIds});

  /// Categories and items hidden or deleted after [since] (ids only).
  Future<List<Object?>> removed({required DateTime since});
}

/// Reads the catalog from Supabase (`supabase/migrations/0002_catalog.sql`).
class SupabaseCatalogRemote implements CatalogRemoteDataSource {
  const new(this._client);

  final SupabaseClient _client;

  static const _categoryColumns =
      'id,parent_id,slug,name_ar,name_en,icon,trait_schema,sort_order,'
      'updated_at';
  static const _itemColumns =
      'id,category_id,slug,menu_name,menu_name_ar,explanation_ar,'
      'explanation_en,gist_ar,gist_en,calories,size_ml,price_min_egp,'
      'price_max_egp,'
      'price_updated_at,image_path,audio_barista_path,audio_original_path,'
      'traits,sort_order,recipe,updated_at';

  @override
  Future<List<Object?>> categories({required DateTime since}) => _client
      .from('categories')
      .select(_categoryColumns)
      .gt('updated_at', since.toUtc().toIso8601String())
      .order('updated_at');

  @override
  Future<int> countItems({required DateTime since}) => _client
      .from('items')
      .count()
      .gt('updated_at', since.toUtc().toIso8601String());

  @override
  Future<List<Object?>> items({
    required DateTime since,
    required int offset,
    required int limit,
  }) => _client
      .from('items')
      .select(_itemColumns)
      .gt('updated_at', since.toUtc().toIso8601String())
      .order('updated_at')
      .order('id')
      .range(offset, offset + limit - 1);

  @override
  Future<List<Object?>> terms({required List<String> itemIds}) async {
    if (itemIds.isEmpty) return const [];
    return await _client
        .from('item_terms')
        .select('item_id,term,lang,kind')
        .inFilter('item_id', itemIds);
  }

  @override
  Future<List<Object?>> removed({required DateTime since}) async {
    final rows = await _client.rpc<List<dynamic>>(
      'catalog_removed_since',
      params: {'since': since.toUtc().toIso8601String()},
    );
    return rows;
  }
}

/// Used when the env file has no Supabase values (a fresh clone): every
/// call fails like being offline, so the app shows its offline state.
class UnconfiguredCatalogRemote implements CatalogRemoteDataSource {
  const new();

  Never _fail() =>
      throw const SocketException('Supabase is not configured (env file).');

  @override
  Future<List<Object?>> categories({required DateTime since}) async => _fail();

  @override
  Future<int> countItems({required DateTime since}) async => _fail();

  @override
  Future<List<Object?>> items({
    required DateTime since,
    required int offset,
    required int limit,
  }) async => _fail();

  @override
  Future<List<Object?>> terms({required List<String> itemIds}) async => _fail();

  @override
  Future<List<Object?>> removed({required DateTime since}) async => _fail();
}
