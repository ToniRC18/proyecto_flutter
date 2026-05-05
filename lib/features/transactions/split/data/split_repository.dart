import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/offline/providers/connectivity_provider.dart';
import '../../../../core/offline/providers/offline_queue_provider.dart';
import '../../../../core/offline/services/connectivity_service.dart';
import '../../../../core/offline/services/offline_queue_service.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../domain/transaction_split_model.dart';

class SplitRepository {
  final SupabaseClient _client;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _queueService;
  final Uuid _uuid;

  SplitRepository(
    this._client,
    this._connectivityService,
    this._queueService, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  Future<void> createSplits({
    required String transactionId,
    required List<TransactionSplitModel> splits,
  }) async {
    if (splits.isEmpty) return;

    // Se serializan una sola vez para reutilizarlos online u offline.
    final payload = splits
        .map(
          (split) => {
            'id': split.id.isEmpty ? _uuid.v4() : split.id,
            'transaction_id': transactionId,
            'user_id': split.userId,
            'amount': split.amount,
            'is_settled': split.isSettled,
            'settled_at': split.settledAt?.toIso8601String(),
          },
        )
        .toList();

    if (_connectivityService.isOnline) {
      try {
        await _client.from('transaction_splits').insert(payload);
        return;
      } catch (error) {
        if (!_shouldFallbackOffline(error)) {
          throw Exception('No se pudieron guardar las divisiones del gasto.');
        }
      }
    }

    try {
      await _queueService.enqueue(
        type: 'create_splits',
        payload: {
          'transactionId': transactionId,
          'splits': payload,
        },
      );
    } catch (_) {
      throw Exception('No se pudieron guardar las divisiones del gasto.');
    }
  }

  Future<List<TransactionSplitModel>> getSplitsForTransaction(
    String transactionId,
  ) async {
    try {
      final rawSplits = await _client
          .from('transaction_splits')
          .select()
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: true);

      final splits = (rawSplits as List)
          .map((json) =>
              TransactionSplitModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (splits.isEmpty) return [];

      final userIds = splits.map((split) => split.userId).toSet().toList();
      final profilesRaw = await _client
          .from('profiles')
          .select('id, name, avatar_url')
          .inFilter('id', userIds);

      final profiles = {
        for (final profile in (profilesRaw as List))
          profile['id'] as String: profile as Map<String, dynamic>,
      };

      return splits.map((split) {
        final profile = profiles[split.userId];
        return split.copyWith(
          profileName: profile?['name'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
        );
      }).toList();
    } catch (_) {
      throw Exception('No se pudieron cargar las divisiones del gasto.');
    }
  }

  Future<void> settleSplit(String splitId) async {
    try {
      await _client.from('transaction_splits').update({
        'is_settled': true,
        'settled_at': DateTime.now().toIso8601String(),
      }).eq('id', splitId);
    } catch (_) {
      throw Exception('No se pudo marcar la división como saldada.');
    }
  }

  Future<List<Map<String, dynamic>>> getMembersWithProfiles(
      String tenantId) async {
    try {
      final rawMembers = await _client
          .from('tenant_members')
          .select('user_id, profiles(name, avatar_url)')
          .eq('tenant_id', tenantId);

      return (rawMembers as List).map((member) {
        final data = member as Map<String, dynamic>;
        final profile = data['profiles'] as Map<String, dynamic>?;
        return {
          'userId': data['user_id'] as String,
          'name': profile?['name'] as String? ?? 'Miembro',
          'avatarUrl': profile?['avatar_url'] as String?,
        };
      }).toList();
    } catch (_) {
      throw Exception(
          'No se pudieron cargar los miembros del espacio compartido.');
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
}

final splitRepositoryProvider = Provider<SplitRepository>((ref) {
  return SplitRepository(
    supabase,
    ref.read(connectivityServiceProvider),
    ref.read(offlineQueueServiceProvider),
  );
});
