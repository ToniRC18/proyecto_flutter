import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/pocket_model.dart';

class PocketsRepository {
  final SupabaseClient _client;
  final Uuid _uuid;

  PocketsRepository(
    this._client, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  Future<List<PocketModel>> getPockets(String tenantId) async {
    try {
      final response = await _client
          .from('pockets')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PocketModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception('No se pudieron cargar las metas de ahorro.');
    }
  }

  Future<void> createPocket(PocketModel pocket) async {
    try {
      await _client.from('pockets').insert(pocket.toJson());
    } catch (_) {
      throw Exception('No se pudo crear la meta de ahorro.');
    }
  }

  Future<void> deletePocket(String pocketId) async {
    try {
      await _client.from('pockets').delete().eq('id', pocketId);
    } catch (_) {
      throw Exception('No se pudo eliminar la meta de ahorro.');
    }
  }

  Future<void> contributeAmount({
    required String pocketId,
    required String accountId,
    required double amount,
    required String tenantId,
  }) async {
    String? transactionId;
    double? previousAccountBalance;
    double? previousSavedAmount;

    try {
      if (amount <= 0) {
        throw Exception('Ingresa un monto mayor a cero.');
      }

      final pocketData = await _client
          .from('pockets')
          .select('name, saved_amount, goal_amount')
          .eq('id', pocketId)
          .single();

      final accountData = await _client
          .from('accounts')
          .select('balance')
          .eq('id', accountId)
          .single();

      final pocketName = pocketData['name'] as String? ?? 'Meta';
      previousSavedAmount = (pocketData['saved_amount'] as num).toDouble();
      final goalAmount = (pocketData['goal_amount'] as num).toDouble();
      previousAccountBalance = (accountData['balance'] as num).toDouble();

      if (previousAccountBalance < amount) {
        throw Exception('Saldo insuficiente en la cuenta seleccionada.');
      }

      transactionId = _uuid.v4();
      final updatedSavedAmount = previousSavedAmount + amount;

      // Registramos el movimiento como gasto para dejar trazabilidad.
      await _client.from('transactions').insert({
        'id': transactionId,
        'tenant_id': tenantId,
        'account_id': accountId,
        'amount': amount,
        'type': 'expense',
        'category': 'pocket',
        'notes': 'Aporte a meta: $pocketName',
        'date': DateTime.now().toIso8601String(),
      });

      await _client.from('accounts').update(
          {'balance': previousAccountBalance - amount}).eq('id', accountId);

      await _client.from('pockets').update({
        'saved_amount': updatedSavedAmount,
        'is_completed': updatedSavedAmount >= goalAmount,
      }).eq('id', pocketId);
    } catch (error) {
      await _rollbackContribution(
        pocketId: pocketId,
        accountId: accountId,
        transactionId: transactionId,
        previousAccountBalance: previousAccountBalance,
        previousSavedAmount: previousSavedAmount,
      );

      if (error is Exception) rethrow;
      throw Exception('No se pudo registrar el aporte a la meta.');
    }
  }

  Future<void> _rollbackContribution({
    required String pocketId,
    required String accountId,
    required String? transactionId,
    required double? previousAccountBalance,
    required double? previousSavedAmount,
  }) async {
    try {
      if (transactionId != null) {
        await _client.from('transactions').delete().eq('id', transactionId);
      }

      if (previousAccountBalance != null) {
        await _client
            .from('accounts')
            .update({'balance': previousAccountBalance}).eq('id', accountId);
      }

      if (previousSavedAmount != null) {
        await _client.from('pockets').update({
          'saved_amount': previousSavedAmount,
          'is_completed': false,
        }).eq('id', pocketId);
      }
    } catch (_) {
      // Conservamos el error principal para el usuario.
    }
  }
}

final pocketsRepositoryProvider = Provider<PocketsRepository>((ref) {
  return PocketsRepository(supabase);
});
