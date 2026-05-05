import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../hive_boxes.dart';
import '../models/pending_operation.dart';

class OfflineQueueService {
  late Box<PendingOperation> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<PendingOperation>(HiveBoxes.pendingOperations);
  }

  Future<String> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final id = const Uuid().v4();
    final op = PendingOperation()
      ..id = id
      ..type = type
      ..payload = jsonEncode(payload)
      ..createdAt = DateTime.now()
      ..retryCount = 0
      ..status = 'pending';

    await _box.put(id, op);
    return id;
  }

  List<PendingOperation> getPending() {
    return _box.values
        .where((op) => op.status == 'pending' && op.retryCount < 3)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> markProcessing(String id) async {
    final op = _box.get(id);
    if (op != null) {
      op.status = 'processing';
      await op.save();
    }
  }

  Future<void> markCompleted(String id) async {
    await _box.delete(id);
  }

  Future<void> markFailed(String id, String error) async {
    final op = _box.get(id);
    if (op != null) {
      op.retryCount++;
      op.status = op.retryCount >= 3 ? 'failed' : 'pending';
      op.errorMessage = error;
      await op.save();
    }
  }

  int get pendingCount => getPending().length;

  List<PendingOperation> getFailed() {
    return _box.values.where((op) => op.status == 'failed').toList();
  }
}
