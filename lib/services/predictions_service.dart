// lib/services/predictions_service.dart
// RF-09: Simple predictions (beta, with disclaimer)

import 'dart:math';
import '../repositories/repository_interfaces.dart';
import '../repositories/health_repository.dart';
import '../models/models.dart';

/// Simple prediction service using moving averages (RF-09)
/// 
/// DISCLAIMER: These predictions are for informational purposes only 
/// and should NOT be used for medical decisions. Always consult your 
/// healthcare provider.
class PredictionsService {
  final IHealthRepository _healthRepo;
  
  PredictionsService({IHealthRepository? healthRepo})
      : _healthRepo = healthRepo ?? HealthRepository();

  static const String disclaimer = 
      'Estas previsões são apenas informativas e não devem ser usadas para '
      'decisões médicas. Sempre consulte seu profissional de saúde.';

  /// Predict next glucose value using weighted moving average
  Future<GlucosePrediction?> predictNextGlucose({int lookbackHours = 24}) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(hours: lookbackHours));
    
    final records = await _healthRepo.getGlucoseRecords(from: from, to: now);
    
    if (records.length < 3) {
      return null; // Not enough data
    }

    // Sort by time ascending
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Simple weighted moving average (recent values count more)
    double weightedSum = 0;
    double weightSum = 0;
    
    for (int i = 0; i < records.length; i++) {
      final weight = (i + 1).toDouble(); // Linear weight
      weightedSum += records[i].quantity * weight;
      weightSum += weight;
    }
    
    final predictedValue = weightedSum / weightSum;
    final trend = _calculateTrend(records);
    final confidence = _calculateConfidence(records);
    
    return GlucosePrediction(
      predictedValue: predictedValue,
      trend: trend,
      confidence: confidence,
      basedOnRecords: records.length,
      disclaimer: disclaimer,
    );
  }

  /// Calculate trend direction based on last N readings
  TrendDirection _calculateTrend(List<GlucoseRecord> records) {
    if (records.length < 2) return TrendDirection.stable;
    
    // Compare last 3 readings (or less if not available)
    final recent = records.reversed.take(3).toList();
    
    if (recent.length < 2) return TrendDirection.stable;
    
    final first = recent.last.quantity;
    final last = recent.first.quantity;
    final diff = last - first;
    final percentChange = (diff / first) * 100;
    
    if (percentChange > 10) return TrendDirection.rising;
    if (percentChange < -10) return TrendDirection.falling;
    if (percentChange > 5) return TrendDirection.risingSlowly;
    if (percentChange < -5) return TrendDirection.fallingSlowly;
    return TrendDirection.stable;
  }

  /// Calculate prediction confidence based on data consistency
  double _calculateConfidence(List<GlucoseRecord> records) {
    if (records.length < 3) return 0.3;
    
    // Calculate standard deviation
    final values = records.map((r) => r.quantity).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);
    
    // Lower variance = higher confidence
    // Normalized confidence: 1.0 for stdDev=0, ~0.5 for stdDev=50
    final confidence = 1.0 / (1 + (stdDev / 50));
    
    // Also factor in data freshness
    final lastRecord = records.last;
    final minutesSinceLastReading = DateTime.now().difference(lastRecord.timestamp).inMinutes;
    final freshnessFactor = 1.0 - (minutesSinceLastReading / 180).clamp(0, 0.5);
    
    return (confidence * freshnessFactor).clamp(0.1, 0.9);
  }

  /// Get trend arrow for UI display
  Future<String> getTrendArrow() async {
    final prediction = await predictNextGlucose();
    if (prediction == null) return '→';
    return prediction.trend.arrow;
  }

  /// Get a simple text summary of current trend
  Future<String> getTrendSummary() async {
    final prediction = await predictNextGlucose();
    if (prediction == null) {
      return 'Dados insuficientes para previsão';
    }
    
    final trendText = prediction.trend.description;
    final valueText = prediction.predictedValue.toStringAsFixed(0);
    
    return 'Tendência: $trendText (próximo: ~$valueText mg/dL)';
  }
}

enum TrendDirection {
  rising,
  risingSlowly,
  stable,
  fallingSlowly,
  falling;

  String get arrow {
    switch (this) {
      case TrendDirection.rising: return '↑↑';
      case TrendDirection.risingSlowly: return '↗';
      case TrendDirection.stable: return '→';
      case TrendDirection.fallingSlowly: return '↘';
      case TrendDirection.falling: return '↓↓';
    }
  }

  String get description {
    switch (this) {
      case TrendDirection.rising: return 'subindo rapidamente';
      case TrendDirection.risingSlowly: return 'subindo lentamente';
      case TrendDirection.stable: return 'estável';
      case TrendDirection.fallingSlowly: return 'descendo lentamente';
      case TrendDirection.falling: return 'descendo rapidamente';
    }
  }
}

class GlucosePrediction {
  final double predictedValue;
  final TrendDirection trend;
  final double confidence; // 0.0 to 1.0
  final int basedOnRecords;
  final String disclaimer;

  GlucosePrediction({
    required this.predictedValue,
    required this.trend,
    required this.confidence,
    required this.basedOnRecords,
    required this.disclaimer,
  });

  String get confidenceLabel {
    if (confidence > 0.7) return 'Alta';
    if (confidence > 0.4) return 'Média';
    return 'Baixa';
  }
}
