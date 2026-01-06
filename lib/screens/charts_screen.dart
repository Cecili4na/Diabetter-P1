// lib/screens/charts_screen.dart
// Charts and statistics screen (RF-08, RF-12)

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../services/charts_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late final ChartsService _chartsService;
  
  int _selectedDays = 7;
  bool _isLoading = true;
  PeriodSummary? _summary;
  TimeInRange? _timeInRange;
  List<DailyStats> _dailyStats = [];

  @override
  void initState() {
    super.initState();
    _chartsService = ChartsService(healthRepo: AppConfig.instance.healthRepository);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final from = now.subtract(Duration(days: _selectedDays));

      final results = await Future.wait([
        _chartsService.getPeriodSummary(from: from, to: now),
        _chartsService.getTimeInRange(from: from, to: now),
        _chartsService.getDailyStats(from: from, to: now),
      ]);

      setState(() {
        _summary = results[0] as PeriodSummary;
        _timeInRange = results[1] as TimeInRange;
        _dailyStats = results[2] as List<DailyStats>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Gráficos e Estatísticas'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildTimeInRangeCard(),
                    const SizedBox(height: 16),
                    _buildDailyChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [7, 14, 30].map((days) {
          final isSelected = _selectedDays == days;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDays = days);
                _loadData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$days dias',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumo do Período', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  'Média',
                  '${_summary?.glucoseAverage?.toStringAsFixed(0) ?? '--'}',
                  'mg/dL',
                  AppColors.primaryBlue,
                ),
              ),
              Expanded(
                child: _buildStat(
                  'Mínimo',
                  '${_summary?.glucoseMin?.toStringAsFixed(0) ?? '--'}',
                  'mg/dL',
                  AppColors.green,
                ),
              ),
              Expanded(
                child: _buildStat(
                  'Máximo',
                  '${_summary?.glucoseMax?.toStringAsFixed(0) ?? '--'}',
                  'mg/dL',
                  AppColors.red,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  'Medições',
                  '${_summary?.glucoseCount ?? 0}',
                  'registros',
                  AppColors.darkGrey,
                ),
              ),
              Expanded(
                child: _buildStat(
                  'Insulina',
                  '${_summary?.insulinTotalUnits?.toStringAsFixed(0) ?? '0'}',
                  'unidades',
                  AppColors.green,
                ),
              ),
              Expanded(
                child: _buildStat(
                  'Eventos',
                  '${_summary?.eventsCount ?? 0}',
                  'registrados',
                  AppColors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(color: color),
        ),
        Text(unit, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildTimeInRangeCard() {
    if (_timeInRange == null || _timeInRange!.total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.cardInfo,
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sem dados suficientes para calcular o tempo no alvo',
                style: AppTextStyles.body.copyWith(color: AppColors.darkBlue),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tempo no Alvo', style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text('(70-180 mg/dL)', style: AppTextStyles.bodySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildRangeBar('Baixo', _timeInRange!.belowPercent, AppColors.red),
                _buildRangeBar('No Alvo', _timeInRange!.inRangePercent, AppColors.green),
                _buildRangeBar('Alto', _timeInRange!.abovePercent, AppColors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeBar(String label, double percent, Color color) {
    // Calculate bar height relative to the available space
    final barHeight = (percent / 100 * 60).clamp(5.0, 60.0);
    
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          Container(
            width: 50,
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDailyChart() {
    if (_dailyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _dailyStats.reversed.take(7).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Médias Diárias', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _LineChartPainter(
                data: stats.map((s) => s.glucoseAverage ?? 0).toList(),
                labels: stats.map((s) => '${s.date.day}/${s.date.month}').toList(),
                lineColor: AppColors.primaryBlue,
                pointColor: AppColors.primaryBlue,
                gridColor: AppColors.lightGrey,
                textColor: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the line chart
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color pointColor;
  final Color gridColor;
  final Color textColor;

  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.pointColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double paddingLeft = 35;
    const double paddingBottom = 25;
    const double paddingTop = 20;
    const double paddingRight = 10;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingBottom - paddingTop;

    // Calculate min/max for scaling
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).clamp(20, double.infinity);
    final adjustedMin = minValue - range * 0.1;
    final adjustedMax = maxValue + range * 0.1;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Horizontal grid lines (3 lines)
    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + (chartHeight / 2) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Y-axis labels
      final value = adjustedMax - ((adjustedMax - adjustedMin) / 2) * i;
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(0),
        style: TextStyle(color: textColor, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - 6));
    }

    // Draw target zone (70-180)
    final targetPaint = Paint()
      ..color = AppColors.green.withAlpha(30)
      ..style = PaintingStyle.fill;

    final y70 = paddingTop + chartHeight * (1 - (70 - adjustedMin) / (adjustedMax - adjustedMin));
    final y180 = paddingTop + chartHeight * (1 - (180 - adjustedMin) / (adjustedMax - adjustedMin));
    
    if (y70 > paddingTop && y180 < size.height - paddingBottom) {
      canvas.drawRect(
        Rect.fromLTRB(paddingLeft, y180.clamp(paddingTop, size.height - paddingBottom), 
                      size.width - paddingRight, y70.clamp(paddingTop, size.height - paddingBottom)),
        targetPaint,
      );
    }

    // Calculate points
    final points = <Offset>[];
    final stepX = chartWidth / (data.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + stepX * i;
      final normalizedY = (data[i] - adjustedMin) / (adjustedMax - adjustedMin);
      final y = paddingTop + chartHeight * (1 - normalizedY);
      points.add(Offset(x, y.clamp(paddingTop, size.height - paddingBottom)));
    }

    // Draw area under line
    if (points.length > 1) {
      final areaPath = Path();
      areaPath.moveTo(points.first.dx, size.height - paddingBottom);
      for (final point in points) {
        areaPath.lineTo(point.dx, point.dy);
      }
      areaPath.lineTo(points.last.dx, size.height - paddingBottom);
      areaPath.close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withAlpha(60), lineColor.withAlpha(10)],
        ).createShader(Rect.fromLTWH(0, paddingTop, size.width, chartHeight));

      canvas.drawPath(areaPath, areaPaint);
    }

    // Draw line
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw points and labels
    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final pointOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      // Point
      canvas.drawCircle(points[i], 6, pointOutlinePaint);
      canvas.drawCircle(points[i], 4, pointPaint);

      // X-axis label
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: textColor, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, size.height - paddingBottom + 8),
      );

      // Value label above point
      textPainter.text = TextSpan(
        text: data[i].toStringAsFixed(0),
        style: TextStyle(color: lineColor, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
