import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  /// Get the current user (works for both authenticated and anonymous users)
  static User? get currentUser => _supabase.auth.currentUser;

  /// Get the current user ID (works for both authenticated and anonymous users)
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Check if there's an active session
  static bool get hasSession => _supabase.auth.currentSession != null;

  /// Check if the current user is anonymous
  static bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// Sign in anonymously - creates a new anonymous session
  static Future<AuthResponse> signInAnonymously() async {
    return await _supabase.auth.signInAnonymously();
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
}
