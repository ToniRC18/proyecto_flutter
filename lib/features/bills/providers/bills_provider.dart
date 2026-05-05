import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/tenant_provider.dart';
import '../data/bills_repository.dart';
import '../domain/bill_model.dart';

final billsProvider = FutureProvider.autoDispose<List<BillModel>>((ref) async {
  final tenantId = await ref.watch(tenantProvider.future);
  return ref.watch(billsRepositoryProvider).getBills(tenantId);
});

final upcomingBillsProvider =
    Provider.autoDispose<AsyncValue<List<BillModel>>>((ref) {
  final billsAsync = ref.watch(billsProvider);

  return billsAsync.whenData(
    (bills) {
      final upcoming = bills
        .where((bill) => bill.isUpcoming && bill.isActive)
        .toList()
        ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
      return upcoming.take(5).toList();
    },
  );
});
