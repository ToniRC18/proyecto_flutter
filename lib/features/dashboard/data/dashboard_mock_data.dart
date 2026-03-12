import 'package:flutter_riverpod/flutter_riverpod.dart';

class PocketMock {
  final String name;
  final String emoji;
  final double currentAmount;
  final double goalAmount;

  PocketMock({
    required this.name,
    required this.emoji,
    required this.currentAmount,
    required this.goalAmount,
  });

  double get progress => (currentAmount / goalAmount).clamp(0.0, 1.0);
}

class UpcomingBillMock {
  final String name;
  final String emoji;
  final double amount;
  final DateTime date;

  UpcomingBillMock({
    required this.name,
    required this.emoji,
    required this.amount,
    required this.date,
  });
}

// Valores fijos de prueba
final mockAvailableNowProvider = Provider<double>((ref) => 12450.00);
final mockWeeklySpentProvider = Provider<double>((ref) => 3200.0);
final mockWeeklyLimitProvider = Provider<double>((ref) => 5000.0);

final mockPocketsProvider = Provider<List<PocketMock>>((ref) {
  return [
    PocketMock(name: 'Viaje', emoji: '✈️', currentAmount: 15000.0, goalAmount: 30000.0),
    PocketMock(name: 'Super', emoji: '🛒', currentAmount: 2000.0, goalAmount: 4000.0),
    PocketMock(name: 'Emergencia', emoji: '🚨', currentAmount: 8000.0, goalAmount: 10000.0),
  ];
});

final mockUpcomingBillsProvider = Provider<List<UpcomingBillMock>>((ref) {
  final now = DateTime.now();
  return [
    UpcomingBillMock(name: 'Renta', emoji: '🏠', amount: 8000.0, date: now.add(const Duration(days: 4))),
    UpcomingBillMock(name: 'Gym', emoji: '🏋️', amount: 600.0, date: now.add(const Duration(days: 6))),
    UpcomingBillMock(name: 'Internet', emoji: '📡', amount: 550.0, date: now.add(const Duration(days: 10))),
  ];
});
