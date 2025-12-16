// lib/models/profile.dart
class UserProfile {
  final String id;
  final String? nome;
  final String? email;
  final String? tipoDiabetes;
  final bool termosAceitos;

  UserProfile({
    required this.id,
    this.nome,
    this.email,
    this.tipoDiabetes,
    this.termosAceitos = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      tipoDiabetes: json['tipo_diabetes'],
      termosAceitos: json['termos_aceitos'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo_diabetes': tipoDiabetes,
      'termos_aceitos': termosAceitos,
    };
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

  GlucoseRecord({
    this.id,
    required this.userId,
    required this.quantity,
    required this.timestamp,
  });

  factory GlucoseRecord.fromJson(Map<String, dynamic> json) {
    return GlucoseRecord(
      id: json['id'],
      userId: json['user_id'],
      quantity: (json['quantidade'] as num).toDouble(),
      timestamp: DateTime.parse(json['horario']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'quantidade': quantity,
      'horario': timestamp.toIso8601String(),
    };
  }
}
