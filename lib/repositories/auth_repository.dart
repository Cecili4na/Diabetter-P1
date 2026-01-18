import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import 'repository_interfaces.dart';

class AuthRepository implements IAuthRepository {
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
  
  // Update Profile (RF-03 - Complete profile editing)
  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').update({
      'nome': profile.nome,
      'tipo_diabetes': profile.tipoDiabetes,
      'termos_aceitos': profile.termosAceitos,
      'horarios_medicao': profile.horariosMedicao,
      'metas': profile.metas,
      'unidade_glicemia': profile.unidadeGlicemia,
      'unidade_a1c': profile.unidadeA1c,
      'tipo_tratamento': profile.tipoTratamento,
      'onboarding_completo': profile.onboardingCompleto,
      'data_nascimento': profile.dataNascimento?.toIso8601String().split('T').first,
      'altura': profile.altura,
      'peso': profile.peso,
      'sexo': profile.sexo,
      'avatar_url': profile.avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profile.id);
  }

  // Upload profile photo to Supabase Storage
  Future<String?> uploadProfilePhoto(String userId, Uint8List imageBytes) async {
    final path = '$userId.jpg';
    await _client.storage.from('avatars').uploadBinary(
      path,
      imageBytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    final url = _client.storage.from('avatars').getPublicUrl(path);
    // Add timestamp to invalidate cache
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
