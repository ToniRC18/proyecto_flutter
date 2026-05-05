import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transfer_repository.dart';

/// Controla el estado asíncrono del submit de transferencia.
class TransferController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TransferController(this._ref) : super(const AsyncData(null));

  Future<void> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String tenantId,
    String? notes,
    DateTime? date,
  }) async {
    state = const AsyncLoading();

    try {
      await _ref.read(transferRepositoryProvider).createTransfer(
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            amount: amount,
            tenantId: tenantId,
            notes: notes,
            date: date,
          );

      _ref.read(transferRefreshProvider)(tenantId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final transferControllerProvider =
    StateNotifierProvider.autoDispose<TransferController, AsyncValue<void>>(
  (ref) => TransferController(ref),
);
