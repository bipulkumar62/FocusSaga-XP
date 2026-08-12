import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth.
/// All auth calls from UI go through here — never call `Supabase.instance`
/// directly in widgets.
class AuthRepository {
  AuthRepository(SupabaseClient client) : _auth = client.auth;

  final GoTrueClient _auth;

  /// Fires on every auth state change: initial restore, sign-in, sign-out.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  /// Ensures a session exists, creating an anonymous guest session when the
  /// user has never signed in. Waits for the initial session restore first
  /// so an existing session is never replaced by a new guest one.
  Future<void> ensureGuestSession() async {
    if (_auth.currentUser != null) return;
    final initial = await _auth.onAuthStateChange.first;
    if (initial.session != null) return;
    await _auth.signInAnonymously();
  }

  Future<void> signOut() => _auth.signOut();
}
