import 'package:hive/hive.dart';

part 'cached_transaction.g.dart';

@HiveType(typeId: 11)
class CachedTransaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String accountId;

  @HiveField(2)
  late String tenantId;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late String type;

  @HiveField(5)
  late String category;

  @HiveField(6)
  late DateTime date;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  late DateTime cachedAt;

  @HiveField(9)
  late bool isPendingSync;

  @HiveField(10)
  String? transferId;
}
