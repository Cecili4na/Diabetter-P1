// lib/screens/profile_screen.dart
// User profile and settings screen (RF-03)

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/export_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserProfile? _profile;
  Map<String, int>? _quota;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AppConfig.instance.authRepository.getCurrentProfile(),
        AppConfig.instance.planoRepository.getRemainingQuota(),
      ]);

      setState(() {
        _profile = results[0] as UserProfile?;
        _quota = results[1] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    // Show period selector dialog
    final selectedDays = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Período do Relatório'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecione o período de dados para o PDF:'),
            const SizedBox(height: 16),
            _buildPeriodOption(context, 7, 'Últimos 7 dias'),
            _buildPeriodOption(context, 14, 'Últimos 14 dias'),
            _buildPeriodOption(context, 30, 'Últimos 30 dias'),
            _buildPeriodOption(context, 45, 'Últimos 45 dias'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
        ],
      ),
    );

    if (selectedDays == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Gerando PDF...'),
          ],
        ),
      ),
    );

    try {
      final exportService = ExportService(
        healthRepo: AppConfig.instance.healthRepository,
        planoRepo: AppConfig.instance.planoRepository,
      );

      final now = DateTime.now();
      final from = now.subtract(Duration(days: selectedDays));

      final filePath = await exportService.exportToPdf(
        from: from,
        to: now,
        userName: _profile?.nome ?? 'Usuário',
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Share the PDF (on mobile) or just show success (on web, download already triggered)
      await exportService.sharePdf(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ PDF exportado com sucesso!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPeriodOption(BuildContext context, int days, String label) {
    return ListTile(
      leading: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => Navigator.pop(context, days),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildStatsCard(),
                          const SizedBox(height: 16),
                          _buildSettingsCard(),
                          const SizedBox(height: 16),
                          _buildActionsCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _profile?.nome ?? 'Usuário',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _profile?.email ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          if (AppConfig.isMockMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🧪 Modo de Teste',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              Text('Informações Médicas', style: AppTextStyles.heading3),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Tipo de Diabetes', _profile?.tipoDiabetes ?? 'Não informado'),
          _buildInfoRow('Unidade', _profile?.unidadeGlicemia ?? 'mg/dL'),
          _buildInfoRow(
            'Meta de Glicemia',
            '${_profile?.metas['min'] ?? 70} - ${_profile?.metas['max'] ?? 180} mg/dL',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final registrosRestantes = _quota?['registros'] ?? -1;
    final exportacoesRestantes = _quota?['exportacoes'] ?? -1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppColors.orange),
              const SizedBox(width: 12),
              Text('Seu Plano', style: AppTextStyles.heading3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: registrosRestantes == -1 ? AppColors.lightGreen : AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  registrosRestantes == -1 ? 'Premium' : 'Gratuito',
                  style: TextStyle(
                    color: registrosRestantes == -1 ? AppColors.green : AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildQuotaRow(
            'Registros este mês',
            registrosRestantes == -1 ? 'Ilimitado' : '$registrosRestantes restantes',
            registrosRestantes == -1 ? 1.0 : (registrosRestantes / 50).clamp(0, 1),
          ),
          const SizedBox(height: 12),
          _buildQuotaRow(
            'Exportações este mês',
            exportacoesRestantes == -1 ? 'Ilimitado' : '$exportacoesRestantes restantes',
            exportacoesRestantes == -1 ? 1.0 : (exportacoesRestantes / 2).clamp(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaRow(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body),
            Text(value, style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightGrey,
            valueColor: AlwaysStoppedAnimation(
              progress > 0.3 ? AppColors.green : AppColors.red,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: AppDecorations.card,
      child: Column(
        children: [
          _buildSettingsItem(Icons.notifications_outlined, 'Notificações', () {}),
          const Divider(height: 1),
          _buildSettingsItem(Icons.schedule, 'Horários de Medição', () {}),
          const Divider(height: 1),
          _buildSettingsItem(Icons.download, 'Exportar Dados', _exportData),
          const Divider(height: 1),
          _buildSettingsItem(Icons.help_outline, 'Ajuda', () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkGrey),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
      onTap: onTap,
    );
  }

  Widget _buildActionsCard() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: AppButtonStyles.secondary,
            icon: const Icon(Icons.logout),
            label: const Text('SAIR DA CONTA'),
            onPressed: () async {
              await AppConfig.instance.authRepository.signOut();
              // Navigate to login and clear the navigation stack
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Diabetter v1.0.0',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
