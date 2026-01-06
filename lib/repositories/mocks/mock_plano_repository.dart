// lib/repositories/mocks/mock_plano_repository.dart
// Mock implementation for freemium plan testing

import '../repository_interfaces.dart';
import '../../models/plano.dart';

/// Mock implementation of IPlanoRepository for testing
class MockPlanoRepository implements IPlanoRepository {
  static const _mockUserId = 'mock-user-id-12345';

  // Available plans
  late final List<Plano> _planos;
  late UserPlano _userPlano;
  bool _isPremium = false;

  MockPlanoRepository() {
    _initializePlanos();
  }

  void _initializePlanos() {
    _planos = [
      Plano(
        id: 'plan-free',
        nome: 'gratuito',
        descricao: 'Plano gratuito com recursos limitados',
        limiteRegistrosMes: 50,
        limiteExportacoesMes: 2,
        precoMensal: 0,
        ativo: true,
      ),
      Plano(
        id: 'plan-premium',
        nome: 'premium',
        descricao: 'Plano premium com recursos ilimitados',
        limiteRegistrosMes: null, // unlimited
        limiteExportacoesMes: null, // unlimited
        precoMensal: 9.99,
        ativo: true,
      ),
    ];

    // Start with free plan
    _userPlano = UserPlano(
      id: 'user-plan-1',
      userId: _mockUserId,
      planoId: 'plan-free',
      dataInicio: DateTime.now().subtract(const Duration(days: 30)),
      registrosUsadosMes: 15,
      exportacoesUsadasMes: 1,
      mesReferencia: DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
  }

  Plano get _currentPlan => _planos.firstWhere(
        (p) => p.id == _userPlano.planoId,
        orElse: () => _planos.first,
      );

  @override
  Future<List<Plano>> getPlanos() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_planos.where((p) => p.ativo));
  }

  @override
  Future<UserPlano?> getUserPlano() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _userPlano;
  }

  @override
  Future<UserPlanoComDetalhes?> getUserPlanoComDetalhes() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return UserPlanoComDetalhes(
      userPlano: _userPlano,
      plano: _currentPlan,
    );
  }

  @override
  Future<bool> canAddRecord() async {
    final planoDetalhes = await getUserPlanoComDetalhes();
    if (planoDetalhes == null) return true;
    return planoDetalhes.canAddRecord;
  }

  @override
  Future<bool> canExport() async {
    final planoDetalhes = await getUserPlanoComDetalhes();
    if (planoDetalhes == null) return true;
    return planoDetalhes.canExport;
  }

  @override
  Future<void> incrementRecordCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _userPlano = UserPlano(
      id: _userPlano.id,
      userId: _userPlano.userId,
      planoId: _userPlano.planoId,
      dataInicio: _userPlano.dataInicio,
      dataFim: _userPlano.dataFim,
      registrosUsadosMes: _userPlano.registrosUsadosMes + 1,
      exportacoesUsadasMes: _userPlano.exportacoesUsadasMes,
      mesReferencia: _userPlano.mesReferencia,
    );
  }

  @override
  Future<void> incrementExportCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _userPlano = UserPlano(
      id: _userPlano.id,
      userId: _userPlano.userId,
      planoId: _userPlano.planoId,
      dataInicio: _userPlano.dataInicio,
      dataFim: _userPlano.dataFim,
      registrosUsadosMes: _userPlano.registrosUsadosMes,
      exportacoesUsadasMes: _userPlano.exportacoesUsadasMes + 1,
      mesReferencia: _userPlano.mesReferencia,
    );
  }

  @override
  Future<Map<String, int>> getRemainingQuota() async {
    final planoDetalhes = await getUserPlanoComDetalhes();
    if (planoDetalhes == null) {
      return {'registros': -1, 'exportacoes': -1};
    }
    return {
      'registros': planoDetalhes.registrosRestantes,
      'exportacoes': planoDetalhes.exportacoesRestantes,
    };
  }

  @override
  Future<void> upgradeToPremium() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final premium = _planos.firstWhere((p) => p.nome == 'premium');
    _isPremium = true;
    
    _userPlano = UserPlano(
      id: _userPlano.id,
      userId: _userPlano.userId,
      planoId: premium.id,
      dataInicio: DateTime.now(),
      registrosUsadosMes: 0, // Reset counters on upgrade
      exportacoesUsadasMes: 0,
      mesReferencia: DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
  }

  // Helper methods for testing
  bool get isPremium => _isPremium;

  void resetToFreePlan() {
    _isPremium = false;
    _initializePlanos();
  }

  void setUsage({int? registros, int? exportacoes}) {
    _userPlano = UserPlano(
      id: _userPlano.id,
      userId: _userPlano.userId,
      planoId: _userPlano.planoId,
      dataInicio: _userPlano.dataInicio,
      dataFim: _userPlano.dataFim,
      registrosUsadosMes: registros ?? _userPlano.registrosUsadosMes,
      exportacoesUsadasMes: exportacoes ?? _userPlano.exportacoesUsadasMes,
      mesReferencia: _userPlano.mesReferencia,
    );
  }
}
