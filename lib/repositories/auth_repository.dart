import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService().client;

  // Login
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Register
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nome,
    required bool termosAceitos,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nome': nome,
        'termos_aceitos': termosAceitos,
      }, // Pass metadata to trigger query
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get Current User Profile
  Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return UserProfile.fromJson(data);
  }
  
  // Update Profile
  Future<void> updateProfile(UserProfile profile) async {
      await _client.from('profiles').update({
          'tipo_diabetes': profile.tipoDiabetes,
          'termos_aceitos': profile.termosAceitos,
          // 'nome': profile.nome, // if editable
      }).eq('id', profile.id);
  }
}
