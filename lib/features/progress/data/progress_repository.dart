import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_guard.dart';
import '../domain/reward_summary.dart';

/// Persists one finished session and its rewards.
///
/// All writes happen inside the `save_study_session` RPC (one atomic
/// database transaction): XP + level ups go to `user_characters`, coins to
/// `profiles`, and the session itself to `study_sessions`.
class ProgressRepository {
  ProgressRepository(this._client);

  final SupabaseClient _client;

  /// Saves a finished session and applies its rewards in one transaction.
  ///
  /// The RPC returns the exact numbers that were written (XP, coins, level
  /// before/after), so the UI can show them with confidence.
  Future<RewardSummary> saveSession({
    required int plannedMinutes,
    required int actualMinutes,
    required bool completed,
    required int pausedCount,
    required DateTime startedAt,
    required DateTime endedAt,
    String? characterId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('saveSession called while signed out');
    }
    final data = await guardNetwork(
      _client.rpc('save_study_session', params: {
        'p_planned_minutes': plannedMinutes,
        'p_actual_minutes': actualMinutes,
        'p_completed': completed,
        'p_paused_count': pausedCount,
        'p_started_at': startedAt.toUtc().toIso8601String(),
        'p_ended_at': endedAt.toUtc().toIso8601String(),
        'p_character_id': ?characterId,
      }),
      operation: 'save session',
    );
    final json = Map<String, dynamic>.from(data as Map);
    return RewardSummary.fromJson({
      ...json,
      'actual_minutes': actualMinutes,
      'completed': completed,
    });
  }
}