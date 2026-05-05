import 'package:hive/hive.dart';

part 'pending_operation.g.dart';

@HiveType(typeId: 10)
class PendingOperation extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String type;

  @HiveField(2)
  late String payload;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late int retryCount;

  @HiveField(5)
  late String status;

  @HiveField(6)
  String? errorMessage;
}
