// test/services/charts_service_test.dart
// Unit tests for ChartsService using mock repository

import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_app/services/charts_service.dart';
import 'package:diabetes_app/repositories/mocks/mock_health_repository.dart';

void main() {
  late MockHealthRepository mockRepo;
  late ChartsService chartsService;

  setUp(() {
    mockRepo = MockHealthRepository();
    chartsService = ChartsService(healthRepo: mockRepo);
  });

  group('ChartsService', () {
    group('getGlucoseChartData', () {
      test('returns sorted data points', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        final data = await chartsService.getGlucoseChartData(
          from: from,
          to: now,
        );
        
        expect(data, isNotEmpty);
        
        // Verify sorting (ascending by timestamp)
        for (int i = 1; i < data.length; i++) {
          expect(
            data[i].timestamp.isAfter(data[i - 1].timestamp) ||
            data[i].timestamp.isAtSameMomentAs(data[i - 1].timestamp),
            isTrue,
            reason: 'Data points should be sorted by timestamp ascending',
          );
        }
      });

      test('returns data within date range', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 3));
        
        final data = await chartsService.getGlucoseChartData(
          from: from,
          to: now,
        );
        
        for (final point in data) {
          expect(point.timestamp.isAfter(from) || point.timestamp.isAtSameMomentAs(from), isTrue);
          expect(point.timestamp.isBefore(now) || point.timestamp.isAtSameMomentAs(now), isTrue);
        }
      });
    });

    group('getInsulinChartData', () {
      test('returns insulin data points', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        final data = await chartsService.getInsulinChartData(
          from: from,
          to: now,
        );
        
        expect(data, isNotEmpty);
        
        // All values should be positive (insulin units)
        for (final point in data) {
          expect(point.value, greaterThan(0));
        }
      });
    });

    group('getDailyStats', () {
      test('returns daily aggregated statistics', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        final stats = await chartsService.getDailyStats(
          from: from,
          to: now,
        );
        
        expect(stats, isNotEmpty);
        
        // Each stat should have a valid date
        for (final stat in stats) {
          expect(stat.date, isNotNull);
        }
      });
    });

    group('getPeriodSummary', () {
      test('returns period summary with statistics', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 30));
        
        final summary = await chartsService.getPeriodSummary(
          from: from,
          to: now,
        );
        
        expect(summary.from, equals(from));
        expect(summary.to, equals(now));
        expect(summary.glucoseCount, greaterThan(0));
        expect(summary.insulinCount, greaterThan(0));
        
        // Glucose stats should be within realistic ranges
        if (summary.glucoseAverage != null) {
          expect(summary.glucoseAverage, greaterThan(50));
          expect(summary.glucoseAverage, lessThan(300));
        }
      });
    });

    group('getTimeInRange', () {
      test('returns time-in-range statistics', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        final tir = await chartsService.getTimeInRange(
          from: from,
          to: now,
        );
        
        expect(tir.total, greaterThan(0));
        expect(tir.inRange + tir.below + tir.above, equals(tir.total));
        
        // Percentages should sum to 100
        final totalPercent = tir.inRangePercent + tir.belowPercent + tir.abovePercent;
        expect(totalPercent, closeTo(100, 0.01));
      });

      test('respects custom thresholds', () async {
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 7));
        
        // Very tight range - should have fewer in-range
        final tightRange = await chartsService.getTimeInRange(
          from: from,
          to: now,
          lowThreshold: 90,
          highThreshold: 110,
        );
        
        // Very loose range - should have more in-range
        final looseRange = await chartsService.getTimeInRange(
          from: from,
          to: now,
          lowThreshold: 50,
          highThreshold: 250,
        );
        
        expect(looseRange.inRangePercent, greaterThanOrEqualTo(tightRange.inRangePercent));
      });
    });
  });
}
