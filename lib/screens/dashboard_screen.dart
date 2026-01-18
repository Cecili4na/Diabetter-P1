// lib/screens/dashboard_screen.dart
// Dashboard/Home screen with glucose summary and quick actions

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/charts_service.dart';
import '../services/predictions_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late final ChartsService _chartsService;
  late final PredictionsService _predictionsService;

  bool _isLoading = true;
  PeriodSummary? _summary;
  TimeInRange? _timeInRange;
  GlucosePrediction? _prediction;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _chartsService = ChartsService(healthRepo: AppConfig.instance.healthRepository);
    _predictionsService = PredictionsService(healthRepo: AppConfig.instance.healthRepository);
    _loadData();
  }

  /// Public method to refresh data (called by AppShell on tab change)
  Future<void> refresh() => _loadData();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final results = await Future.wait([
        _chartsService.getPeriodSummary(from: thirtyDaysAgo, to: now),
        _chartsService.getTimeInRange(from: sevenDaysAgo, to: now),
        _predictionsService.predictNextGlucose(),
        AppConfig.instance.authRepository.getCurrentProfile(),
      ]);
      
      setState(() {
        _summary = results[0] as PeriodSummary;
        _timeInRange = results[1] as TimeInRange;
        _prediction = results[2] as GlucosePrediction?;
        final profile = results[3] as UserProfile?;
        _userName = profile?.nome ?? 'Usuário';
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPredictionCard(),
                            const SizedBox(height: 16),
                            _buildMetricsRow(),
                            const SizedBox(height: 16),
                            _buildTimeInRangeCard(),
                            const SizedBox(height: 16),
                            _buildQuickActions(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_userName ?? 'Usuário'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConfig.isMockMode ? '🧪 Modo de teste' : 'Bem-vindo de volta',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    if (_prediction == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.cardInfo,
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Registre mais medições para ver previsões',
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
          Row(
            children: [
              Text('Tendência', style: AppTextStyles.label),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Confiança: ${_prediction!.confidenceLabel}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _prediction!.trend.arrow,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '~${_prediction!.predictedValue.toStringAsFixed(0)} mg/dL',
                      style: AppTextStyles.heading2,
                    ),
                    Text(
                      _prediction!.trend.description,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Média (30d)',
            _summary?.glucoseAverage?.toStringAsFixed(0) ?? '--',
            'mg/dL',
            Icons.analytics_outlined,
            AppColors.lightBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Medições',
            '${_summary?.glucoseCount ?? 0}',
            'registros',
            Icons.edit_note,
            AppColors.lightGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.darkGrey),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.metric),
          Text(unit, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTimeInRangeCard() {
    if (_timeInRange == null || _timeInRange!.total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tempo no Alvo (7 dias)', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: _timeInRange!.below,
                  child: Container(height: 24, color: AppColors.red),
                ),
                Expanded(
                  flex: _timeInRange!.inRange,
                  child: Container(height: 24, color: AppColors.green),
                ),
                Expanded(
                  flex: _timeInRange!.above,
                  child: Container(height: 24, color: AppColors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRangeLabel('Baixo', _timeInRange!.belowPercent, AppColors.red),
              _buildRangeLabel('No alvo', _timeInRange!.inRangePercent, AppColors.green),
              _buildRangeLabel('Alto', _timeInRange!.abovePercent, AppColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeLabel(String label, double percent, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${percent.toStringAsFixed(0)}%',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações Rápidas', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Glicemia',
                Icons.water_drop,
                AppColors.primaryBlue,
                () => _navigateToRecord(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Insulina',
                Icons.vaccines,
                AppColors.green,
                () => _navigateToRecord(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Evento',
                Icons.event_note,
                AppColors.orange,
                () => _navigateToRecord(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRecord(int tabIndex) {
    // Find parent AppShell and switch to Record tab
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vá para a aba "Registrar" para adicionar'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
