import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/services/supabase_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

class AuthRepository {
  const AuthRepository();

  bool get isAvailable => SupabaseStatus.isInitialized;

  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession =>
      isAvailable ? _client.auth.currentSession : null;

  User? get currentUser => currentSession?.user;

  Stream<AuthState> get authStateChanges {
    if (!isAvailable) {
      return const Stream.empty();
    }
    return _client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    if (!isAvailable) {
      throw const AuthException('Supabase is not configured.');
    }
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    if (!isAvailable) {
      throw const AuthException('Supabase is not configured.');
    }
    final name = displayName?.trim();
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {if (name != null && name.isNotEmpty) 'display_name': name},
    );
  }

  Future<void> signOut() {
    if (!isAvailable) {
      return Future.value();
    }
    return _client.auth.signOut(scope: SignOutScope.local);
  }
}
