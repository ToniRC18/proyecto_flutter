import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_model.dart';

final mockTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final now = DateTime.now();
  return [
    TransactionModel(
      id: '1',
      amount: 450.0,
      category: 'Comida',
      categoryEmoji: '🍔',
      date: now.subtract(const Duration(hours: 2)),
      type: 'expense',
      account: 'Main Pocket',
    ),
    TransactionModel(
      id: '2',
      amount: 120.0,
      category: 'Transporte',
      categoryEmoji: '🚗',
      date: now.subtract(const Duration(days: 1)),
      type: 'expense',
      account: 'Main Pocket',
    ),
    TransactionModel(
      id: '3',
      amount: 8000.0,
      category: 'Renta',
      categoryEmoji: '🏠',
      date: now.subtract(const Duration(days: 2)),
      type: 'expense',
      account: 'Main Pocket',
    ),
    TransactionModel(
      id: '4',
      amount: 650.0,
      category: 'Ocio',
      categoryEmoji: '🎮',
      date: now.subtract(const Duration(days: 3)),
      type: 'expense',
      account: 'Main Pocket',
    ),
    TransactionModel(
      id: '5',
      amount: 1200.0,
      category: 'Super',
      categoryEmoji: '🛒',
      date: now.subtract(const Duration(days: 4)),
      type: 'expense',
      account: 'Main Pocket',
    ),
  ];
});
