// lib/config/app_config.dart
// Configuration for switching between production and mock modes

import '../repositories/repository_interfaces.dart';
import '../repositories/auth_repository.dart';
import '../repositories/health_repository.dart';
import '../repositories/plano_repository.dart';
import '../repositories/mocks/mock_auth_repository.dart';
import '../repositories/mocks/mock_health_repository.dart';
import '../repositories/mocks/mock_plano_repository.dart';

/// Application running mode
enum AppMode {
  /// Production mode - uses Supabase
  production,
  /// Mock mode - uses in-memory mock repositories with sample data
  mock,
}

/// Centralized app configuration for dependency injection
class AppConfig {
  // Private constructor - singleton pattern
  AppConfig._();
  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  /// Current app mode - can be set at startup
  static AppMode mode = AppMode.production;

  /// Check if running in mock mode
  static bool get isMockMode => mode == AppMode.mock;

  // Cached repository instances (singleton within the app session)
  IAuthRepository? _authRepository;
  IHealthRepository? _healthRepository;
  IPlanoRepository? _planoRepository;

  /// Get the auth repository based on current mode
  IAuthRepository get authRepository {
    _authRepository ??= isMockMode 
        ? MockAuthRepository() 
        : AuthRepository();
    return _authRepository!;
  }

  /// Get the health repository based on current mode
  IHealthRepository get healthRepository {
    _healthRepository ??= isMockMode 
        ? MockHealthRepository() 
        : HealthRepository();
    return _healthRepository!;
  }

  /// Get the plano repository based on current mode
  IPlanoRepository get planoRepository {
    _planoRepository ??= isMockMode 
        ? MockPlanoRepository() 
        : PlanoRepository();
    return _planoRepository!;
  }

  /// Reset cached repositories (useful for tests or mode changes)
  void resetRepositories() {
    _authRepository = null;
    _healthRepository = null;
    _planoRepository = null;
  }

  /// Initialize with a specific mode
  static void initialize({AppMode appMode = AppMode.production}) {
    mode = appMode;
    _instance.resetRepositories();
  }

  /// Initialize from environment/compile-time flags
  static void initializeFromEnvironment() {
    const mockModeEnv = String.fromEnvironment('MOCK_MODE', defaultValue: 'false');
    mode = mockModeEnv.toLowerCase() == 'true' ? AppMode.mock : AppMode.production;
    _instance.resetRepositories();
  }
}
