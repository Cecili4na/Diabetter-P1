// lib/models/plano.dart
// RF-11: Freemium subscription plans

class Plano {
  final String id;
  final String nome;
  final String? descricao;
  final int? limiteRegistrosMes;      // null = unlimited
  final int? limiteExportacoesMes;    // null = unlimited
  final double precoMensal;
  final bool ativo;

  Plano({
    required this.id,
    required this.nome,
    this.descricao,
    this.limiteRegistrosMes,
    this.limiteExportacoesMes,
    this.precoMensal = 0,
    this.ativo = true,
  });

  bool get isUnlimited => limiteRegistrosMes == null;
  bool get isFree => precoMensal == 0;

  factory Plano.fromJson(Map<String, dynamic> json) {
    return Plano(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      limiteRegistrosMes: json['limite_registros_mes'],
      limiteExportacoesMes: json['limite_exportacoes_mes'],
      precoMensal: (json['preco_mensal'] as num?)?.toDouble() ?? 0,
      ativo: json['ativo'] ?? true,
    );
  }
}

class UserPlano {
  final String id;
  final String userId;
  final String planoId;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final int registrosUsadosMes;
  final int exportacoesUsadasMes;
  final DateTime mesReferencia;

  UserPlano({
    required this.id,
    required this.userId,
    required this.planoId,
    required this.dataInicio,
    this.dataFim,
    this.registrosUsadosMes = 0,
    this.exportacoesUsadasMes = 0,
    required this.mesReferencia,
  });

  factory UserPlano.fromJson(Map<String, dynamic> json) {
    return UserPlano(
      id: json['id'],
      userId: json['user_id'],
      planoId: json['plano_id'],
      dataInicio: DateTime.parse(json['data_inicio']),
      dataFim: json['data_fim'] != null 
          ? DateTime.parse(json['data_fim']) 
          : null,
      registrosUsadosMes: json['registros_usados_mes'] ?? 0,
      exportacoesUsadasMes: json['exportacoes_usadas_mes'] ?? 0,
      mesReferencia: DateTime.parse(json['mes_referencia']),
    );
  }
}

/// Combined view of user's plan with plan details
class UserPlanoComDetalhes {
  final UserPlano userPlano;
  final Plano plano;

  UserPlanoComDetalhes({
    required this.userPlano,
    required this.plano,
  });

  bool get canAddRecord {
    if (plano.limiteRegistrosMes == null) return true;
    return userPlano.registrosUsadosMes < plano.limiteRegistrosMes!;
  }

  bool get canExport {
    if (plano.limiteExportacoesMes == null) return true;
    return userPlano.exportacoesUsadasMes < plano.limiteExportacoesMes!;
  }

  int get registrosRestantes {
    if (plano.limiteRegistrosMes == null) return -1; // unlimited
    return plano.limiteRegistrosMes! - userPlano.registrosUsadosMes;
  }

  int get exportacoesRestantes {
    if (plano.limiteExportacoesMes == null) return -1; // unlimited
    return plano.limiteExportacoesMes! - userPlano.exportacoesUsadasMes;
  }
}
