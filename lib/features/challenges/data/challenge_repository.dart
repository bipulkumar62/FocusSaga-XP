import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_guard.dart';
import '../domain/daily_challenge.dart';

/// Talks to the two challenge RPCs. All state changes happen server-side;
/// the app only reads the returned jsonb.
class ChallengeRepository {
  ChallengeRepository(this._client);

  final SupabaseClient _client;

  /// Assigns today's challenges if missing, recomputes progress from live
  /// data, and returns the day's rows.
  Future<List<DailyChallenge>> refreshToday() async {
    final data = await guardNetwork(
      _client.rpc('refresh_daily_challenges'),
      operation: 'load challenges',
    );
    if (data == null) return const [];
    final rows = (data as List).cast<Map<String, dynamic>>();
    return rows.map(DailyChallenge.fromJson).toList();
  }

  /// Claims the reward of a completed challenge.
  /// The RPC rejects double claims (`already claimed`).
  Future<ChallengeClaim> claim(String userChallengeId) async {
    final data = await guardNetwork(
      _client.rpc('claim_challenge_reward', params: {
        'p_user_challenge_id': userChallengeId,
      }),
      operation: 'claim challenge reward',
    );
    return ChallengeClaim.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }
}
