// lib/screens/record_screen.dart
// Screen for recording glucose, insulin, and events (RF-04, RF-05, RF-06)

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../models/event_record.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Novo Registro'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.water_drop), text: 'Glicemia'),
            Tab(icon: Icon(Icons.vaccines), text: 'Insulina'),
            Tab(icon: Icon(Icons.event_note), text: 'Evento'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GlucoseForm(),
          _InsulinForm(),
          _EventForm(),
        ],
      ),
    );
  }
}

// =====================================================
// GLUCOSE FORM
// =====================================================
class _GlucoseForm extends StatefulWidget {
  const _GlucoseForm();

  @override
  State<_GlucoseForm> createState() => _GlucoseFormState();
}

class _GlucoseFormState extends State<_GlucoseForm> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um valor válido'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final record = GlucoseRecord(
        userId: 'mock-user',
        quantity: value,
        timestamp: DateTime.now(),
        notas: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await AppConfig.instance.healthRepository.addGlucoseRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Glicemia registrada!'),
            backgroundColor: AppColors.green,
          ),
        );
        _valueController.clear();
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor da Glicemia', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.metric,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '120',
                    hintStyle: AppTextStyles.metric.copyWith(color: AppColors.grey),
                    suffixText: 'mg/dL',
                    suffixStyle: AppTextStyles.body,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Notas (opcional)', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ex: Antes do café da manhã',
                    hintStyle: AppTextStyles.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: AppButtonStyles.primary,
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('REGISTRAR GLICEMIA'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// INSULIN FORM
// =====================================================
class _InsulinForm extends StatefulWidget {
  const _InsulinForm();

  @override
  State<_InsulinForm> createState() => _InsulinFormState();
}

class _InsulinFormState extends State<_InsulinForm> {
  final _unitsController = TextEditingController();
  String _selectedType = 'Bolus';
  String _selectedBodyPart = 'Abdômen';
  bool _isLoading = false;

  final List<String> _types = ['Bolus', 'Basal', 'Correção'];
  final List<String> _bodyParts = ['Abdômen', 'Braço esquerdo', 'Braço direito', 'Coxa esquerda', 'Coxa direita'];

  Future<void> _submit() async {
    final units = double.tryParse(_unitsController.text);
    if (units == null || units <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um valor válido'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final record = InsulinRecord(
        userId: 'mock-user',
        quantity: units,
        timestamp: DateTime.now(),
        type: _selectedType,
        bodyPart: _selectedBodyPart,
      );

      await AppConfig.instance.healthRepository.addInsulinRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Insulina registrada!'),
            backgroundColor: AppColors.green,
          ),
        );
        _unitsController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unidades', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                TextField(
                  controller: _unitsController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.metric,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '10',
                    hintStyle: AppTextStyles.metric.copyWith(color: AppColors.grey),
                    suffixText: 'U',
                    suffixStyle: AppTextStyles.body,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tipo de Insulina', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _types.map((type) => ChoiceChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (selected) => setState(() => _selectedType = type),
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: _selectedType == type ? Colors.white : AppColors.textPrimary,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Text('Local de Aplicação', style: AppTextStyles.label),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBodyPart,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                  ),
                  items: _bodyParts.map((part) => DropdownMenuItem(
                    value: part,
                    child: Text(part),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedBodyPart = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: AppButtonStyles.primary,
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('REGISTRAR INSULINA'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// EVENT FORM
// =====================================================
class _EventForm extends StatefulWidget {
  const _EventForm();

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  EventType _selectedType = EventType.refeicao;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um título'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final record = EventRecord(
        userId: 'mock-user',
        titulo: _titleController.text,
        descricao: _descController.text.isEmpty ? null : _descController.text,
        tipoEvento: _selectedType,
        horario: DateTime.now(),
      );

      await AppConfig.instance.healthRepository.addEventRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Evento registrado!'),
            backgroundColor: AppColors.green,
          ),
        );
        _titleController.clear();
        _descController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de Evento', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EventType.values.map((type) => ChoiceChip(
                    label: Text(type.displayName),
                    selected: _selectedType == type,
                    onSelected: (selected) => setState(() => _selectedType = type),
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: _selectedType == type ? Colors.white : AppColors.textPrimary,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Text('Título', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Almoço, Caminhada, etc.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Descrição (opcional)', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Detalhes adicionais...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: AppButtonStyles.primary,
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('REGISTRAR EVENTO'),
            ),
          ),
        ],
      ),
    );
  }
}
