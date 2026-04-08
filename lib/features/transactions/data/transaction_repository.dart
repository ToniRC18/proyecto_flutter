import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/domain/account_model.dart';
import '../domain/transaction_model.dart';

class TransactionRepository {
  /// Obtiene las cuentas disponibles del tenant
  Future<List<Account>> getAccounts(String tenantId) async {
    final response = await supabase
        .from('accounts')
        .select()
        .eq('tenant_id', tenantId);
    
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Account.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Guarda un gasto: 
  /// 1. Inserta la transacción
  /// 2. Actualiza el balance de la cuenta
  Future<void> saveExpense({
    required String tenantId,
    required String accountId,
    required double amount,
    required String category,
    String? notes,
  }) async {
    // 1. Insertar transacción
    await supabase.from('transactions').insert({
      'tenant_id': tenantId,
      'account_id': accountId,
      'amount': amount,
      'type': 'expense',
      'category': category,
      'notes': notes,
      'date': DateTime.now().toIso8601String(),
    });

    // 2. Obtener balance actual para restar
    final accountData = await supabase
        .from('accounts')
        .select('balance')
        .eq('id', accountId)
        .single();
    
    final currentBalance = (accountData['balance'] as num).toDouble();
    final newBalance = currentBalance - amount;

    // 3. Actualizar cuenta
    await supabase
        .from('accounts')
        .update({'balance': newBalance})
        .eq('id', accountId);
  }

  /// Guarda un ingreso:
  /// 1. Inserta la transacción con type 'income'
  /// 2. Suma el monto al balance de la cuenta
  Future<void> saveIncome({
    required String tenantId,
    required String accountId,
    required double amount,
    required String category,
    String? notes,
  }) async {
    // 1. Insertar transacción
    await supabase.from('transactions').insert({
      'tenant_id': tenantId,
      'account_id': accountId,
      'amount': amount,
      'type': 'income',
      'category': category,
      'notes': notes,
      'date': DateTime.now().toIso8601String(),
    });

    // 2. Obtener balance actual para sumar
    final accountData = await supabase
        .from('accounts')
        .select('balance')
        .eq('id', accountId)
        .single();

    final currentBalance = (accountData['balance'] as num).toDouble();
    final newBalance = currentBalance + amount;

    // 3. Actualizar cuenta
    await supabase
        .from('accounts')
        .update({'balance': newBalance})
        .eq('id', accountId);
  }
}

final transactionRepositoryProvider = Provider((ref) => TransactionRepository());

final accountsProvider = FutureProvider.family<List<Account>, String>((ref, tenantId) async {
  return ref.watch(transactionRepositoryProvider).getAccounts(tenantId);
});
