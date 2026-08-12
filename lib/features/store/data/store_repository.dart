import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_guard.dart';
import '../domain/store_item.dart';

/// Reads the store catalogs, merges ownership state, and buys/equips.
class StoreRepository {
  StoreRepository(this._client);

  final SupabaseClient _client;

  /// Cache of the four master-table lists (characters, backgrounds,
  /// timer_skins, reward_animations). These are static admin-curated rows,
  /// so one fetch per app session is enough; only the user-scoped inventory
  /// queries re-run on every catalog refresh. Populated by [_fetchMaster].
  List<List<Map<String, dynamic>>>? _masterCache;

  /// All active items of all four categories, flagged with the current
  /// user's owned / equipped state.
  ///
  /// The four master-table queries are session-cached (see [_masterCache]),
  /// so after the first load only the two user-scoped queries run.
  Future<StoreCatalog> fetchCatalog() async {
    final user = _client.auth.currentUser;
    if (user == null) return StoreCatalog.empty;

    final master = _masterCache ?? await _fetchMaster();
    final results = await guardNetwork(
      Future.wait([
        _client
            .from('user_inventory')
            .select('item_type, item_id, is_equipped')
            .eq('user_id', user.id),
        _client
            .from('user_characters')
            .select('id, character_id, is_selected')
            .eq('user_id', user.id),
      ]),
      operation: 'load store',
    );

    final inventory = List<Map<String, dynamic>>.from(results[0] as List);
    final ownedChars = List<Map<String, dynamic>>.from(results[1] as List);

    final characters = master[0];
    final backgrounds = master[1];
    final timerSkins = master[2];
    final rewardAnimations = master[3];

    // Ownership maps. item_id is a UUID unique across all master tables,
    // so keying by id alone is collision-safe.
    final ownedIds = <String>{};
    final equippedIds = <String>{};
    for (final row in inventory) {
      final id = row['item_id'] as String?;
      if (id == null) continue;
      ownedIds.add(id);
      if (row['is_equipped'] as bool? ?? false) equippedIds.add(id);
    }

    final ownedCharacterIds = <String>{};
    final selectedCharacterRowIds = <String>{};
    final ucRowByCharacterId = <String, String>{};
    for (final row in ownedChars) {
      final cid = row['character_id'] as String?;
      final rid = row['id'] as String?;
      if (cid == null || rid == null) continue;
      ownedCharacterIds.add(cid);
      ucRowByCharacterId[cid] = rid;
      if (row['is_selected'] as bool? ?? false) selectedCharacterRowIds.add(rid);
    }

    final items = <StoreItem>[
      for (final row in characters)
        StoreItem.fromJson(
          row,
          kind: StoreItemKind.character,
          owned: ownedCharacterIds.contains(row['id']),
          equipped: selectedCharacterRowIds
              .contains(ucRowByCharacterId[row['id']]),
          ownedRowId: ucRowByCharacterId[row['id']],
        ),
      for (final row in backgrounds)
        StoreItem.fromJson(
          row,
          kind: StoreItemKind.background,
          owned: ownedIds.contains(row['id']),
          equipped: equippedIds.contains(row['id']),
        ),
      for (final row in timerSkins)
        StoreItem.fromJson(
          row,
          kind: StoreItemKind.timerSkin,
          owned: ownedIds.contains(row['id']),
          equipped: equippedIds.contains(row['id']),
        ),
      for (final row in rewardAnimations)
        StoreItem.fromJson(
          row,
          kind: StoreItemKind.rewardAnimation,
          owned: ownedIds.contains(row['id']),
          equipped: equippedIds.contains(row['id']),
        ),
    ];

    return StoreCatalog(items: items);
  }

  /// Fetches the four master tables once and stores them for the rest of
  /// the app session. Order: [characters, backgrounds, timer_skins,
  /// reward_animations]. The cache is set *after* a successful fetch so a
  /// failed load never poisons it.
  Future<List<List<Map<String, dynamic>>>> _fetchMaster() async {
    final results = await guardNetwork(
      Future.wait([
        _client
            .from('characters')
            .select(
              'id, name, description, image_url, price_coins, unlock_level, '
              'class_title, static_image_path',
            )
            .eq('active', true)
            .order('is_starter', ascending: false)
            .order('price_coins', ascending: true),
        _client
            .from('backgrounds')
            .select(
              'id, name, description, image_url, price_coins, effect_type, '
              'rarity, preview_asset_path',
            )
            .eq('active', true)
            .order('is_starter', ascending: false)
            .order('price_coins', ascending: true),
        _client
            .from('timer_skins')
            .select('id, name, description, image_url, price_coins')
            .eq('active', true)
            .order('price_coins', ascending: true),
        _client
            .from('reward_animations')
            .select('id, name, description, image_url, price_coins')
            .eq('active', true)
            .order('price_coins', ascending: true),
      ]),
      operation: 'load store catalog',
    );
    final cache = [
      List<Map<String, dynamic>>.from(results[0] as List),
      List<Map<String, dynamic>>.from(results[1] as List),
      List<Map<String, dynamic>>.from(results[2] as List),
      List<Map<String, dynamic>>.from(results[3] as List),
    ];
    _masterCache = cache;
    return cache;
  }

  /// Buys an item. The RPC rejects duplicates / insufficient coins / a too
  /// low player level with a clear message. Returns the new coin balance.
  Future<int> buy(StoreItemKind kind, String itemId) async {
    final data = await guardNetwork(
      _client.rpc('buy_store_item', params: {
        'p_item_type': kind.apiValue,
        'p_item_id': itemId,
      }),
      operation: 'buy item',
    );
    return (Map<String, dynamic>.from(data as Map)['balance'] as num).toInt();
  }

  /// Equips an owned item. Characters use `equip_character` (row id), the
  /// other three categories share `equip_inventory_item`.
  Future<void> equip(StoreItem item) async {
    if (item.kind == StoreItemKind.character) {
      final rowId = item.ownedRowId;
      if (rowId == null) throw StateError('Character not owned');
      await guardNetwork(
        _client.rpc('equip_character', params: {
          'p_user_character_id': rowId,
        }),
        operation: 'equip character',
      );
    } else {
      await guardNetwork(
        _client.rpc('equip_inventory_item', params: {
          'p_item_type': item.kind.apiValue,
          'p_item_id': item.id,
        }),
        operation: 'equip item',
      );
    }
  }
}
