// test/repositories/mock_health_repository_test.dart
// Tests to verify mock repository generates valid sample data

import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_app/repositories/mocks/mock_health_repository.dart';
import 'package:diabetes_app/models/models.dart';
import 'package:diabetes_app/models/event_record.dart';

void main() {
  late MockHealthRepository mockRepo;

  setUp(() {
    mockRepo = MockHealthRepository();
  });

  group('MockHealthRepository', () {
    group('Sample Data Generation', () {
      test('generates glucose records for 30 days', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 30));
        
        final records = await mockRepo.getGlucoseRecords(from: from, to: now);
        
        // Should have multiple readings per day for 30 days
        expect(records.length, greaterThan(90)); // At least 3 per day
        expect(records.length, lessThan(200)); // At most ~6 per day
      });

      test('generates realistic glucose values', () async {
        final records = await mockRepo.getGlucoseRecords();
        
        for (final record in records) {
          expect(record.quantity, greaterThanOrEqualTo(55));
          expect(record.quantity, lessThanOrEqualTo(280));
        }
      });

      test('generates insulin records with types', () async {
        final records = await mockRepo.getInsulinRecords();
        
        expect(records, isNotEmpty);
        
        final hasBasal = records.any((r) => r.type == 'Basal');
        final hasBolus = records.any((r) => r.type == 'Bolus');
        
        expect(hasBasal, isTrue, reason: 'Should have basal insulin records');
        expect(hasBolus, isTrue, reason: 'Should have bolus insulin records');
      });

      test('generates events of different types', () async {
        final records = await mockRepo.getEventRecords();
        
        expect(records, isNotEmpty);
        
        // Should have at least some variety in event types
        final types = records.map((r) => r.tipoEvento).toSet();
        expect(types.length, greaterThan(1));
      });
    });

    group('CRUD Operations', () {
      test('can add and retrieve glucose record', () async {
        final initialCount = (await mockRepo.getGlucoseRecords()).length;
        
        final newRecord = GlucoseRecord(
          userId: 'test-user',
          quantity: 120,
          timestamp: DateTime.now(),
          notas: 'Test note',
        );
        
        await mockRepo.addGlucoseRecord(newRecord);
        
        final afterCount = (await mockRepo.getGlucoseRecords()).length;
        expect(afterCount, equals(initialCount + 1));
      });

      test('can delete glucose record', () async {
        final records = await mockRepo.getGlucoseRecords();
        final initialCount = records.length;
        final recordToDelete = records.first;
        
        await mockRepo.deleteGlucoseRecord(recordToDelete.id!);
        
        final afterCount = (await mockRepo.getGlucoseRecords()).length;
        expect(afterCount, equals(initialCount - 1));
      });

      test('can filter events by type', () async {
        final mealEvents = await mockRepo.getEventRecords(
          tipoEvento: EventType.refeicao,
        );
        
        for (final event in mealEvents) {
          expect(event.tipoEvento, equals(EventType.refeicao));
        }
      });
    });

    group('Statistics', () {
      test('calculates glucose average correctly', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        final average = await mockRepo.getGlucoseAverage(from: from, to: now);
        
        expect(average, isNotNull);
        expect(average, greaterThan(50));
        expect(average, lessThan(300));
      });

      test('returns daily averages map', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        final dailyAverages = await mockRepo.getDailyGlucoseAverages(
          from: from,
          to: now,
        );
        
        expect(dailyAverages, isNotEmpty);
        expect(dailyAverages.length, lessThanOrEqualTo(8)); // 7 days + today
      });

      test('returns complete statistics', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        final stats = await mockRepo.getStatistics(from: from, to: now);
        
        expect(stats['glucose'], isNotNull);
        expect(stats['insulin'], isNotNull);
        expect(stats['events'], isNotNull);
        
        expect(stats['glucose']['count'], greaterThan(0));
        expect(stats['insulin']['count'], greaterThan(0));
      });
    });

    group('Helper Methods', () {
      test('clearAllData removes all records', () async {
        mockRepo.clearAllData();
        
        final glucose = await mockRepo.getGlucoseRecords();
        final insulin = await mockRepo.getInsulinRecords();
        final events = await mockRepo.getEventRecords();
        
        expect(glucose, isEmpty);
        expect(insulin, isEmpty);
        expect(events, isEmpty);
      });

      test('regenerateData repopulates records', () async {
        mockRepo.clearAllData();
        mockRepo.regenerateData();
        
        final glucose = await mockRepo.getGlucoseRecords();
        expect(glucose, isNotEmpty);
      });
    });
  });
}
