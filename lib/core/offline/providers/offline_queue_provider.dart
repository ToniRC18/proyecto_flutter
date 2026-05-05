import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../hive_boxes.dart';
import '../services/hive_cache_service.dart';
import '../services/offline_queue_service.dart';

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

final hiveCacheServiceProvider = Provider<HiveCacheService>((ref) {
  return HiveCacheService();
});

final pendingOperationsTickProvider = StreamProvider<int>((ref) async* {
  final box = Hive.box(HiveBoxes.pendingOperations);
  yield 0;
  await for (final _ in box.watch()) {
    yield DateTime.now().microsecondsSinceEpoch;
  }
});

final pendingOperationsCountProvider = Provider<int>((ref) {
  ref.watch(pendingOperationsTickProvider);
  final queue = ref.watch(offlineQueueServiceProvider);
  return queue.pendingCount;
});
