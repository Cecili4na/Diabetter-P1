// lib/repositories/mocks/mock_auth_repository.dart
// Mock implementation for testing without Supabase

import 'dart:async';
import '../repository_interfaces.dart';
import '../../models/models.dart';

/// Mock authentication response mimicking Supabase AuthResponse
class MockAuthResponse {
  final MockUser? user;
  final MockSession? session;

  MockAuthResponse({this.user, this.session});
}

class MockUser {
  final String id;
  final String email;

  MockUser({required this.id, required this.email});
}

class MockSession {
  final String accessToken;

  MockSession({required this.accessToken});
}

/// Mock implementation of IAuthRepository for testing
class MockAuthRepository implements IAuthRepository {
  UserProfile? _currentUser;
  bool _isLoggedIn = false;

  // Test credentials
  static const _testEmail = 'teste@diabetter.com';
  static const _testPassword = 'senha123';
  static const _testUserId = 'mock-user-id-12345';

  // Create a default test user profile
  UserProfile get _testProfile => UserProfile(
        id: _testUserId,
        nome: 'Usuário de Teste',
        email: _testEmail,
        tipoDiabetes: 'Tipo 1',
        termosAceitos: true,
        horariosMedicao: ['07:00', '12:00', '19:00', '22:00'],
        metas: {'min': 70, 'max': 180, 'alvo': 100},
        unidadeGlicemia: 'mg/dL',
      );

  @override
  Future<MockAuthResponse> signIn(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (email == _testEmail && password == _testPassword) {
      _isLoggedIn = true;
      _currentUser = _testProfile;
      return MockAuthResponse(
        user: MockUser(id: _testUserId, email: email),
        session: MockSession(accessToken: 'mock-token-xyz'),
      );
    }

    throw Exception('Credenciais inválidas');
  }

  @override
  Future<MockAuthResponse> signUp({
    required String email,
    required String password,
    required String nome,
    required bool termosAceitos,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newUserId = 'mock-user-${DateTime.now().millisecondsSinceEpoch}';
    _currentUser = UserProfile(
      id: newUserId,
      nome: nome,
      email: email,
      termosAceitos: termosAceitos,
    );
    _isLoggedIn = true;

    return MockAuthResponse(
      user: MockUser(id: newUserId, email: email),
      session: MockSession(accessToken: 'mock-token-new'),
    );
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoggedIn = false;
    _currentUser = null;
  }

  @override
  Future<UserProfile?> getCurrentProfile() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!_isLoggedIn) return null;
    return _currentUser ?? _testProfile;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!_isLoggedIn) throw Exception('Usuário não autenticado');
    _currentUser = profile;
  }

  // Helper methods for tests
  bool get isLoggedIn => _isLoggedIn;
  
  void setLoggedIn(bool value, {UserProfile? profile}) {
    _isLoggedIn = value;
    _currentUser = value ? (profile ?? _testProfile) : null;
  }
}
