import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/app/presentation/app_shell.dart';
import '../../features/challenges/presentation/challenges_tab.dart';
import '../../features/characters/presentation/characters_tab.dart';
import '../../features/focus/presentation/focus_tab.dart';
import '../../features/profile/presentation/profile_setup_page.dart';
import '../../features/profile/presentation/profile_tab.dart';
import '../../features/ranking/presentation/ranking_tab.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/store/presentation/store_tab.dart';
import '../../features/terms/presentation/legal_documents_page.dart';
import '../../features/terms/presentation/terms_page.dart';
import '../../features/tutorial/presentation/tutorial_page.dart';
import '../supabase/supabase_providers.dart';

/// Application routes with onboarding gating:
///
/// 1. no session yet (restoring or creating an anonymous guest) -> /splash
/// 2. profile loading/error     -> /splash (spinner or retry)
/// 3. terms not accepted        -> /terms
/// 4. terms ok, tutorial pending-> /tutorial
/// 5. everything done           -> main shell (default tab: /focus)
final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authUserProvider);
  final loggedIn = user != null;
  final profile = ref.watch(currentProfileProvider).value;
  final termsAccepted = ref.watch(termsStatusProvider).value ?? false;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // No session yet (restoring an existing one or signing in as an
      // anonymous guest happens on the splash screen).
      if (!loggedIn) {
        return location == '/splash' ? null : '/splash';
      }

      // Profile not loaded yet (loading or failed) -> hold on splash.
      if (profile == null) {
        return location == '/splash' ? null : '/splash';
      }

      // Terms gate.
      if (!termsAccepted) {
        if (location == '/terms' || location == '/legal') return null;
        return '/terms';
      }

      // Tutorial gate.
      if (!profile.tutorialCompleted) {
        return location == '/tutorial' ? null : '/tutorial';
      }

      // Name setup gate: anonymous guests start as "Guest Learner" and
      // must pick a name before the main app.
      if (ProfileSetupPage.needsNameSetup(profile.displayName)) {
        return location == '/profile-setup' ? null : '/profile-setup';
      }

      // Fully onboarded: land on the Focus tab.
      if (location == '/terms' ||
          location == '/tutorial' ||
          location == '/profile-setup' ||
          location == '/' ||
          location == '/splash') {
        return '/focus';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: SplashPage.routeName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/terms',
        name: TermsPage.routeName,
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: '/legal',
        name: LegalDocumentsPage.routeName,
        builder: (context, state) => LegalDocumentsPage(
          initial: state.extra is LegalDocument
              ? state.extra! as LegalDocument
              : LegalDocument.terms,
        ),
      ),
      GoRoute(
        path: '/tutorial',
        name: TutorialPage.routeName,
        builder: (context, state) => const TutorialPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: ProfileSetupPage.routeName,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      // Main app shell: 6 tabs, each with its own navigation stack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/focus',
                builder: (context, state) => const FocusTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/characters',
                builder: (context, state) => const CharactersTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/store',
                builder: (context, state) => const StoreTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/challenges',
                builder: (context, state) => const ChallengesTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ranking',
                builder: (context, state) => const RankingTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileTab(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});