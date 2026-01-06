// lib/repositories/mocks/mock_health_repository.dart
// Mock implementation with 30 days of realistic sample data

import 'dart:math';
import '../repository_interfaces.dart';
import '../../models/models.dart';
import '../../models/event_record.dart';

/// Mock implementation of IHealthRepository for testing
class MockHealthRepository implements IHealthRepository {
  static const _mockUserId = 'mock-user-id-12345';
  final Random _random = Random(42); // Fixed seed for reproducible data

  // In-memory storage
  final List<GlucoseRecord> _glucoseRecords = [];
  final List<InsulinRecord> _insulinRecords = [];
  final List<EventRecord> _eventRecords = [];

  MockHealthRepository() {
    _generateSampleData();
  }

  /// Generate 30 days of realistic sample data
  void _generateSampleData() {
    final now = DateTime.now();
    
    for (int day = 0; day < 30; day++) {
      final date = now.subtract(Duration(days: day));
      
      // Generate 4-6 glucose readings per day
      _generateDailyGlucose(date);
      
      // Generate 2-4 insulin doses per day
      _generateDailyInsulin(date);
      
      // Generate 0-2 events per day
      _generateDailyEvents(date);
    }
  }

  void _generateDailyGlucose(DateTime date) {
    final readingsCount = 4 + _random.nextInt(3); // 4-6 readings
    final hours = [7, 10, 12, 15, 19, 22];
    
    for (int i = 0; i < readingsCount && i < hours.length; i++) {
      final timestamp = DateTime(date.year, date.month, date.day, hours[i], _random.nextInt(30));
      
      // Realistic glucose values: base 100, variance ±60
      double value = 100 + (_random.nextDouble() * 120 - 60);
      value = value.clamp(55, 280); // Realistic range
      
      _glucoseRecords.add(GlucoseRecord(
        id: 'glucose-${_glucoseRecords.length}',
        userId: _mockUserId,
        quantity: double.parse(value.toStringAsFixed(1)),
        timestamp: timestamp,
        notas: _random.nextBool() ? _randomNote() : null,
      ));
    }
  }

  void _generateDailyInsulin(DateTime date) {
    // Morning basal
    _insulinRecords.add(InsulinRecord(
      id: 'insulin-${_insulinRecords.length}',
      userId: _mockUserId,
      quantity: 10 + _random.nextInt(5).toDouble(), // 10-14 units
      timestamp: DateTime(date.year, date.month, date.day, 7, 30),
      type: 'Basal',
      bodyPart: 'Abdômen',
    ));

    // Bolus doses with meals
    final mealHours = [8, 12, 19];
    for (final hour in mealHours) {
      if (_random.nextDouble() > 0.2) { // 80% chance of having this meal dose
        _insulinRecords.add(InsulinRecord(
          id: 'insulin-${_insulinRecords.length}',
          userId: _mockUserId,
          quantity: 3 + _random.nextInt(6).toDouble(), // 3-8 units
          timestamp: DateTime(date.year, date.month, date.day, hour, _random.nextInt(20)),
          type: 'Bolus',
          bodyPart: _randomBodyPart(),
        ));
      }
    }
  }

  void _generateDailyEvents(DateTime date) {
    final eventCount = _random.nextInt(3); // 0-2 events per day
    
    for (int i = 0; i < eventCount; i++) {
      final type = EventType.values[_random.nextInt(EventType.values.length)];
      final hour = 6 + _random.nextInt(16); // Between 6am and 10pm
      
      _eventRecords.add(EventRecord(
        id: 'event-${_eventRecords.length}',
        userId: _mockUserId,
        tipoEvento: type,
        titulo: _eventTitle(type),
        descricao: _random.nextBool() ? 'Descrição do evento' : null,
        horario: DateTime(date.year, date.month, date.day, hour, _random.nextInt(60)),
      ));
    }
  }

  String _randomNote() {
    final notes = [
      'Antes do café',
      'Após exercício',
      'Antes de dormir',
      'Hipoglicemia leve',
      'Após refeição pesada',
      'Em jejum',
    ];
    return notes[_random.nextInt(notes.length)];
  }

  String _randomBodyPart() {
    final parts = ['Abdômen', 'Braço esquerdo', 'Braço direito', 'Coxa'];
    return parts[_random.nextInt(parts.length)];
  }

  String _eventTitle(EventType type) {
    switch (type) {
      case EventType.refeicao:
        final meals = ['Café da manhã', 'Almoço', 'Jantar', 'Lanche'];
        return meals[_random.nextInt(meals.length)];
      case EventType.exercicio:
        final exercises = ['Caminhada', 'Corrida', 'Musculação', 'Natação'];
        return exercises[_random.nextInt(exercises.length)];
      case EventType.estresse:
        return 'Situação de estresse';
      case EventType.medicamento:
        return 'Medicamento tomado';
      case EventType.outro:
        return 'Outro evento';
    }
  }

  // =====================================================
  // INSULIN (RF-05)
  // =====================================================

  @override
  Future<void> addInsulinRecord(InsulinRecord record) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newRecord = InsulinRecord(
      id: 'insulin-${_insulinRecords.length}',
      userId: record.userId,
      quantity: record.quantity,
      timestamp: record.timestamp,
      type: record.type,
      bodyPart: record.bodyPart,
    );
    _insulinRecords.add(newRecord);
  }

  @override
  Future<List<InsulinRecord>> getInsulinRecords({
    DateTime? from,
    DateTime? to,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    var records = List<InsulinRecord>.from(_insulinRecords);
    
    if (from != null) {
      records = records.where((r) => r.timestamp.isAfter(from) || r.timestamp.isAtSameMomentAs(from)).toList();
    }
    if (to != null) {
      records = records.where((r) => r.timestamp.isBefore(to) || r.timestamp.isAtSameMomentAs(to)).toList();
    }
    
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  @override
  Future<void> updateInsulinRecord(InsulinRecord record) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _insulinRecords.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _insulinRecords[index] = record;
    }
  }

  @override
  Future<void> deleteInsulinRecord(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _insulinRecords.removeWhere((r) => r.id == id);
  }

  // =====================================================
  // GLUCOSE (RF-04)
  // =====================================================

  @override
  Future<void> addGlucoseRecord(GlucoseRecord record) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newRecord = GlucoseRecord(
      id: 'glucose-${_glucoseRecords.length}',
      userId: record.userId,
      quantity: record.quantity,
      timestamp: record.timestamp,
      notas: record.notas,
    );
    _glucoseRecords.add(newRecord);
  }

  @override
  Future<List<GlucoseRecord>> getGlucoseRecords({
    DateTime? from,
    DateTime? to,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    var records = List<GlucoseRecord>.from(_glucoseRecords);
    
    if (from != null) {
      records = records.where((r) => r.timestamp.isAfter(from) || r.timestamp.isAtSameMomentAs(from)).toList();
    }
    if (to != null) {
      records = records.where((r) => r.timestamp.isBefore(to) || r.timestamp.isAtSameMomentAs(to)).toList();
    }
    
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  @override
  Future<void> updateGlucoseRecord(GlucoseRecord record) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _glucoseRecords.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _glucoseRecords[index] = record;
    }
  }

  @override
  Future<void> deleteGlucoseRecord(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _glucoseRecords.removeWhere((r) => r.id == id);
  }

  // =====================================================
  // EVENTS (RF-06)
  // =====================================================

  @override
  Future<void> addEventRecord(EventRecord record) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newRecord = EventRecord(
      id: 'event-${_eventRecords.length}',
      userId: record.userId,
      tipoEvento: record.tipoEvento,
      titulo: record.titulo,
      descricao: record.descricao,
      horario: record.horario,
    );
    _eventRecords.add(newRecord);
  }

  @override
  Future<List<EventRecord>> getEventRecords({
    DateTime? from,
    DateTime? to,
    EventType? tipoEvento,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    var records = List<EventRecord>.from(_eventRecords);
    
    if (from != null) {
      records = records.where((r) => r.horario.isAfter(from) || r.horario.isAtSameMomentAs(from)).toList();
    }
    if (to != null) {
      records = records.where((r) => r.horario.isBefore(to) || r.horario.isAtSameMomentAs(to)).toList();
    }
    if (tipoEvento != null) {
      records = records.where((r) => r.tipoEvento == tipoEvento).toList();
    }
    
    records.sort((a, b) => b.horario.compareTo(a.horario));
    return records;
  }

  @override
  Future<void> updateEventRecord(EventRecord record) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _eventRecords.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _eventRecords[index] = record;
    }
  }

  @override
  Future<void> deleteEventRecord(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _eventRecords.removeWhere((r) => r.id == id);
  }

  // =====================================================
  // STATISTICS (RF-08, RF-12)
  // =====================================================

  @override
  Future<double?> getGlucoseAverage({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await getGlucoseRecords(from: from, to: to);
    if (records.isEmpty) return null;
    
    final sum = records.fold<double>(0, (acc, r) => acc + r.quantity);
    return sum / records.length;
  }

  @override
  Future<Map<DateTime, double>> getDailyGlucoseAverages({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await getGlucoseRecords(from: from, to: to);
    
    final Map<DateTime, List<double>> grouped = {};
    for (final record in records) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      grouped.putIfAbsent(date, () => []).add(record.quantity);
    }
    
    return grouped.map((date, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(date, avg);
    });
  }

  @override
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

  // Helper for tests
  void clearAllData() {
    _glucoseRecords.clear();
    _insulinRecords.clear();
    _eventRecords.clear();
  }

  void regenerateData() {
    clearAllData();
    _generateSampleData();
  }
}
