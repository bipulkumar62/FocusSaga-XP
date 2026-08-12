import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_guard.dart';
import '../domain/leaderboard_entry.dart';

/// Reads the ranking views. The server already ranks and orders the rows;
/// the app only maps them to [LeaderboardEntry]s.
///
/// Bounded to the top [limit] entries so the view (which ranks every user,
/// including a per-user streak lateral call) never runs unbounded.
class RankingRepository {
  RankingRepository(this._client);

  final SupabaseClient _client;

  /// How many entries the app fetches. The server still ranks the whole
  /// population; this only bounds the payload and the final sort.
  static const int limit = 50;

  Future<List<LeaderboardEntry>> fetchDaily() async {
    final data = await guardNetwork(
      _client
          .from('daily_leaderboard')
          .select()
          .order('rank_points', ascending: false)
          .limit(limit),
      operation: 'load daily ranking',
    );
    return _mapRows(data);
  }

  Future<List<LeaderboardEntry>> fetchWeekly() async {
    final data = await guardNetwork(
      _client
          .from('weekly_leaderboard')
          .select()
          .order('rank_points', ascending: false)
          .limit(limit),
      operation: 'load weekly ranking',
    );
    return _mapRows(data);
  }

  List<LeaderboardEntry> _mapRows(dynamic data) {
    if (data == null) return const [];
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
  }
}
