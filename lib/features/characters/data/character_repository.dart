import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_guard.dart';
import '../domain/owned_character.dart';

/// Loads the user's characters and handles equipping.
class CharacterRepository {
  CharacterRepository(this._client);

  final SupabaseClient _client;

  static const String _select = '''
    id, xp, is_selected, form_unlocked,
    characters (id, name, description, image_url, is_starter,
      class_title, static_image_path,
      character_forms (id, form_name, form_order, unlock_level, image_url))
  ''';

  /// All characters owned by the current user, equipped one first,
  /// forms attached in evolution order.
  Future<List<OwnedCharacter>> fetchOwnedCharacters() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    final rows = await guardNetwork(
      _client
          .from('user_characters')
          .select(_select)
          .eq('user_id', user.id)
          .order('is_selected', ascending: false),
      operation: 'load characters',
    );

    return rows
        .map((row) => OwnedCharacter.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Equips a character owned by the user. The RPC atomically sets
  /// `is_selected` on exactly one row.
  Future<void> equip(String userCharacterId) async {
    await guardNetwork(
      _client.rpc('equip_character', params: {
        'p_user_character_id': userCharacterId,
      }),
      operation: 'equip character',
    );
  }
}
