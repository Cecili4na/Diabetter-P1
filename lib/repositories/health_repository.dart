import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class HealthRepository {
  final SupabaseClient _client = SupabaseService().client;

  String? get _userId => _client.auth.currentUser?.id;

  // --- Insulin ---

  Future<void> addInsulinRecord(InsulinRecord record) async {
    if (_userId == null) throw Exception('User not logged in');
    
    // Ensure the record has the current user ID
    final data = record.toJson();
    data['user_id'] = _userId; // Override security

    await _client.from('insulina').insert(data);
  }

  Future<List<InsulinRecord>> getInsulinRecords() async {
    if (_userId == null) return [];

    final List<dynamic> data = await _client
        .from('insulina')
        .select()
        .eq('user_id', _userId!)
        .order('horario', ascending: false);

    return data.map((json) => InsulinRecord.fromJson(json)).toList();
  }

  // --- Glucose ---

  Future<void> addGlucoseRecord(GlucoseRecord record) async {
        if (_userId == null) throw Exception('User not logged in');
        
        final data = record.toJson();
        data['user_id'] = _userId;

        await _client.from('glicemia').insert(data);
  }

  Future<List<GlucoseRecord>> getGlucoseRecords() async {
    if (_userId == null) return [];

    final List<dynamic> data = await _client
        .from('glicemia')
        .select()
        .eq('user_id', _userId!)
        .order('horario', ascending: false);

    return data.map((json) => GlucoseRecord.fromJson(json)).toList();
  }
}
