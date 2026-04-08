import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

/// Modelo de presupuesto por categoría.
class Budget {
  final String id;
  final String tenantId;
  final String category;
  final double amount;
  final String period; // 'monthly' | 'weekly'

  const Budget({
    required this.id,
    required this.tenantId,
    required this.category,
    required this.amount,
    required this.period,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String? ?? 'monthly',
    );
  }

  // Emoji para la categoría del presupuesto
  String get emoji {
    const map = {
      'comida': '🍔',
      'food': '🍔',
      'transporte': '🚗',
      'transport': '🚗',
      'renta': '🏠',
      'rent': '🏠',
      'ocio': '🎮',
      'entertainment': '🎮',
      'super': '🛒',
      'grocery': '🛒',
      'salud': '💊',
      'health': '💊',
      'ropa': '👗',
      'clothing': '👗',
      'tecnología': '📱',
      'tech': '📱',
    };
    return map[category.toLowerCase()] ?? '💰';
  }
}

/// Repositorio para gestión de presupuestos.
class BudgetRepository {
  final SupabaseClient _client;
  BudgetRepository(this._client);

  /// Obtiene todos los presupuestos del tenant.
  Future<List<Budget>> getBudgets(String tenantId) async {
    final raw = await _client
        .from('budgets')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: true);
    return (raw as List)
        .map((json) => Budget.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crea un nuevo presupuesto.
  Future<void> createBudget({
    required String tenantId,
    required String category,
    required double amount,
    required String period,
  }) async {
    await _client.from('budgets').insert({
      'tenant_id': tenantId,
      'category': category,
      'amount': amount,
      'period': period,
    });
  }

  /// Elimina un presupuesto.
  Future<void> deleteBudget(String budgetId) async {
    await _client.from('budgets').delete().eq('id', budgetId);
  }

  /// Obtiene el gasto por categoría del mes actual.
  /// Retorna mapa {category: totalGastado}
  Future<Map<String, double>> getSpentByCategory(String tenantId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final raw = await _client
        .from('transactions')
        .select('category, amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', startOfMonth);

    final Map<String, double> result = {};
    for (final row in (raw as List)) {
      final cat = (row['category'] as String).toLowerCase();
      final amt = (row['amount'] as num).toDouble();
      result[cat] = (result[cat] ?? 0) + amt;
    }
    return result;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(supabase);
});

final budgetsListProvider =
    FutureProvider.autoDispose.family<List<Budget>, String>((ref, tenantId) {
  return ref.watch(budgetRepositoryProvider).getBudgets(tenantId);
});

final spentByCategoryProvider =
    FutureProvider.autoDispose.family<Map<String, double>, String>(
  (ref, tenantId) {
    return ref.watch(budgetRepositoryProvider).getSpentByCategory(tenantId);
  },
);
