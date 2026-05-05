import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/split_repository.dart';
import '../domain/transaction_split_model.dart';

final splitsForTransactionProvider =
    FutureProvider.autoDispose.family<List<TransactionSplitModel>, String>(
  (ref, transactionId) async {
    return ref
        .watch(splitRepositoryProvider)
        .getSplitsForTransaction(transactionId);
  },
);

final tenantMembersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, tenantId) async {
    return ref.watch(splitRepositoryProvider).getMembersWithProfiles(tenantId);
  },
);
