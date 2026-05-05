import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/providers/connectivity_provider.dart';
import '../../../core/offline/providers/offline_queue_provider.dart';
import '../../../core/offline/services/connectivity_service.dart';
import '../../../core/offline/services/offline_queue_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/domain/account_model.dart';
import '../domain/bill_model.dart';

/// Repositorio para CRUD de pagos recurrentes y registro de pagos.
class BillsRepository {
  final SupabaseClient _client;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _queueService;
  final Uuid _uuid;

  BillsRepository(
    this._client,
    this._connectivityService,
    this._queueService, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  Future<List<BillModel>> getBills(String tenantId) async {
    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .order('due_day', ascending: true);

      return (response as List)
          .map((json) => BillModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception('No se pudieron cargar los pagos recurrentes.');
    }
  }

  Future<void> createBill(BillModel bill) async {
    try {
      await _client.from('bills').insert(bill.toJson()..remove('id'));
    } catch (_) {
      throw Exception('No se pudo crear el pago recurrente.');
    }
  }

  Future<void> updateBill(BillModel bill) async {
    try {
      await _client
          .from('bills')
          .update(
            bill.toJson()
              ..remove('id')
              ..remove('created_at'),
          )
          .eq('id', bill.id);
    } catch (_) {
      throw Exception('No se pudo actualizar el pago recurrente.');
    }
  }

  Future<void> deleteBill(String billId) async {
    try {
      await _client.from('bills').update({'is_active': false}).eq('id', billId);
    } catch (_) {
      throw Exception('No se pudo eliminar el pago recurrente.');
    }
  }

  Future<void> markAsPaid({
    required String billId,
    required double amount,
    String? transactionId,
  }) async {
    try {
      await _client.from('bill_payments').insert({
        'bill_id': billId,
        'amount': amount,
        'transaction_id': transactionId,
      });
    } catch (_) {
      throw Exception('No se pudo registrar el pago del bill.');
    }
  }

  Future<List<Account>> getAccounts(String tenantId) async {
    try {
      final response = await _client
          .from('accounts')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Account.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception('No se pudieron cargar las cuentas del usuario.');
    }
  }

  /// Registra el pago del bill y crea una transacción si el bill tiene cuenta.
  Future<void> payBill({
    required BillModel bill,
  }) async {
    final now = DateTime.now();
    final offlineTransactionId = bill.accountId != null ? _uuid.v4() : null;
    final transactionPayload = bill.accountId == null
        ? null
        : <String, dynamic>{
            'id': offlineTransactionId,
            'tenant_id': bill.tenantId,
            'account_id': bill.accountId,
            'amount': bill.amount,
            'type': 'expense',
            'category': bill.category,
            'notes': 'Pago de bill: ${bill.name}',
            'date': now.toIso8601String(),
          };
    final paymentPayload = <String, dynamic>{
      'bill_id': bill.id,
      'amount': bill.amount,
      'transaction_id': offlineTransactionId,
      'paid_at': now.toIso8601String(),
    };

    if (_connectivityService.isOnline) {
      try {
        await _payBillOnline(
          bill: bill,
          paymentDate: now,
        );
        return;
      } catch (error) {
        if (!_shouldFallbackOffline(error)) {
          throw Exception('No se pudo marcar el bill como pagado.');
        }
      }
    }

    await _queueService.enqueue(
      type: 'pay_bill',
      payload: {
        'bill': bill.toJson(),
        'bill_payment': paymentPayload,
        'transaction': transactionPayload,
      },
    );
  }

  /// Ejecuta el pago completo contra Supabase cuando hay conexión.
  Future<void> _payBillOnline({
    required BillModel bill,
    required DateTime paymentDate,
  }) async {
    String? transactionId;
    double? previousBalance;

    try {
      if (bill.accountId != null) {
        final accountData = await _client
            .from('accounts')
            .select('balance')
            .eq('id', bill.accountId!)
            .single();

        previousBalance = (accountData['balance'] as num).toDouble();
        final transactionResponse = await _client
            .from('transactions')
            .insert({
              'tenant_id': bill.tenantId,
              'account_id': bill.accountId,
              'amount': bill.amount,
              'type': 'expense',
              'category': bill.category,
              'notes': 'Pago de bill: ${bill.name}',
              'date': paymentDate.toIso8601String(),
            })
            .select('id')
            .single();

        transactionId = transactionResponse['id'] as String;

        await _client
            .from('accounts')
            .update({'balance': previousBalance - bill.amount}).eq(
                'id', bill.accountId!);
      }

      await markAsPaid(
        billId: bill.id,
        amount: bill.amount,
        transactionId: transactionId,
      );
    } catch (_) {
      await _rollbackPayment(
        bill: bill,
        transactionId: transactionId,
        previousBalance: previousBalance,
      );
      rethrow;
    }
  }

  Future<void> _rollbackPayment({
    required BillModel bill,
    required String? transactionId,
    required double? previousBalance,
  }) async {
    try {
      if (transactionId != null) {
        await _client.from('transactions').delete().eq('id', transactionId);
      }

      if (bill.accountId != null && previousBalance != null) {
        await _client
            .from('accounts')
            .update({'balance': previousBalance}).eq('id', bill.accountId!);
      }
    } catch (_) {
      // Se conserva el error principal para el usuario.
    }
  }

  bool _shouldFallbackOffline(Object error) {
    final message = error.toString().toLowerCase();
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('timed out');
  }

  BillModel buildNewBill({
    required String tenantId,
    required String name,
    required double amount,
    required int dueDay,
    required BillFrequency frequency,
    required String category,
    String? accountId,
    String? notes,
  }) {
    return BillModel(
      id: _uuid.v4(),
      tenantId: tenantId,
      name: name,
      amount: amount,
      dueDay: dueDay,
      frequency: frequency,
      category: category,
      accountId: accountId,
      isActive: true,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  return BillsRepository(
    supabase,
    ref.read(connectivityServiceProvider),
    ref.read(offlineQueueServiceProvider),
  );
});
