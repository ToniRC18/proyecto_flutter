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
      case 'create_split':
        final splits = List<Map<String, dynamic>>.from(
          payload['splits'] as List<dynamic>,
        );
        await _supabase.from('transaction_splits').insert(splits);
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
