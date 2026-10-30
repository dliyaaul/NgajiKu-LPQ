import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile/profile_model.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  Session? get currentSession {
    return _supabase.auth.currentSession;
  }

  Future<ProfileModel?> getUserProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ProfileModel.fromMap(response);
  }
}
