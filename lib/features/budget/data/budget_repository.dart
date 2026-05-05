import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/domain/app_categories.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../transactions/domain/transaction_model.dart';

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
    return AppCategories.emojiForId(category);
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
        .order('id', ascending: true);
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
      final cat = AppCategories.normalizeId(row['category'] as String);
      final amt = (row['amount'] as num).toDouble();
      result[cat] = (result[cat] ?? 0) + amt;
    }
    return result;
  }

  /// Obtiene el total gastado por categoría para un mes específico.
  Future<Map<String, double>> getMonthlySpendByCategory(
    String tenantId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final raw = await _client
        .from('transactions')
        .select('category, amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', start.toIso8601String())
        .lt('date', end.toIso8601String());

    final result = <String, double>{};
    for (final row in (raw as List)) {
      final category = AppCategories.normalizeId(row['category'] as String);
      final amount = (row['amount'] as num).toDouble();
      result[category] = (result[category] ?? 0) + amount;
    }
    return result;
  }

  /// Obtiene los totales de ingresos y gastos para un mes específico.
  Future<Map<String, double>> getMonthlyTotals(
    String tenantId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final raw = await _client
        .from('transactions')
        .select('type, amount')
        .eq('tenant_id', tenantId)
        .gte('date', start.toIso8601String())
        .lt('date', end.toIso8601String());

    double income = 0;
    double expenses = 0;

    for (final row in (raw as List)) {
      final type = row['type'] as String? ?? '';
      final amount = (row['amount'] as num).toDouble();
      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expenses += amount;
      }
    }

    return {
      'income': income,
      'expenses': expenses,
    };
  }

  /// Obtiene los gastos más grandes de un mes específico.
  Future<List<Transaction>> getTopExpenses(
    String tenantId,
    int year,
    int month, {
    int limit = 5,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final raw = await _client
        .from('transactions')
        .select()
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', start.toIso8601String())
        .lt('date', end.toIso8601String())
        .order('amount', ascending: false)
        .limit(limit);

    return (raw as List)
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene el total de gastos del mes previo al mes de referencia.
  Future<double> getPreviousMonthExpenses(
    String tenantId, {
    required int year,
    required int month,
  }) async {
    final previousMonth = DateTime(year, month - 1, 1);
    final start = DateTime(previousMonth.year, previousMonth.month, 1);
    final end = DateTime(previousMonth.year, previousMonth.month + 1, 1);

    final raw = await _client
        .from('transactions')
        .select('amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', start.toIso8601String())
        .lt('date', end.toIso8601String());

    return (raw as List).fold<double>(
      0,
      (sum, row) => sum + (row['amount'] as num).toDouble(),
    );
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

final monthlySpendByCategoryProvider = FutureProvider.autoDispose
    .family<Map<String, double>, ({String tenantId, int year, int month})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getMonthlySpendByCategory(
          params.tenantId,
          params.year,
          params.month,
        );
  },
);

final monthlyTotalsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, ({String tenantId, int year, int month})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getMonthlyTotals(
          params.tenantId,
          params.year,
          params.month,
        );
  },
);

final topExpensesProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ({String tenantId, int year, int month})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getTopExpenses(
          params.tenantId,
          params.year,
          params.month,
        );
  },
);

final previousMonthExpensesProvider =
    FutureProvider.autoDispose.family<double, ({String tenantId, int year, int month})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getPreviousMonthExpenses(
          params.tenantId,
          year: params.year,
          month: params.month,
        );
  },
);
