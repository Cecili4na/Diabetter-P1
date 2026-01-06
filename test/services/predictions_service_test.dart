// test/services/predictions_service_test.dart
// Unit tests for PredictionsService using mock repository

import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_app/services/predictions_service.dart';
import 'package:diabetes_app/repositories/mocks/mock_health_repository.dart';

void main() {
  late MockHealthRepository mockRepo;
  late PredictionsService predictionsService;

  setUp(() {
    mockRepo = MockHealthRepository();
    predictionsService = PredictionsService(healthRepo: mockRepo);
  });

  group('PredictionsService', () {
    group('predictNextGlucose', () {
      test('returns prediction with sufficient data', () async {
        final prediction = await predictionsService.predictNextGlucose(
          lookbackHours: 48,
        );
        
        expect(prediction, isNotNull);
        expect(prediction!.predictedValue, greaterThan(0));
        expect(prediction.predictedValue, lessThan(400)); // Realistic max
        expect(prediction.basedOnRecords, greaterThan(2));
        expect(prediction.disclaimer, isNotEmpty);
      });

      test('prediction has valid confidence', () async {
        final prediction = await predictionsService.predictNextGlucose();
        
        expect(prediction, isNotNull);
        expect(prediction!.confidence, greaterThanOrEqualTo(0.0));
        expect(prediction.confidence, lessThanOrEqualTo(1.0));
      });

      test('prediction has valid trend direction', () async {
        final prediction = await predictionsService.predictNextGlucose();
        
        expect(prediction, isNotNull);
        expect(prediction!.trend, isNotNull);
        // Verify it's a valid TrendDirection value
        expect(prediction.trend.arrow, isNotEmpty);
      });

      test('confidence label is appropriate', () async {
        final prediction = await predictionsService.predictNextGlucose();
        
        expect(prediction, isNotNull);
        expect(
          ['Alta', 'Média', 'Baixa'],
          contains(prediction!.confidenceLabel),
        );
      });
    });

    group('getTrendArrow', () {
      test('returns valid arrow emoji', () async {
        final arrow = await predictionsService.getTrendArrow();
        
        expect(arrow, isNotEmpty);
        expect(
          ['↑↑', '↗', '→', '↘', '↓↓'],
          contains(arrow),
        );
      });
    });

    group('getTrendSummary', () {
      test('returns readable summary text', () async {
        final summary = await predictionsService.getTrendSummary();
        
        expect(summary, isNotEmpty);
        // Should contain either "Tendência" or "Dados insuficientes"
        final containsTendencia = summary.contains('Tendência');
        final containsInsuficiente = summary.contains('Dados insuficientes');
        expect(containsTendencia || containsInsuficiente, isTrue);
      });
    });
  });
}
