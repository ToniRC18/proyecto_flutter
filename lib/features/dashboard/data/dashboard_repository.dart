import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../transactions/domain/transaction_model.dart';

class DashboardRepository {
  /// Obtiene el balance disponible sumando todas las cuentas del tenant
  Future<double> getAvailableBalance(String tenantId) async {
    final response = await supabase
        .from('accounts')
        .select('balance')
        .eq('tenant_id', tenantId);
    
    final List<dynamic> data = response as List<dynamic>;
    return data.fold<double>(0.0, (sum, item) => sum + (item['balance'] as num).toDouble());
  }

  /// Obtiene las últimas 10 transacciones del tenant
  Future<List<Transaction>> getRecentTransactions(String tenantId) async {
    final response = await supabase
        .from('transactions')
        .select()
        .eq('tenant_id', tenantId)
        .order('date', ascending: false)
        .limit(10);
    
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Calcula el gasto semanal (últimos 7 días)
  Future<Map<String, double>> getWeeklySpend(String tenantId) async {
    final lastWeek = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    
    final response = await supabase
        .from('transactions')
        .select('amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', lastWeek);
    
    final List<dynamic> data = response as List<dynamic>;
    final totalSpent = data.fold<double>(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
    
    return {
      'spent': totalSpent,
      'limit': 5000.0, // Límite hardcodeado por ahora
    };
  }

  /// Obtiene el nombre del perfil del usuario
  Future<String> getUserName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return '';
    
    final response = await supabase
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .single();
    
    return response['name'] as String? ?? 'Usuario';
  }

  /// Obtiene los presupuestos (pockets) del tenant
  Future<List<Budget>> getBudgets(String tenantId) async {
    final response = await supabase
        .from('budgets')
        .select()
        .eq('tenant_id', tenantId);
    
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Budget.fromJson(json as Map<String, dynamic>)).toList();
  }
}

class Budget {
  final String id;
  final String category;
  final double amount;
  final String period;

  Budget({required this.id, required this.category, required this.amount, required this.period});

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
    );
  }

  String get emoji {
    const mapping = {
      'viaje': '✈️',
      'super': '🛒',
      'comida': '🍔',
      'renta': '🏠',
      'salud': '💊',
      'ocio': '🎮',
    };
    return mapping[category.toLowerCase()] ?? '💰';
  }
}

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final availableBalanceProvider = FutureProvider.family<double, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getAvailableBalance(tenantId);
});

final recentTransactionsProvider = FutureProvider.family<List<Transaction>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getRecentTransactions(tenantId);
});

final weeklySpendProvider = FutureProvider.family<Map<String, double>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getWeeklySpend(tenantId);
});

final budgetsProvider = FutureProvider.family<List<Budget>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getBudgets(tenantId);
});

final userNameProvider = FutureProvider<String>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getUserName();
});
