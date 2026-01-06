import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/plano.dart';
import 'repository_interfaces.dart';

/// RF-11: Freemium plan management
class PlanoRepository implements IPlanoRepository {
  final SupabaseClient _client = SupabaseService().client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Get all available plans
  Future<List<Plano>> getPlanos() async {
    final List<dynamic> data = await _client
        .from('planos')
        .select()
        .eq('ativo', true)
        .order('preco_mensal');

    return data.map((json) => Plano.fromJson(json)).toList();
  }

  /// Get user's current subscription
  Future<UserPlano?> getUserPlano() async {
    if (_userId == null) return null;

    try {
      final data = await _client
          .from('user_planos')
          .select()
          .eq('user_id', _userId!)
          .single();

      return UserPlano.fromJson(data);
    } catch (e) {
      // No subscription found
      return null;
    }
  }

  /// Get user's plan with full details
  Future<UserPlanoComDetalhes?> getUserPlanoComDetalhes() async {
    if (_userId == null) return null;

    try {
      final data = await _client
          .from('user_planos')
          .select('''
            *,
            planos:plano_id (*)
          ''')
          .eq('user_id', _userId!)
          .single();

      final userPlano = UserPlano.fromJson(data);
      final plano = Plano.fromJson(data['planos']);

      return UserPlanoComDetalhes(userPlano: userPlano, plano: plano);
    } catch (e) {
      return null;
    }
  }

  /// Check if user can add a new record (respects freemium limits)
  Future<bool> canAddRecord() async {
    final planoDetalhes = await getUserPlanoComDetalhes();
    if (planoDetalhes == null) return true; // No plan = allow (fallback)
    return planoDetalhes.canAddRecord;
  }

  /// Check if user can export (respects freemium limits)
  Future<bool> canExport() async {
    final planoDetalhes = await getUserPlanoComDetalhes();
    if (planoDetalhes == null) return true;
    return planoDetalhes.canExport;
  }

  /// Increment record counter after adding a record
  Future<void> incrementRecordCount() async {
    if (_userId == null) return;

    await _client.rpc('increment_record_count', params: {
      'p_user_id': _userId,
    });
    
    // Fallback if RPC doesn't exist - direct update
    // await _client
    //     .from('user_planos')
    //     .update({
    //       'registros_usados_mes': /* current + 1 */,
    //       'updated_at': DateTime.now().toIso8601String(),
    //     })
    //     .eq('user_id', _userId!);
  }

  /// Increment export counter
  Future<void> incrementExportCount() async {
    if (_userId == null) return;

    await _client.rpc('increment_export_count', params: {
      'p_user_id': _userId,
    });
  }

  /// Get remaining quota info for UI display
  Future<Map<String, int>> getRemainingQuota() async {
    final planoDetalhes = await getUserPlanoComDetalhes();
    if (planoDetalhes == null) {
      return {'registros': -1, 'exportacoes': -1}; // -1 = unlimited
    }
    return {
      'registros': planoDetalhes.registrosRestantes,
      'exportacoes': planoDetalhes.exportacoesRestantes,
    };
  }

  /// Upgrade to premium (simulated for MVP - RF-11 specifies no real payment)
  Future<void> upgradeToPremium() async {
    if (_userId == null) throw Exception('User not logged in');

    final planos = await getPlanos();
    final premium = planos.firstWhere(
      (p) => p.nome == 'premium',
      orElse: () => throw Exception('Premium plan not found'),
    );

    await _client
        .from('user_planos')
        .update({
          'plano_id': premium.id,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', _userId!);
  }
}
