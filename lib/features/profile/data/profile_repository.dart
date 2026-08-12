import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_guard.dart';
import 'profile.dart';

/// Reads/writes the `profiles` and `terms_acceptance` tables.
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const int _defaultCoins = 50;
  static const int _defaultLevel = 1;
  static const String _termsVersion = '1.0';

  /// Users whose starter kit was already repaired in this app session
  /// (the RPC is idempotent, so running it once per session is enough).
  final Set<String> _startersRepaired = {};

  /// Returns the profile row for [userId], or null if it does not exist.
  Future<Profile?> fetchProfile(String userId) async {
    final row = await guardNetwork(
      _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
      operation: 'load profile',
    );
    return row == null ? null : Profile.fromJson(row);
  }

  /// Creates the profile row if missing, then returns it.
  ///
  /// New profiles get: coins = 50, profile_level = 1,
  /// tutorial_completed = false. Guest metadata (display_name / email /
  /// avatar_url) is used when present; anonymous guests fall back to
  /// "Guest Learner" with no email/avatar.
  ///
  /// After the profile is ready, the idempotent server-side starter kit
  /// repair runs, so a user missing starter items never gets stuck on an
  /// empty Characters/Store screen.
  Future<Profile> ensureProfile(User user) async {
    final existing = await fetchProfile(user.id);
    if (existing != null) {
      await _repairStartersSilently(user.id);
      return existing;
    }

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final displayName = (meta['display_name'] ?? meta['name'] ?? meta['full_name']) as String?;
    final avatarUrl = (meta['avatar_url'] ?? meta['picture']) as String?;

    await guardNetwork(
      _client.from('profiles').insert({
        'user_id': user.id,
        'display_name': displayName ?? 'Guest Learner',
        'email': user.email, // null for anonymous guests (column is nullable)
        'avatar_url': avatarUrl,
        'coins': _defaultCoins,
        'profile_level': _defaultLevel,
        'tutorial_completed': false,
      }),
      operation: 'create profile',
    );

    final created = await fetchProfile(user.id);
    if (created == null) {
      throw Exception('Profile was not created for user ${user.id}');
    }
    await _repairStartersSilently(user.id);
    return created;
  }

  /// Runs the idempotent starter-item repair. Runs at most once per user per
  /// app session; failures are logged but never block the profile load — the
  /// UI surfaces the real error state instead of hanging on a missing starter.
  Future<void> _repairStartersSilently(String userId) async {
    if (_startersRepaired.contains(userId)) return;
    _startersRepaired.add(userId);
    try {
      await guardNetwork(
        _client.rpc('ensure_starter_items_for_current_user'),
        operation: 'repair starter items',
      );
    } catch (e) {
      debugPrint('Starter repair failed (non-fatal): $e');
    }
  }

  /// Server-side repair of the starter kit for the current user.
  /// Call it from a Retry action when the Characters screen is empty.
  Future<void> repairStarterItems() =>
      guardNetwork(
        _client.rpc('ensure_starter_items_for_current_user'),
        operation: 'repair starter items',
      );

  /// Sets the profile's display name (the leaderboard shows it too).
  Future<void> updateDisplayName(String userId, String displayName) async {
    await guardNetwork(
      _client
          .from('profiles')
          .update({'display_name': displayName})
          .eq('user_id', userId),
      operation: 'save name',
    );
  }

  /// True once the user has accepted the terms of service.
  Future<bool> hasAcceptedTerms(String userId) async {
    final row = await guardNetwork(
      _client
          .from('terms_acceptance')
          .select('accepted')
          .eq('user_id', userId)
          .maybeSingle(),
      operation: 'load terms status',
    );
    return row?['accepted'] as bool? ?? false;
  }

  /// Records terms acceptance (insert on first accept, update after).
  Future<void> acceptTerms(String userId) async {
    await guardNetwork(
      _client.from('terms_acceptance').upsert({
        'user_id': userId,
        'accepted': true,
        'terms_version': _termsVersion,
        'accepted_at': DateTime.now().toUtc().toIso8601String(),
      }),
      operation: 'accept terms',
    );
  }

  /// Marks the onboarding tutorial as completed on the user's profile.
  Future<void> completeTutorial(String userId) async {
    await guardNetwork(
      _client
          .from('profiles')
          .update({'tutorial_completed': true})
          .eq('user_id', userId),
      operation: 'complete tutorial',
    );
  }

  /// Sum of all focused minutes across the user's completed sessions.
  ///
  /// Aggregated server-side (`SUM`) so the client never downloads the full
  /// session history. Falls back to the old row-by-row fold only if the
  /// aggregate select is unsupported; timeouts still surface as errors.
  Future<int> fetchTotalFocusedMinutes(String userId) async {
    try {
      final row = await guardNetwork(
        _client
            .from('study_sessions')
            .select('actual_minutes.sum()')
            .eq('user_id', userId)
            .maybeSingle(),
        operation: 'load total focused minutes',
      );
      final value = row?['sum'] as num?;
      return value?.toInt() ?? 0;
    } on PostgrestException {
      final rows = await guardNetwork(
        _client
            .from('study_sessions')
            .select('actual_minutes')
            .eq('user_id', userId),
        operation: 'load total focused minutes',
      );
      return rows.fold<int>(
        0,
        (sum, row) => sum + ((row['actual_minutes'] as num?)?.toInt() ?? 0),
      );
    }
  }

  /// Consecutive days with at least one completed session (server-side RPC).
  Future<int> fetchCurrentStreak(String userId) async {
    final value = await guardNetwork(
      _client.rpc('current_streak', params: {'p_user_id': userId}),
      operation: 'load streak',
    );
    return (value as num?)?.toInt() ?? 0;
  }
}