// lib/repositories/repository_interfaces.dart
// Abstract interfaces for all repositories - enables mocking for tests

import 'dart:typed_data';
import '../models/models.dart';
import '../models/event_record.dart';
import '../models/plano.dart';

/// Abstract interface for authentication operations
abstract class IAuthRepository {
  /// Sign in with email and password
  Future<dynamic> signIn(String email, String password);

  /// Register a new user
  Future<dynamic> signUp({
    required String email,
    required String password,
    required String nome,
    required bool termosAceitos,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Get current user's profile
  Future<UserProfile?> getCurrentProfile();

  /// Update user profile (RF-03)
  Future<void> updateProfile(UserProfile profile);

  /// Upload profile photo to storage
  Future<String?> uploadProfilePhoto(String userId, Uint8List imageBytes);
}

/// Abstract interface for health data operations (RF-04, RF-05, RF-06)
abstract class IHealthRepository {
  // =====================================================
  // INSULIN (RF-05)
  // =====================================================

  Future<void> addInsulinRecord(InsulinRecord record);

  Future<List<InsulinRecord>> getInsulinRecords({
    DateTime? from,
    DateTime? to,
  });

  Future<void> updateInsulinRecord(InsulinRecord record);

  Future<void> deleteInsulinRecord(String id);

  // =====================================================
  // GLUCOSE (RF-04)
  // =====================================================

  Future<void> addGlucoseRecord(GlucoseRecord record);

  Future<List<GlucoseRecord>> getGlucoseRecords({
    DateTime? from,
    DateTime? to,
  });

  Future<void> updateGlucoseRecord(GlucoseRecord record);

  Future<void> deleteGlucoseRecord(String id);

  // =====================================================
  // EVENTS (RF-06)
  // =====================================================

  Future<void> addEventRecord(EventRecord record);

  Future<List<EventRecord>> getEventRecords({
    DateTime? from,
    DateTime? to,
    EventType? tipoEvento,
  });

  Future<void> updateEventRecord(EventRecord record);

  Future<void> deleteEventRecord(String id);

  // =====================================================
  // STATISTICS (RF-08, RF-12)
  // =====================================================

  /// Get glucose average for a period
  Future<double?> getGlucoseAverage({
    required DateTime from,
    required DateTime to,
  });

  /// Get daily glucose averages for chart (RF-08)
  Future<Map<DateTime, double>> getDailyGlucoseAverages({
    required DateTime from,
    required DateTime to,
  });

  /// Get statistics summary for a period
  Future<Map<String, dynamic>> getStatistics({
    required DateTime from,
    required DateTime to,
  });
}

/// Abstract interface for plan/freemium operations (RF-11)
abstract class IPlanoRepository {
  /// Get all available plans
  Future<List<Plano>> getPlanos();

  /// Get user's current subscription
  Future<UserPlano?> getUserPlano();

  /// Get user's plan with full details
  Future<UserPlanoComDetalhes?> getUserPlanoComDetalhes();

  /// Check if user can add a new record (respects freemium limits)
  Future<bool> canAddRecord();

  /// Check if user can export (respects freemium limits)
  Future<bool> canExport();

  /// Increment record counter after adding a record
  Future<void> incrementRecordCount();

  /// Increment export counter
  Future<void> incrementExportCount();

  /// Get remaining quota info for UI display
  Future<Map<String, int>> getRemainingQuota();

  /// Upgrade to premium (simulated for MVP)
  Future<void> upgradeToPremium();
}
