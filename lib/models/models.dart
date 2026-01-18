// lib/models/profile.dart
class UserProfile {
  final String id;
  final String? nome;
  final String? email;
  final String? tipoDiabetes;
  final bool termosAceitos;
  final List<String> horariosMedicao;  // RF-03: measurement times
  final Map<String, dynamic> metas;     // RF-03: {min, max, alvo}
  final String unidadeGlicemia;         // mg/dL or mmol/L

  // Novos campos - Onboarding essencial
  final String unidadeA1c;              // '%' ou 'mmol/mol'
  final String? tipoTratamento;         // 'insulina', 'comprimidos', 'ambos', 'nenhum'
  final bool onboardingCompleto;

  // Novos campos - Dados complementares
  final DateTime? dataNascimento;
  final double? altura;                 // cm
  final double? peso;                   // kg
  final String? sexo;                   // 'masculino', 'feminino', 'outro', 'prefiro_nao_informar'

  UserProfile({
    required this.id,
    this.nome,
    this.email,
    this.tipoDiabetes,
    this.termosAceitos = false,
    this.horariosMedicao = const [],
    this.metas = const {'min': 70, 'max': 180, 'alvo': 100},
    this.unidadeGlicemia = 'mg/dL',
    this.unidadeA1c = '%',
    this.tipoTratamento,
    this.onboardingCompleto = false,
    this.dataNascimento,
    this.altura,
    this.peso,
    this.sexo,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      tipoDiabetes: json['tipo_diabetes'],
      termosAceitos: json['termos_aceitos'] ?? false,
      horariosMedicao: (json['horarios_medicao'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      metas: (json['metas'] as Map<String, dynamic>?) ??
          {'min': 70, 'max': 180, 'alvo': 100},
      unidadeGlicemia: json['unidade_glicemia'] ?? 'mg/dL',
      unidadeA1c: json['unidade_a1c'] ?? '%',
      tipoTratamento: json['tipo_tratamento'],
      onboardingCompleto: json['onboarding_completo'] ?? false,
      dataNascimento: json['data_nascimento'] != null
          ? DateTime.parse(json['data_nascimento'])
          : null,
      altura: json['altura'] != null ? (json['altura'] as num).toDouble() : null,
      peso: json['peso'] != null ? (json['peso'] as num).toDouble() : null,
      sexo: json['sexo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo_diabetes': tipoDiabetes,
      'termos_aceitos': termosAceitos,
      'horarios_medicao': horariosMedicao,
      'metas': metas,
      'unidade_glicemia': unidadeGlicemia,
      'unidade_a1c': unidadeA1c,
      'tipo_tratamento': tipoTratamento,
      'onboarding_completo': onboardingCompleto,
      'data_nascimento': dataNascimento?.toIso8601String().split('T').first,
      'altura': altura,
      'peso': peso,
      'sexo': sexo,
    };
  }

  UserProfile copyWith({
    String? nome,
    String? email,
    String? tipoDiabetes,
    bool? termosAceitos,
    List<String>? horariosMedicao,
    Map<String, dynamic>? metas,
    String? unidadeGlicemia,
    String? unidadeA1c,
    String? tipoTratamento,
    bool? onboardingCompleto,
    DateTime? dataNascimento,
    double? altura,
    double? peso,
    String? sexo,
  }) {
    return UserProfile(
      id: id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tipoDiabetes: tipoDiabetes ?? this.tipoDiabetes,
      termosAceitos: termosAceitos ?? this.termosAceitos,
      horariosMedicao: horariosMedicao ?? this.horariosMedicao,
      metas: metas ?? this.metas,
      unidadeGlicemia: unidadeGlicemia ?? this.unidadeGlicemia,
      unidadeA1c: unidadeA1c ?? this.unidadeA1c,
      tipoTratamento: tipoTratamento ?? this.tipoTratamento,
      onboardingCompleto: onboardingCompleto ?? this.onboardingCompleto,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      altura: altura ?? this.altura,
      peso: peso ?? this.peso,
      sexo: sexo ?? this.sexo,
    );
  }
}


// lib/models/insulin_record.dart
class InsulinRecord {
  final String? id;
  final String userId;
  final double quantity;
  final DateTime timestamp;
  final String? type;
  final String? bodyPart;

  InsulinRecord({
    this.id,
    required this.userId,
    required this.quantity,
    required this.timestamp,
    this.type,
    this.bodyPart,
  });

  factory InsulinRecord.fromJson(Map<String, dynamic> json) {
    return InsulinRecord(
      id: json['id'],
      userId: json['user_id'],
      quantity: (json['quantidade'] as num).toDouble(),
      timestamp: DateTime.parse(json['horario']),
      type: json['tipo'],
      bodyPart: json['parte_corpo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Usually let DB generate ID
      'user_id': userId,
      'quantidade': quantity,
      'horario': timestamp.toIso8601String(),
      'tipo': type,
      'parte_corpo': bodyPart,
    };
  }
}

// lib/models/glucose_record.dart
class GlucoseRecord {
  final String? id;
  final String userId;
  final double quantity; // mg/dL
  final DateTime timestamp;
  final String? notas;  // RF-04: optional notes

  GlucoseRecord({
    this.id,
    required this.userId,
    required this.quantity,
    required this.timestamp,
    this.notas,
  });

  factory GlucoseRecord.fromJson(Map<String, dynamic> json) {
    return GlucoseRecord(
      id: json['id'],
      userId: json['user_id'],
      quantity: (json['quantidade'] as num).toDouble(),
      timestamp: DateTime.parse(json['horario']),
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'quantidade': quantity,
      'horario': timestamp.toIso8601String(),
      'notas': notas,
    };
  }
}

