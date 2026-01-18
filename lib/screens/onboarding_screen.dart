// lib/screens/onboarding_screen.dart
// Onboarding wizard for new users - collects essential profile data

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'complementary_data_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form values
  String _unidadeGlicemia = 'mg/dL';
  String _unidadeA1c = '%';
  double _metaMin = 70;
  double _metaAlvo = 100;
  double _metaMax = 180;
  String? _tipoTratamento;

  // Blue color scheme (matching login/register screens)
  static const Color _darkBlue = Color(0xFF1E3A5F);
  static const Color _mediumBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFF3B82F6);
  static const Color _paleBlue = Color(0xFFDBEAFE);
  static const Color _veryLightBlue = Color(0xFFEFF6FF);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_tipoTratamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione seu tipo de tratamento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = await AppConfig.instance.authRepository.getCurrentProfile();
      if (profile == null) throw Exception('Perfil não encontrado');

      // Convert metas to mg/dL if user selected mmol/L (always save in mg/dL)
      final metaMinMgDl = _unidadeGlicemia == 'mmol/L' ? _metaMin * 18 : _metaMin;
      final metaAlvoMgDl = _unidadeGlicemia == 'mmol/L' ? _metaAlvo * 18 : _metaAlvo;
      final metaMaxMgDl = _unidadeGlicemia == 'mmol/L' ? _metaMax * 18 : _metaMax;

      final updatedProfile = profile.copyWith(
        unidadeGlicemia: _unidadeGlicemia,
        unidadeA1c: _unidadeA1c,
        metas: {
          'min': metaMinMgDl.round(),
          'max': metaMaxMgDl.round(),
          'alvo': metaAlvoMgDl.round(),
        },
        tipoTratamento: _tipoTratamento,
        onboardingCompleto: true,
      );

      await AppConfig.instance.authRepository.updateProfile(updatedProfile);

      if (mounted) {
        // Navigate to complementary data screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ComplementaryDataScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Get slider range based on selected unit
  double get _sliderMin => _unidadeGlicemia == 'mmol/L' ? 2.0 : 40;
  double get _sliderMax => _unidadeGlicemia == 'mmol/L' ? 20.0 : 350;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBlue, _mediumBlue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomePage(),
                    _buildUnitsPage(),
                    _buildGoalsPage(),
                    _buildTreatmentPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _lightBlue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Bem-vindo ao Diabetter!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Vamos configurar seu perfil para personalizar sua experiência e ajudar você a gerenciar melhor sua diabetes.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _mediumBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _nextPage,
              child: const Text(
                'COMEÇAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Icon(
              Icons.straighten,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Unidades de Medida',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Escolha as unidades que você utiliza',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Card with options
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paleBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unidade de Glicose',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionCard(
                        'mg/dL',
                        'Mais comum no Brasil',
                        _unidadeGlicemia == 'mg/dL',
                        () => setState(() {
                          _unidadeGlicemia = 'mg/dL';
                          // Reset metas to default mg/dL values
                          _metaMin = 70;
                          _metaAlvo = 100;
                          _metaMax = 180;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOptionCard(
                        'mmol/L',
                        'Padrão internacional',
                        _unidadeGlicemia == 'mmol/L',
                        () => setState(() {
                          _unidadeGlicemia = 'mmol/L';
                          // Convert metas to mmol/L display values
                          _metaMin = 3.9;
                          _metaAlvo = 5.6;
                          _metaMax = 10.0;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Unidade de Hemoglobina Glicada (A1c)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionCard(
                        '%',
                        'NGSP/DCCT',
                        _unidadeA1c == '%',
                        () => setState(() => _unidadeA1c = '%'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOptionCard(
                        'mmol/mol',
                        'IFCC',
                        _unidadeA1c == 'mmol/mol',
                        () => setState(() => _unidadeA1c = 'mmol/mol'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _buildNavigationButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Icon(
              Icons.track_changes,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Metas de Glicose',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Defina suas faixas ideais de glicemia',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Card with sliders
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paleBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildGoalSlider(
                  'Mínimo (Hipoglicemia)',
                  _metaMin,
                  _sliderMin,
                  _metaAlvo - (_unidadeGlicemia == 'mmol/L' ? 0.5 : 10),
                  Colors.red,
                  (value) => setState(() => _metaMin = value),
                ),
                const SizedBox(height: 24),
                _buildGoalSlider(
                  'Alvo',
                  _metaAlvo,
                  _metaMin + (_unidadeGlicemia == 'mmol/L' ? 0.5 : 10),
                  _metaMax - (_unidadeGlicemia == 'mmol/L' ? 0.5 : 10),
                  Colors.green,
                  (value) => setState(() => _metaAlvo = value),
                ),
                const SizedBox(height: 24),
                _buildGoalSlider(
                  'Máximo (Hiperglicemia)',
                  _metaMax,
                  _metaAlvo + (_unidadeGlicemia == 'mmol/L' ? 0.5 : 10),
                  _sliderMax,
                  Colors.orange,
                  (value) => setState(() => _metaMax = value),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _veryLightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _mediumBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valores recomendados para a maioria dos diabéticos. Consulte seu médico.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _buildNavigationButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTreatmentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Icon(
              Icons.medical_services,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Seu Tratamento',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Como você trata o diabetes?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Treatment options
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paleBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTreatmentOption(
                  'insulina',
                  'Insulina',
                  'Aplicações diárias de insulina',
                  Icons.water_drop,
                ),
                const SizedBox(height: 12),
                _buildTreatmentOption(
                  'comprimidos',
                  'Comprimidos',
                  'Medicamentos orais',
                  Icons.medication,
                ),
                const SizedBox(height: 12),
                _buildTreatmentOption(
                  'ambos',
                  'Ambos',
                  'Insulina e comprimidos',
                  Icons.vaccines,
                ),
                const SizedBox(height: 12),
                _buildTreatmentOption(
                  'nenhum',
                  'Apenas dieta',
                  'Controle por alimentação e exercícios',
                  Icons.restaurant,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _buildNavigationButtons(isLastPage: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _mediumBlue : _veryLightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _mediumBlue : _lightBlue.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : _darkBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white.withOpacity(0.9) : _darkBlue.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSlider(
    String label,
    double value,
    double min,
    double max,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    final displayValue = _unidadeGlicemia == 'mmol/L'
        ? '${value.toStringAsFixed(1)} mmol/L'
        : '${value.round()} mg/dL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _darkBlue,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: _unidadeGlicemia == 'mmol/L' ? ((max - min) * 10).round() : (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _tipoTratamento == value;

    return GestureDetector(
      onTap: () => setState(() => _tipoTratamento = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _mediumBlue : _veryLightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _mediumBlue : _lightBlue.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : _lightBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : _mediumBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _darkBlue,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white.withOpacity(0.9) : _darkBlue.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons({bool isLastPage = false}) {
    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _previousPage,
                child: const Text(
                  'VOLTAR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        if (_currentPage > 0) const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _mediumBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _isLoading
                  ? null
                  : (isLastPage ? _completeOnboarding : _nextPage),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: _mediumBlue,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLastPage ? 'CONCLUIR' : 'PRÓXIMO',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

extension ColorShade on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
