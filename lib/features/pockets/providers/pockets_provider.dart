import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/data/accounts_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../data/pockets_repository.dart';
import '../domain/pocket_model.dart';

final pocketsProvider =
    FutureProvider.family<List<PocketModel>, String>((ref, tenantId) async {
  return ref.watch(pocketsRepositoryProvider).getPockets(tenantId);
});

final pocketAccountsProvider =
    FutureProvider.family<List<Account>, String>((ref, tenantId) async {
  return ref.watch(allAccountsProvider(tenantId).future);
});
