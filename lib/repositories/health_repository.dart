import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../models/event_record.dart';
import 'repository_interfaces.dart';

class HealthRepository implements IHealthRepository {
  final SupabaseClient _client = SupabaseService().client;

  String? get _userId => _client.auth.currentUser?.id;

  // =====================================================
  // INSULIN (RF-05)
  // =====================================================

  Future<void> addInsulinRecord(InsulinRecord record) async {
    if (_userId == null) throw Exception('User not logged in');
    
    final data = record.toJson();
    data['user_id'] = _userId;

    await _client.from('insulina').insert(data);
  }

  Future<List<InsulinRecord>> getInsulinRecords({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_userId == null) return [];

    var query = _client
        .from('insulina')
        .select()
        .eq('user_id', _userId!);
    
    if (from != null) {
      query = query.gte('horario', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('horario', to.toIso8601String());
    }

    final List<dynamic> data = await query.order('horario', ascending: false);
    return data.map((json) => InsulinRecord.fromJson(json)).toList();
  }

  Future<void> updateInsulinRecord(InsulinRecord record) async {
    if (_userId == null || record.id == null) {
      throw Exception('Invalid operation');
    }

    await _client
        .from('insulina')
        .update(record.toJson())
        .eq('id', record.id!)
        .eq('user_id', _userId!);
  }

  Future<void> deleteInsulinRecord(String id) async {
    if (_userId == null) throw Exception('User not logged in');

    await _client
        .from('insulina')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // =====================================================
  // GLUCOSE (RF-04)
  // =====================================================

  Future<void> addGlucoseRecord(GlucoseRecord record) async {
    if (_userId == null) throw Exception('User not logged in');
    
    final data = record.toJson();
    data['user_id'] = _userId;

    await _client.from('glicemia').insert(data);
  }

  Future<List<GlucoseRecord>> getGlucoseRecords({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_userId == null) return [];

    var query = _client
        .from('glicemia')
        .select()
        .eq('user_id', _userId!);

    if (from != null) {
      query = query.gte('horario', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('horario', to.toIso8601String());
    }

    final List<dynamic> data = await query.order('horario', ascending: false);
    return data.map((json) => GlucoseRecord.fromJson(json)).toList();
  }

  Future<void> updateGlucoseRecord(GlucoseRecord record) async {
    if (_userId == null || record.id == null) {
      throw Exception('Invalid operation');
    }

    await _client
        .from('glicemia')
        .update(record.toJson())
        .eq('id', record.id!)
        .eq('user_id', _userId!);
  }

  Future<void> deleteGlucoseRecord(String id) async {
    if (_userId == null) throw Exception('User not logged in');

    await _client
        .from('glicemia')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // =====================================================
  // EVENTS (RF-06)
  // =====================================================

  Future<void> addEventRecord(EventRecord record) async {
    if (_userId == null) throw Exception('User not logged in');
    
    final data = record.toJson();
    data['user_id'] = _userId;

    await _client.from('eventos').insert(data);
  }

  Future<List<EventRecord>> getEventRecords({
    DateTime? from,
    DateTime? to,
    EventType? tipoEvento,
  }) async {
    if (_userId == null) return [];

    var query = _client
        .from('eventos')
        .select()
        .eq('user_id', _userId!);

    if (from != null) {
      query = query.gte('horario', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('horario', to.toIso8601String());
    }
    if (tipoEvento != null) {
      query = query.eq('tipo_evento', tipoEvento.name);
    }

    final List<dynamic> data = await query.order('horario', ascending: false);
    return data.map((json) => EventRecord.fromJson(json)).toList();
  }

  Future<void> updateEventRecord(EventRecord record) async {
    if (_userId == null || record.id == null) {
      throw Exception('Invalid operation');
    }

    await _client
        .from('eventos')
        .update(record.toJson())
        .eq('id', record.id!)
        .eq('user_id', _userId!);
  }

  Future<void> deleteEventRecord(String id) async {
    if (_userId == null) throw Exception('User not logged in');

    await _client
        .from('eventos')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // =====================================================
  // STATISTICS (RF-08, RF-12 - Médias)
  // =====================================================

  /// Get glucose average for a period
  Future<double?> getGlucoseAverage({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await getGlucoseRecords(from: from, to: to);
    if (records.isEmpty) return null;
    
    final sum = records.fold<double>(0, (acc, r) => acc + r.quantity);
    return sum / records.length;
  }

  /// Get daily glucose averages for chart (RF-08)
  Future<Map<DateTime, double>> getDailyGlucoseAverages({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await getGlucoseRecords(from: from, to: to);
    
    // Group by date
    final Map<DateTime, List<double>> grouped = {};
    for (final record in records) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      grouped.putIfAbsent(date, () => []).add(record.quantity);
    }
    
    // Calculate averages
    return grouped.map((date, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(date, avg);
    });
  }

  /// Get statistics summary for a period
  Future<Map<String, dynamic>> getStatistics({
    required DateTime from,
    required DateTime to,
  }) async {
    final glucoseRecords = await getGlucoseRecords(from: from, to: to);
    final insulinRecords = await getInsulinRecords(from: from, to: to);
    final eventRecords = await getEventRecords(from: from, to: to);
    
    double? glucoseAvg, glucoseMin, glucoseMax;
    if (glucoseRecords.isNotEmpty) {
      final values = glucoseRecords.map((r) => r.quantity).toList();
      glucoseAvg = values.reduce((a, b) => a + b) / values.length;
      values.sort();
      glucoseMin = values.first;
      glucoseMax = values.last;
    }

    return {
      'glucose': {
        'count': glucoseRecords.length,
        'average': glucoseAvg,
        'min': glucoseMin,
        'max': glucoseMax,
      },
      'insulin': {
        'count': insulinRecords.length,
        'totalUnits': insulinRecords.fold<double>(0, (acc, r) => acc + r.quantity),
      },
      'events': {
        'count': eventRecords.length,
        'byType': _countEventsByType(eventRecords),
      },
    };
  }

  Map<String, int> _countEventsByType(List<EventRecord> events) {
    final counts = <String, int>{};
    for (final event in events) {
      final key = event.tipoEvento.name;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}
