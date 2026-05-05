import 'package:hive/hive.dart';

part 'cached_account.g.dart';

@HiveType(typeId: 12)
class CachedAccount extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String tenantId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String type;

  @HiveField(4)
  late double balance;

  @HiveField(5)
  late DateTime cachedAt;

  @HiveField(6)
  double? creditLimit;

  @HiveField(7)
  int? billingCloseDay;

  @HiveField(8)
  int? paymentDueDay;
}
