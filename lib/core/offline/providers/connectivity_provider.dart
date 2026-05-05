import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/tenant_provider.dart';
import '../../../features/accounts/data/accounts_repository.dart';
import '../../../features/dashboard/data/dashboard_repository.dart';
import '../../../features/transactions/data/transaction_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import 'offline_queue_provider.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

final isOnlineSyncProvider = Provider<bool>((ref) {
  return ref.watch(isOnlineProvider).maybeWhen(
        data: (online) => online,
        orElse: () => true,
      );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(offlineQueueServiceProvider),
    ref.read(hiveCacheServiceProvider),
    Supabase.instance.client,
  );
});

final connectivitySyncListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) async {
    final wasOnline = previous?.asData?.value ?? true;
    final isOnline = next.asData?.value;
    if (isOnline != true || wasOnline) return;

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncPendingOperations();

      final activeTenant = ref.read(activeTenantProvider).valueOrNull;
      final String tenantId =
          activeTenant?.id ?? await ref.read(tenantProvider.future);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        await syncService.refreshCache(
          tenantId: tenantId,
          userId: userId,
        );
      }

      ref.invalidate(accountsProvider(tenantId));
      ref.invalidate(allAccountsProvider(tenantId));
      ref.invalidate(totalBalanceProvider(tenantId));
      ref.invalidate(availableBalanceProvider(tenantId));
      ref.invalidate(recentTransactionsProvider(tenantId));
      ref.invalidate(weeklySpendProvider(tenantId));
    } catch (error, stackTrace) {
      debugPrint('Error al sincronizar al reconectarse: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  });
});
