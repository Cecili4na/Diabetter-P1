// lib/screens/complementary_data_screen.dart
// Optional complementary data collection after essential onboarding

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';

class ComplementaryDataScreen extends StatefulWidget {
  const ComplementaryDataScreen({super.key});

  @override
  State<ComplementaryDataScreen> createState() => _ComplementaryDataScreenState();
}

class _ComplementaryDataScreenState extends State<ComplementaryDataScreen> {
  // Form values
  String? _tipoDiabetes;
  DateTime? _dataNascimento;
  String? _sexo;
  final _alturaController = TextEditingController();
  final _pesoController = TextEditingController();
  List<String> _horariosMedicao = [];
  bool _isLoading = false;

  // Avatar
  Uint8List? _selectedImageBytes;
  final _imagePicker = ImagePicker();

  // Blue color scheme (matching onboarding)
  static const Color _darkBlue = Color(0xFF1E3A5F);
  static const Color _mediumBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFF3B82F6);
  static const Color _paleBlue = Color(0xFFDBEAFE);
  static const Color _veryLightBlue = Color(0xFFEFF6FF);

  // Horários disponíveis
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
  void dispose() {
    _alturaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Escolher foto'),
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

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final profile = await AppConfig.instance.authRepository.getCurrentProfile();
      if (profile == null) throw Exception('Perfil não encontrado');

      // Upload avatar if selected
      String? avatarUrl;
      if (_selectedImageBytes != null) {
        avatarUrl = await AppConfig.instance.authRepository.uploadProfilePhoto(
          profile.id,
          _selectedImageBytes!,
        );
      }

      final updatedProfile = profile.copyWith(
        tipoDiabetes: _tipoDiabetes,
        dataNascimento: _dataNascimento,
        sexo: _sexo,
        altura: double.tryParse(_alturaController.text),
        peso: double.tryParse(_pesoController.text.replaceAll(',', '.')),
        horariosMedicao: _horariosMedicao,
        avatarUrl: avatarUrl,
      );

      await AppConfig.instance.authRepository.updateProfile(updatedProfile);

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
              // Header with Avatar Picker
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildAvatarPicker(),
                    const SizedBox(height: 16),
                    const Text(
                      'Dados Complementares',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Essas informações são opcionais e ajudam a personalizar sua experiência.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _paleBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipo de Diabetes
                        _buildLabel('Tipo de Diabetes'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: _tipoDiabetes,
                          hint: 'Selecione',
                          items: const [
                            DropdownMenuItem(value: 'Tipo 1', child: Text('Tipo 1')),
                            DropdownMenuItem(value: 'Tipo 2', child: Text('Tipo 2')),
                            DropdownMenuItem(value: 'Gestacional', child: Text('Gestacional')),
                            DropdownMenuItem(value: 'LADA', child: Text('LADA')),
                            DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                          ],
                          onChanged: (value) => setState(() => _tipoDiabetes = value),
                        ),

                        const SizedBox(height: 20),

                        // Data de Nascimento
                        _buildLabel('Data de Nascimento'),
                        const SizedBox(height: 8),
                        _buildDatePicker(),

                        const SizedBox(height: 20),

                        // Altura e Peso
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Altura (cm)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _alturaController,
                                    hint: '170',
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Peso (kg)'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _pesoController,
                                    hint: '70.0',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Sexo
                        _buildLabel('Sexo'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: _sexo,
                          hint: 'Selecione',
                          items: const [
                            DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                            DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
                            DropdownMenuItem(value: 'outro', child: Text('Outro')),
                            DropdownMenuItem(value: 'prefiro_nao_informar', child: Text('Prefiro não informar')),
                          ],
                          onChanged: (value) => setState(() => _sexo = value),
                        ),

                        const SizedBox(height: 20),

                        // Horários de Medição
                        _buildLabel('Horários de Medição'),
                        const SizedBox(height: 8),
                        Text(
                          'Selecione os horários em que você costuma medir a glicose',
                          style: TextStyle(
                            fontSize: 12,
                            color: _darkBlue.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _horariosDisponiveis.map((horario) {
                            final isSelected = _horariosMedicao.contains(horario);
                            return FilterChip(
                              label: Text(
                                horario,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _darkBlue,
                                  fontSize: 13,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _horariosMedicao.add(horario);
                                  } else {
                                    _horariosMedicao.remove(horario);
                                  }
                                });
                              },
                              selectedColor: _mediumBlue,
                              checkmarkColor: Colors.white,
                              backgroundColor: _veryLightBlue,
                              side: BorderSide(
                                color: isSelected ? _mediumBlue : _lightBlue.withValues(alpha: 0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
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
                          onPressed: _isLoading ? null : _skip,
                          child: const Text(
                            'PULAR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          onPressed: _isLoading ? null : _save,
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: _mediumBlue,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SALVAR',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _darkBlue,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _veryLightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lightBlue.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        hint: Text(hint, style: TextStyle(color: _darkBlue.withValues(alpha: 0.5))),
        items: items,
        onChanged: onChanged,
        dropdownColor: _veryLightBlue,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _veryLightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lightBlue.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dataNascimento ?? DateTime(1990),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _dataNascimento = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _veryLightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _lightBlue.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dataNascimento != null
                    ? '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}'
                    : 'Selecionar data',
                style: TextStyle(
                  color: _dataNascimento != null ? _darkBlue : _darkBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
            Icon(Icons.calendar_today, color: _mediumBlue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 3),
              image: _selectedImageBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_selectedImageBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImageBytes == null
                ? const Icon(Icons.person, color: Colors.white, size: 50)
                : null,
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
              child: Icon(Icons.camera_alt, size: 20, color: _mediumBlue),
            ),
          ),
        ],
      ),
    );
  }
}
