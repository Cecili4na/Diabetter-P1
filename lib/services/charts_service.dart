// lib/services/charts_service.dart
// RF-08: Charts and graphs, RF-12: Averages

import '../repositories/repository_interfaces.dart';
import '../repositories/health_repository.dart';
import '../models/event_record.dart';

/// Service for generating chart data (RF-08)
class ChartsService {
  final IHealthRepository _healthRepo;

  ChartsService({IHealthRepository? healthRepo})
      : _healthRepo = healthRepo ?? HealthRepository();

  /// Get glucose data points for line chart
  Future<List<ChartDataPoint>> getGlucoseChartData({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await _healthRepo.getGlucoseRecords(from: from, to: to);
    
    return records.map((r) => ChartDataPoint(
      timestamp: r.timestamp,
      value: r.quantity,
      label: r.notas,
    )).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get insulin data points for overlay on glucose chart
  Future<List<ChartDataPoint>> getInsulinChartData({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await _healthRepo.getInsulinRecords(from: from, to: to);
    
    return records.map((r) => ChartDataPoint(
      timestamp: r.timestamp,
      value: r.quantity,
      label: r.type,
    )).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get events for chart markers
  Future<List<ChartMarker>> getEventMarkers({
    required DateTime from,
    required DateTime to,
  }) async {
    final events = await _healthRepo.getEventRecords(from: from, to: to);
    
    return events.map((e) => ChartMarker(
      timestamp: e.horario,
      type: e.tipoEvento,
      label: e.titulo,
    )).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get daily aggregated data for bar/summary chart
  Future<List<DailyStats>> getDailyStats({
    required DateTime from,
    required DateTime to,
  }) async {
    final glucoseByDay = await _healthRepo.getDailyGlucoseAverages(
      from: from,
      to: to,
    );
    final insulinRecords = await _healthRepo.getInsulinRecords(
      from: from,
      to: to,
    );

    // Group insulin by day
    final insulinByDay = <DateTime, double>{};
    for (final record in insulinRecords) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      insulinByDay[date] = (insulinByDay[date] ?? 0) + record.quantity;
    }

    // Combine into daily stats
    final allDates = {...glucoseByDay.keys, ...insulinByDay.keys}.toList()
      ..sort();

    return allDates.map((date) => DailyStats(
      date: date,
      glucoseAverage: glucoseByDay[date],
      insulinTotal: insulinByDay[date],
    )).toList();
  }

  /// Get period summary (RF-12 - Médias)
  Future<PeriodSummary> getPeriodSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final stats = await _healthRepo.getStatistics(from: from, to: to);
    
    return PeriodSummary(
      from: from,
      to: to,
      glucoseAverage: stats['glucose']['average']?.toDouble(),
      glucoseMin: stats['glucose']['min']?.toDouble(),
      glucoseMax: stats['glucose']['max']?.toDouble(),
      glucoseCount: stats['glucose']['count'],
      insulinTotalUnits: stats['insulin']['totalUnits']?.toDouble(),
      insulinCount: stats['insulin']['count'],
      eventsCount: stats['events']['count'],
    );
  }

  /// Get time-in-range statistics
  Future<TimeInRange> getTimeInRange({
    required DateTime from,
    required DateTime to,
    double lowThreshold = 70,
    double highThreshold = 180,
  }) async {
    final records = await _healthRepo.getGlucoseRecords(from: from, to: to);
    
    if (records.isEmpty) {
      return TimeInRange(inRange: 0, below: 0, above: 0, total: 0);
    }

    int inRange = 0, below = 0, above = 0;
    for (final r in records) {
      if (r.quantity < lowThreshold) {
        below++;
      } else if (r.quantity > highThreshold) {
        above++;
      } else {
        inRange++;
      }
    }

    return TimeInRange(
      inRange: inRange,
      below: below,
      above: above,
      total: records.length,
    );
  }
}

// Data classes for chart representation
class ChartDataPoint {
  final DateTime timestamp;
  final double value;
  final String? label;

  ChartDataPoint({
    required this.timestamp,
    required this.value,
    this.label,
  });
}

class ChartMarker {
  final DateTime timestamp;
  final EventType type;
  final String label;

  ChartMarker({
    required this.timestamp,
    required this.type,
    required this.label,
  });
}

class DailyStats {
  final DateTime date;
  final double? glucoseAverage;
  final double? insulinTotal;

  DailyStats({
    required this.date,
    this.glucoseAverage,
    this.insulinTotal,
  });
}

class PeriodSummary {
  final DateTime from;
  final DateTime to;
  final double? glucoseAverage;
  final double? glucoseMin;
  final double? glucoseMax;
  final int glucoseCount;
  final double? insulinTotalUnits;
  final int insulinCount;
  final int eventsCount;

  PeriodSummary({
    required this.from,
    required this.to,
    this.glucoseAverage,
    this.glucoseMin,
    this.glucoseMax,
    required this.glucoseCount,
    this.insulinTotalUnits,
    required this.insulinCount,
    required this.eventsCount,
  });
}

class TimeInRange {
  final int inRange;
  final int below;
  final int above;
  final int total;

  TimeInRange({
    required this.inRange,
    required this.below,
    required this.above,
    required this.total,
  });

  double get inRangePercent => total > 0 ? (inRange / total) * 100 : 0;
  double get belowPercent => total > 0 ? (below / total) * 100 : 0;
  double get abovePercent => total > 0 ? (above / total) * 100 : 0;
}
