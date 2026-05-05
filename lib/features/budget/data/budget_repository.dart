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

class BudgetStatsRange {
  final DateTime start;
  final DateTime end;

  const BudgetStatsRange({
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetStatsRange &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

class SpendingTrend {
  final String category;
  final double currentAmount;
  final double previousAmount;

  const SpendingTrend({
    required this.category,
    required this.currentAmount,
    required this.previousAmount,
  });

  double get deltaAmount => currentAmount - previousAmount;
  double get deltaPercent {
    if (previousAmount <= 0) {
      return currentAmount > 0 ? 100 : 0;
    }
    return (deltaAmount / previousAmount) * 100;
  }

  bool get increased => deltaAmount > 0;
  bool get decreased => deltaAmount < 0;
  bool get hasChange => deltaAmount.abs() > 0.009;
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

  /// Obtiene el total gastado por categoría para un rango específico.
  Future<Map<String, double>> getSpendByCategoryForRange(
    String tenantId,
    DateTime start,
    DateTime end,
  ) async {
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

  /// Obtiene los totales de ingresos y gastos para un rango específico.
  Future<Map<String, double>> getTotalsForRange(
    String tenantId,
    DateTime start,
    DateTime end,
  ) async {
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

  /// Obtiene los gastos más grandes de un rango específico.
  Future<List<Transaction>> getTopExpensesForRange(
    String tenantId,
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) async {
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

  /// Obtiene el total de gastos del rango previo al rango de referencia.
  Future<double> getPreviousRangeExpenses(
    String tenantId, {
    required DateTime start,
    required DateTime end,
  }) async {
    final previousRange = _previousRange(start, end);
    final raw = await _client
        .from('transactions')
        .select('amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', previousRange.start.toIso8601String())
        .lt('date', previousRange.end.toIso8601String());

    return (raw as List).fold<double>(
      0,
      (sum, row) => sum + (row['amount'] as num).toDouble(),
    );
  }

  Future<List<SpendingTrend>> getSpendingTrendsForRange(
    String tenantId, {
    required DateTime start,
    required DateTime end,
  }) async {
    final previousRange = _previousRange(start, end);
    final currentSpend = await getSpendByCategoryForRange(tenantId, start, end);
    final previousSpend = await getSpendByCategoryForRange(
      tenantId,
      previousRange.start,
      previousRange.end,
    );

    final categories = <String>{
      ...currentSpend.keys,
      ...previousSpend.keys,
    };

    final trends = categories
        .map(
          (category) => SpendingTrend(
            category: category,
            currentAmount: currentSpend[category] ?? 0,
            previousAmount: previousSpend[category] ?? 0,
          ),
        )
        .where((trend) => trend.currentAmount > 0 || trend.previousAmount > 0)
        .where((trend) => trend.hasChange)
        .toList()
      ..sort((a, b) => b.deltaAmount.abs().compareTo(a.deltaAmount.abs()));

    return trends;
  }

  BudgetStatsRange _previousRange(DateTime start, DateTime end) {
    final duration = end.difference(start);
    return BudgetStatsRange(
      start: start.subtract(duration),
      end: end.subtract(duration),
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

final statsSpendByCategoryProvider = FutureProvider.autoDispose
    .family<Map<String, double>, ({String tenantId, BudgetStatsRange range})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getSpendByCategoryForRange(
          params.tenantId,
          params.range.start,
          params.range.end,
        );
  },
);

final statsTotalsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, ({String tenantId, BudgetStatsRange range})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getTotalsForRange(
          params.tenantId,
          params.range.start,
          params.range.end,
        );
  },
);

final statsTopExpensesProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ({String tenantId, BudgetStatsRange range})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getTopExpensesForRange(
          params.tenantId,
          params.range.start,
          params.range.end,
        );
  },
);

final statsPreviousExpensesProvider = FutureProvider.autoDispose
    .family<double, ({String tenantId, BudgetStatsRange range})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getPreviousRangeExpenses(
          params.tenantId,
          start: params.range.start,
          end: params.range.end,
        );
  },
);

final statsTrendsProvider = FutureProvider.autoDispose
    .family<List<SpendingTrend>, ({String tenantId, BudgetStatsRange range})>(
  (ref, params) {
    return ref.watch(budgetRepositoryProvider).getSpendingTrendsForRange(
          params.tenantId,
          start: params.range.start,
          end: params.range.end,
        );
  },
);
