// lib/models/event_record.dart
// RF-06: Register events (refeição, exercício, estresse, outros)

enum EventType {
  refeicao,
  exercicio,
  estresse,
  medicamento,
  outro;

  String get displayName {
    switch (this) {
      case EventType.refeicao:
        return 'Refeição';
      case EventType.exercicio:
        return 'Exercício';
      case EventType.estresse:
        return 'Estresse';
      case EventType.medicamento:
        return 'Medicamento';
      case EventType.outro:
        return 'Outro';
    }
  }

  static EventType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'refeicao':
        return EventType.refeicao;
      case 'exercicio':
        return EventType.exercicio;
      case 'estresse':
        return EventType.estresse;
      case 'medicamento':
        return EventType.medicamento;
      default:
        return EventType.outro;
    }
  }
}

class EventRecord {
  final String? id;
  final String userId;
  final String titulo;
  final String? descricao;
  final EventType tipoEvento;
  final double? carboidratos;
  final double? calorias;
  final DateTime horario;
  final DateTime? createdAt;

  EventRecord({
    this.id,
    required this.userId,
    required this.titulo,
    this.descricao,
    this.tipoEvento = EventType.outro,
    this.carboidratos,
    this.calorias,
    required this.horario,
    this.createdAt,
  });

  factory EventRecord.fromJson(Map<String, dynamic> json) {
    return EventRecord(
      id: json['id'],
      userId: json['user_id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      tipoEvento: EventType.fromString(json['tipo_evento'] ?? 'outro'),
      carboidratos: json['carboidratos'] != null 
          ? (json['carboidratos'] as num).toDouble() 
          : null,
      calorias: json['calorias'] != null 
          ? (json['calorias'] as num).toDouble() 
          : null,
      horario: DateTime.parse(json['horario']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'titulo': titulo,
      'descricao': descricao,
      'tipo_evento': tipoEvento.name,
      'carboidratos': carboidratos,
      'calorias': calorias,
      'horario': horario.toIso8601String(),
    };
  }
}
