import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/challenges/data/challenge_repository.dart';
import '../../features/challenges/domain/daily_challenge.dart';
import '../../features/characters/data/character_repository.dart';
import '../../features/characters/domain/owned_character.dart';
import '../../features/profile/data/profile.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/progress/data/progress_repository.dart';
import '../../features/ranking/data/ranking_repository.dart';
import '../../features/ranking/domain/leaderboard_entry.dart';
import '../../features/store/data/store_repository.dart';
import '../../features/store/domain/store_item.dart';
import '../../shared/domain/season.dart';

/// Riverpod provider exposing the initialized Supabase client.
/// Use this everywhere instead of calling Supabase.instance directly.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth repository singleton.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Reactive auth state. `session != null` means logged in.
/// Safe fallback: if Supabase isn't initialized, emit nothing (logged out).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  try {
    return ref.watch(authRepositoryProvider).authStateChanges;
  } catch (_) {
    return const Stream.empty();
  }
});

/// The signed-in user (null when logged out). Re-emits on every auth change.
final authUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value?.session?.user;
});

/// Ensures a session exists: restores an existing one or signs in as an
/// anonymous guest. The splash screen holds until this completes.
/// Watches [authUserProvider] so that after a sign-out (user becomes null)
/// it re-runs and creates a fresh anonymous guest.
final ensureSessionProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user != null) return;
  await ref.watch(authRepositoryProvider).ensureGuestSession();
});

/// Profile repository singleton.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// Loads the current user's profile, creating it (50 coins, level 1) on first
/// sign-in. Null when logged out; re-runs when the user changes.
final currentProfileProvider = FutureProvider<Profile?>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).ensureProfile(user);
});

/// Progress (XP / coins / level) repository singleton.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(supabaseClientProvider));
});

/// Characters repository singleton.
final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepository(ref.watch(supabaseClientProvider));
});

/// The current user's owned characters, equipped one first.
/// Invalidate after equipping or after any session that granted XP.
final ownedCharactersProvider = FutureProvider<List<OwnedCharacter>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return const [];
  return ref.watch(characterRepositoryProvider).fetchOwnedCharacters();
});

/// Store repository singleton.
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.watch(supabaseClientProvider));
});

/// The store catalog with the current user's ownership state.
/// Invalidate after any purchase or equip.
final storeCatalogProvider = FutureProvider<StoreCatalog>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return StoreCatalog.empty;
  return ref.watch(storeRepositoryProvider).fetchCatalog();
});

/// Challenges repository singleton.
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(ref.watch(supabaseClientProvider));
});

/// Today's challenges with live progress. Calling `refreshToday` also
/// assigns today's rows on the server, so a simple read triggers the
/// daily reset. Invalidate after every study session and after claiming.
final dailyChallengesProvider = FutureProvider<List<DailyChallenge>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return const [];
  return ref.watch(challengeRepositoryProvider).refreshToday();
});

/// Whether the current user has accepted the terms of service.
final termsStatusProvider = FutureProvider<bool>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  return ref.watch(profileRepositoryProvider).hasAcceptedTerms(user.id);
});

/// Ranking repository singleton.
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository(ref.watch(supabaseClientProvider));
});

/// Today's leaderboard, ranked by the server (rank = list position + 1).
/// Invalidate after study sessions, challenge claims or level-ups.
final dailyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return const [];
  return ref.watch(rankingRepositoryProvider).fetchDaily();
});

/// Rolling 7-day leaderboard, ranked by the server.
final weeklyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return const [];
  return ref.watch(rankingRepositoryProvider).fetchWeekly();
});

/// Lifetime focused minutes across the user's completed sessions.
final totalFocusedMinutesProvider = FutureProvider<int>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return 0;
  return ref.watch(profileRepositoryProvider).fetchTotalFocusedMinutes(user.id);
});

/// Current streak in days (server-side consecutive-day counter).
final currentStreakProvider = FutureProvider<int>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return 0;
  return ref.watch(profileRepositoryProvider).fetchCurrentStreak(user.id);
});

/// The currently equipped companion, if any.
///
/// Derived from [ownedCharactersProvider] (which orders the equipped row
/// first) so the heavy characters+forms join is fetched once instead of
/// twice. Invalidating [ownedCharactersProvider] refreshes both.
final selectedCharacterProvider =
    Provider<AsyncValue<OwnedCharacter?>>((ref) {
  final owned = ref.watch(ownedCharactersProvider);
  return owned.when(
    loading: () => const AsyncLoading<OwnedCharacter?>(),
    error: (e, st) => AsyncError<OwnedCharacter?>(e, st),
    data: (list) =>
        AsyncData(list.where((c) => c.isSelected).firstOrNull),
  );
});

/// The globally applied animated season.
///
/// Derived from [storeCatalogProvider] (whose background master-table fetch is
/// session-cached), looking up the equipped `background` item and mapping its
/// `effect_type` to a [SeasonType]. Falls back to Forest Morning when nothing
/// is equipped or the catalog is still loading/errored, so the background
/// layer is never blank. Invalidating [storeCatalogProvider] (after a buy or
/// equip) refreshes this automatically.
final selectedSeasonProvider = Provider<AsyncValue<SeasonType>>((ref) {
  final catalog = ref.watch(storeCatalogProvider);
  return catalog.when(
    loading: () => const AsyncLoading<SeasonType>(),
    error: (e, st) => AsyncError<SeasonType>(e, st),
    data: (store) {
      final equipped = store.items
          .where((i) => i.kind == StoreItemKind.background && i.equipped)
          .firstOrNull;
      return AsyncData(
        SeasonType.fromEffect(equipped?.effectType) ?? SeasonType.fallback,
      );
    },
  );
});