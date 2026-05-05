import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pending_operation.dart';
import 'hive_cache_service.dart';
import 'offline_queue_service.dart';

class SyncService {
  final OfflineQueueService _queue;
  final HiveCacheService _cache;
  final SupabaseClient _supabase;

  SyncService(this._queue, this._cache, this._supabase);

  Future<void> syncPendingOperations() async {
    final pending = _queue.getPending();
    if (pending.isEmpty) return;

    for (final op in pending) {
      await _queue.markProcessing(op.id);
      try {
        await _executeOperation(op);
        await _queue.markCompleted(op.id);
      } catch (error) {
        await _queue.markFailed(op.id, error.toString());
      }
    }

    await _cache.setLastSync(DateTime.now());
  }

  Future<void> _executeOperation(PendingOperation op) async {
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;

    switch (op.type) {
      case 'create_transaction':
        await _supabase.from('transactions').insert(payload);
        break;
      case 'create_transfer':
        final out = payload['transfer_out'] as Map<String, dynamic>;
        final inn = payload['transfer_in'] as Map<String, dynamic>;
        await _supabase.from('transactions').insert(out);
        await _supabase.from('transactions').insert(inn);
        break;
      case 'mark_bill_paid':
        await _supabase.from('bill_payments').insert(payload);
        break;
      case 'create_splits':
        final splits = List<Map<String, dynamic>>.from(
          payload['splits'] as List<dynamic>,
        );
        await _supabase.from('transaction_splits').insert(splits);
        break;
      case 'pay_bill':
        try {
          final billId =
              payload['billId'] as String? ??
              (payload['bill_payment'] as Map<String, dynamic>?)?['bill_id']
                  as String?;
          final amountRaw =
              payload['amount'] ??
              (payload['bill_payment'] as Map<String, dynamic>?)?['amount'];
          final accountId =
              payload['accountId'] as String? ??
              (payload['transaction'] as Map<String, dynamic>?)?['account_id']
                  as String?;
          final tenantId =
              payload['tenantId'] as String? ??
              (payload['transaction'] as Map<String, dynamic>?)?['tenant_id']
                  as String? ??
              (payload['bill'] as Map<String, dynamic>?)?['tenant_id'] as String?;

          if (billId == null || amountRaw == null || accountId == null || tenantId == null) {
            throw Exception('Payload inválido para pay_bill');
          }

          final amount = (amountRaw as num).toDouble();
          final bill = await _supabase
              .from('bills')
              .select()
              .eq('id', billId)
              .maybeSingle();

          if (bill == null) {
            throw Exception('Bill no encontrada');
          }

          if (bill['is_active'] != true) {
            break;
          }

          await _supabase.from('bill_payments').insert({
            'bill_id': billId,
            'amount': amount,
            'paid_at': DateTime.now().toIso8601String(),
          });

          await _supabase.from('transactions').insert({
            'tenant_id': tenantId,
            'account_id': accountId,
            'type': 'expense',
            'amount': amount,
            'category': (bill['category'] as String?) ?? 'servicios',
            'notes': 'Pago: ${bill['name']}',
            'date': DateTime.now().toIso8601String(),
          });

          final accountData = await _supabase
              .from('accounts')
              .select('balance')
              .eq('id', accountId)
              .single();
          final currentBalance = (accountData['balance'] as num).toDouble();

          await _supabase
              .from('accounts')
              .update({'balance': currentBalance - amount})
              .eq('id', accountId);
        } catch (_) {
          rethrow;
        }
        break;
      default:
        throw Exception('Tipo de operación desconocido: ${op.type}');
    }
  }

  Future<void> refreshCache({
    required String tenantId,
    required String userId,
  }) async {
    final transactions = await _supabase
        .from('transactions')
        .select()
        .eq('tenant_id', tenantId)
        .order('date', ascending: false)
        .limit(100);

    await _cache.cacheTransactions(
      List<Map<String, dynamic>>.from(transactions as List),
    );

    final accounts = await _supabase
        .from('accounts')
        .select()
        .eq('tenant_id', tenantId);

    await _cache.cacheAccounts(
      List<Map<String, dynamic>>.from(accounts as List),
    );

    await _cache.setLastSync(DateTime.now());
  }
}
