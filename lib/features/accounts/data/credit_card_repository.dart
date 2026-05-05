import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/msi_plan_model.dart';

class CreditCardRepository {
  final SupabaseClient _client;

  CreditCardRepository(this._client);

  Future<List<MsiPlanModel>> getMsiPlans(String accountId) async {
    try {
      final response = await _client
          .from('msi_plans')
          .select()
          .eq('account_id', accountId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MsiPlanModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception('No se pudieron cargar las compras a meses.');
    }
  }

  Future<void> createMsiPlan(MsiPlanModel plan) async {
    try {
      await _client.from('msi_plans').insert(plan.toJson());
    } catch (_) {
      throw Exception('No se pudo crear la compra a meses.');
    }
  }

  Future<void> markMonthPaid(String planId, int currentPaid) async {
    try {
      final response = await _client
          .from('msi_plans')
          .select('months_total')
          .eq('id', planId)
          .single();

      final monthsTotal = response['months_total'] as int;
      final nextPaid = currentPaid + 1;

      await _client.from('msi_plans').update({
        'months_paid': nextPaid,
        'is_active': nextPaid < monthsTotal,
      }).eq('id', planId);
    } catch (_) {
      throw Exception('No se pudo marcar el mes como pagado.');
    }
  }

  Future<void> deleteMsiPlan(String planId) async {
    try {
      await _client
          .from('msi_plans')
          .update({'is_active': false}).eq('id', planId);
    } catch (_) {
      throw Exception('No se pudo eliminar la compra a meses.');
    }
  }

  Future<void> updateCreditCardDetails({
    required String accountId,
    double? creditLimit,
    int? billingCloseDay,
    int? paymentDueDay,
  }) async {
    try {
      await _client.from('accounts').update({
        'credit_limit': creditLimit,
        'billing_close_day': billingCloseDay,
        'payment_due_day': paymentDueDay,
      }).eq('id', accountId);
    } catch (_) {
      throw Exception('No se pudieron actualizar los datos de la tarjeta.');
    }
  }

  Future<double> getTotalMonthlyMsiPayment(String accountId) async {
    try {
      final plans = await getMsiPlans(accountId);
      return plans.fold<double>(0.0, (sum, plan) => sum + plan.monthlyAmount);
    } catch (_) {
      throw Exception('No se pudo calcular el total mensual de MSI.');
    }
  }
}

final creditCardRepositoryProvider = Provider<CreditCardRepository>((ref) {
  return CreditCardRepository(supabase);
});

final msiPlansProvider =
    FutureProvider.autoDispose.family<List<MsiPlanModel>, String>(
  (ref, accountId) {
    return ref.watch(creditCardRepositoryProvider).getMsiPlans(accountId);
  },
);

final totalMonthlyMsiProvider =
    FutureProvider.autoDispose.family<double, String>((ref, accountId) {
  return ref
      .watch(creditCardRepositoryProvider)
      .getTotalMonthlyMsiPayment(accountId);
});
