// lib/screens/profile_screen.dart
// User profile and settings screen (RF-03)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/export_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserProfile? _profile;
  Map<String, int>? _quota;

  final _imagePicker = ImagePicker();

  // Horários disponíveis para medição
  static const List<String> _horariosDisponiveis = [
    'Jejum',
    'Pré-café',
    'Pós-café',
    'Pré-almoço',
    'Pós-almoço',
    'Pré-jantar',
    'Pós-jantar',
    'Antes de dormir',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Public method to refresh data (called by AppShell on tab change)
  Future<void> refresh() => _loadProfile();

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
    // Calculate age from birth date
    int? idade;
    if (_profile?.dataNascimento != null) {
      final now = DateTime.now();
      idade = now.year - _profile!.dataNascimento!.year;
      if (now.month < _profile!.dataNascimento!.month ||
          (now.month == _profile!.dataNascimento!.month && now.day < _profile!.dataNascimento!.day)) {
        idade--;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: Column(
        children: [
          _buildAvatar(),
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
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          // Complementary data chips
          if (_hasComplementaryData()) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (_profile?.tipoDiabetes != null)
                  _buildHeaderChip(_profile!.tipoDiabetes!),
                if (idade != null)
                  _buildHeaderChip('$idade anos'),
                if (_profile?.altura != null)
                  _buildHeaderChip('${_profile!.altura!.round()} cm'),
                if (_profile?.peso != null)
                  _buildHeaderChip('${_profile!.peso!.toStringAsFixed(1)} kg'),
              ],
            ),
          ],
          // Edit complementary data button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showEditComplementaryDataDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Editar dados pessoais',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (AppConfig.isMockMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Modo de Teste',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasComplementaryData() {
    return _profile?.tipoDiabetes != null ||
        _profile?.dataNascimento != null ||
        _profile?.altura != null ||
        _profile?.peso != null;
  }

  Widget _buildHeaderChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: _profile?.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _profile!.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      placeholder: (_, __) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhotoOptions() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Alterar foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked != null && _profile != null) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Atualizando foto...'),
            ],
          ),
        ),
      );

      try {
        final bytes = await picked.readAsBytes();
        final avatarUrl = await AppConfig.instance.authRepository.uploadProfilePhoto(
          _profile!.id,
          bytes,
        );

        final updatedProfile = _profile!.copyWith(avatarUrl: avatarUrl);
        await AppConfig.instance.authRepository.updateProfile(updatedProfile);

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        await _loadProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto atualizada!'),
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
              content: Text('Erro ao atualizar foto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileCard() {
    final tipoTratamentoDisplay = {
      'insulina': 'Insulina',
      'comprimidos': 'Comprimidos',
      'ambos': 'Insulina e Comprimidos',
      'nenhum': 'Apenas dieta',
    };

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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primaryBlue, size: 20),
                onPressed: _showEditMedicalInfoDialog,
                tooltip: 'Editar',
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Unidade de Glicose', _profile?.unidadeGlicemia ?? 'mg/dL'),
          _buildInfoRow('Unidade de A1c', _profile?.unidadeA1c ?? '%'),
          _buildInfoRow(
            'Meta de Glicemia',
            '${_profile?.metas['min'] ?? 70} - ${_profile?.metas['max'] ?? 180} ${_profile?.unidadeGlicemia ?? 'mg/dL'}',
          ),
          _buildInfoRow(
            'Tratamento',
            tipoTratamentoDisplay[_profile?.tipoTratamento] ?? 'Não informado',
          ),
        ],
      ),
    );
  }

  Future<void> _showEditMedicalInfoDialog() async {
    if (_profile == null) return;

    String unidadeGlicemia = _profile!.unidadeGlicemia;
    String unidadeA1c = _profile!.unidadeA1c;
    String? tipoTratamento = _profile!.tipoTratamento;
    double metaMin = (_profile!.metas['min'] as num).toDouble();
    double metaMax = (_profile!.metas['max'] as num).toDouble();
    double metaAlvo = (_profile!.metas['alvo'] as num).toDouble();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Informações Médicas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Unidade de Glicose', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'mg/dL', label: Text('mg/dL')),
                    ButtonSegment(value: 'mmol/L', label: Text('mmol/L')),
                  ],
                  selected: {unidadeGlicemia},
                  onSelectionChanged: (value) => setDialogState(() => unidadeGlicemia = value.first),
                ),
                const SizedBox(height: 16),
                const Text('Unidade de A1c', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '%', label: Text('%')),
                    ButtonSegment(value: 'mmol/mol', label: Text('mmol/mol')),
                  ],
                  selected: {unidadeA1c},
                  onSelectionChanged: (value) => setDialogState(() => unidadeA1c = value.first),
                ),
                const SizedBox(height: 16),
                const Text('Tratamento', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoTratamento,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'insulina', child: Text('Insulina')),
                    DropdownMenuItem(value: 'comprimidos', child: Text('Comprimidos')),
                    DropdownMenuItem(value: 'ambos', child: Text('Ambos')),
                    DropdownMenuItem(value: 'nenhum', child: Text('Apenas dieta')),
                  ],
                  onChanged: (value) => setDialogState(() => tipoTratamento = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: AppButtonStyles.primary,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final updatedProfile = _profile!.copyWith(
        unidadeGlicemia: unidadeGlicemia,
        unidadeA1c: unidadeA1c,
        tipoTratamento: tipoTratamento,
        metas: {'min': metaMin.round(), 'max': metaMax.round(), 'alvo': metaAlvo.round()},
      );

      try {
        await AppConfig.instance.authRepository.updateProfile(updatedProfile);
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informações atualizadas!'), backgroundColor: AppColors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showEditComplementaryDataDialog() async {
    if (_profile == null) return;

    String? tipoDiabetes = _profile!.tipoDiabetes;
    DateTime? dataNascimento = _profile!.dataNascimento;
    String? sexo = _profile!.sexo;
    final alturaController = TextEditingController(
      text: _profile!.altura?.round().toString() ?? '',
    );
    final pesoController = TextEditingController(
      text: _profile!.peso?.toStringAsFixed(1) ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Dados Complementares'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tipo de Diabetes', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoDiabetes,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tipo 1', child: Text('Tipo 1')),
                    DropdownMenuItem(value: 'Tipo 2', child: Text('Tipo 2')),
                    DropdownMenuItem(value: 'Gestacional', child: Text('Gestacional')),
                    DropdownMenuItem(value: 'LADA', child: Text('LADA')),
                    DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                  ],
                  onChanged: (value) => setDialogState(() => tipoDiabetes = value),
                ),
                const SizedBox(height: 16),
                const Text('Data de Nascimento', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataNascimento ?? DateTime(1990),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => dataNascimento = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dataNascimento != null
                                ? '${dataNascimento!.day.toString().padLeft(2, '0')}/${dataNascimento!.month.toString().padLeft(2, '0')}/${dataNascimento!.year}'
                                : 'Selecionar data',
                            style: TextStyle(
                              color: dataNascimento != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Sexo', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: sexo,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
                    DropdownMenuItem(value: 'outro', child: Text('Outro')),
                    DropdownMenuItem(value: 'prefiro_nao_informar', child: Text('Prefiro não informar')),
                  ],
                  onChanged: (value) => setDialogState(() => sexo = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Altura (cm)', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: alturaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '170',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Peso (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: pesoController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '70.0',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: AppButtonStyles.primary,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final altura = double.tryParse(alturaController.text);
      final peso = double.tryParse(pesoController.text.replaceAll(',', '.'));

      final updatedProfile = _profile!.copyWith(
        tipoDiabetes: tipoDiabetes,
        dataNascimento: dataNascimento,
        sexo: sexo,
        altura: altura,
        peso: peso,
      );

      try {
        await AppConfig.instance.authRepository.updateProfile(updatedProfile);
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados atualizados!'), backgroundColor: AppColors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    alturaController.dispose();
    pesoController.dispose();
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
    // Build measurement times subtitle
    final horarios = _profile?.horariosMedicao ?? [];
    String horariosSubtitle = 'Nenhum configurado';
    if (horarios.isNotEmpty) {
      if (horarios.length <= 2) {
        horariosSubtitle = horarios.join(', ');
      } else {
        horariosSubtitle = '${horarios.length} horários configurados';
      }
    }

    return Container(
      decoration: AppDecorations.card,
      child: Column(
        children: [
          _buildSettingsItem(Icons.notifications_outlined, 'Notificações', null, () {}),
          const Divider(height: 1),
          _buildSettingsItem(Icons.schedule, 'Horários de Medição', horariosSubtitle, _showMeasurementTimesDialog),
          const Divider(height: 1),
          _buildSettingsItem(Icons.download, 'Exportar Dados', null, _exportData),
          const Divider(height: 1),
          _buildSettingsItem(Icons.help_outline, 'Ajuda', null, () {}),
        ],
      ),
    );
  }

  Future<void> _showMeasurementTimesDialog() async {
    if (_profile == null) return;

    List<String> selected = List.from(_profile!.horariosMedicao);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Horários de Medição'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione os horários em que você costuma medir a glicose:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _horariosDisponiveis.map((horario) {
                    final isSelected = selected.contains(horario);
                    return FilterChip(
                      label: Text(horario),
                      selected: isSelected,
                      onSelected: (value) {
                        setDialogState(() {
                          if (value) {
                            selected.add(horario);
                          } else {
                            selected.remove(horario);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primaryBlue,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: AppButtonStyles.primary,
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedProfile = _profile!.copyWith(
        horariosMedicao: result,
      );

      try {
        await AppConfig.instance.authRepository.updateProfile(updatedProfile);
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Horários atualizados!'), backgroundColor: AppColors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildSettingsItem(IconData icon, String label, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkGrey),
      title: Text(label, style: AppTextStyles.body),
      subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.bodySmall) : null,
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
