import '../../../core/domain/app_categories.dart';

enum BillFrequency { monthly, weekly, yearly }

/// Modelo de pago recurrente almacenado en Supabase.
class BillModel {
  final String id;
  final String tenantId;
  final String name;
  final double amount;
  final int dueDay;
  final BillFrequency frequency;
  final String category;
  final String? accountId;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  const BillModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.frequency,
    required this.category,
    required this.accountId,
    required this.isActive,
    required this.notes,
    required this.createdAt,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDay: json['due_day'] as int,
      frequency: BillFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
      ),
      category: json['category'] as String? ?? 'bills',
      accountId: json['account_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'amount': amount,
      'due_day': dueDay,
      'frequency': frequency.name,
      'category': category,
      'account_id': accountId,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BillModel copyWith({
    String? id,
    String? tenantId,
    String? name,
    double? amount,
    int? dueDay,
    BillFrequency? frequency,
    String? category,
    String? accountId,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Fecha de vencimiento correspondiente al ciclo actual.
  DateTime get currentCycleDueDate {
    final now = DateTime.now();

    switch (frequency) {
      case BillFrequency.monthly:
        return DateTime(
          now.year,
          now.month,
          clampDay(now.year, now.month, dueDay),
        );
      case BillFrequency.weekly:
        final weekday = dueDay.clamp(1, 7);
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + (weekday - 1),
        );
      case BillFrequency.yearly:
        return DateTime(
          now.year,
          createdAt.month,
          clampDay(now.year, createdAt.month, dueDay),
        );
    }
  }

  /// Próxima fecha efectiva de vencimiento para agendar recordatorios.
  DateTime get nextDueDate {
    final now = DateTime.now();
    final current = currentCycleDueDate;

    if (!current.isBefore(DateTime(now.year, now.month, now.day))) {
      return current;
    }

    switch (frequency) {
      case BillFrequency.monthly:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          clampDay(nextMonth.year, nextMonth.month, dueDay),
        );
      case BillFrequency.weekly:
        return current.add(const Duration(days: 7));
      case BillFrequency.yearly:
        final nextYear = now.year + 1;
        return DateTime(
          nextYear,
          createdAt.month,
          clampDay(nextYear, createdAt.month, dueDay),
        );
    }
  }

  /// Días faltantes respecto al ciclo actual; si es negativo, ya venció.
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return currentCycleDueDate.difference(today).inDays;
  }

  bool get isUpcoming => daysUntilDue <= 7 && daysUntilDue >= 0;

  bool get isOverdue => daysUntilDue < 0;

  String get emoji {
    return AppCategories.emojiForId(category);
  }

  String get recurrenceLabel {
    switch (frequency) {
      case BillFrequency.monthly:
        return 'Día $dueDay de cada mes';
      case BillFrequency.weekly:
        return 'Cada ${_weekdayName(dueDay.clamp(1, 7))}';
      case BillFrequency.yearly:
        return 'Cada año el día $dueDay';
    }
  }

  static int clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day.clamp(1, lastDay);
  }

  static String _weekdayName(int weekday) {
    const weekdays = {
      1: 'lunes',
      2: 'martes',
      3: 'miércoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sábado',
      7: 'domingo',
    };
    return weekdays[weekday] ?? 'día';
  }
}
