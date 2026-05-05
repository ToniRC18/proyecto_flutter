class MsiPlanModel {
  final String id;
  final String accountId;
  final String tenantId;
  final String storeName;
  final double totalAmount;
  final int monthsTotal;
  final int monthsPaid;
  final DateTime startDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  MsiPlanModel({
    required this.id,
    required this.accountId,
    required this.tenantId,
    required this.storeName,
    required this.totalAmount,
    required this.monthsTotal,
    required this.monthsPaid,
    required this.startDate,
    required this.isActive,
    required this.notes,
    required this.createdAt,
  });

  factory MsiPlanModel.fromJson(Map<String, dynamic> json) {
    return MsiPlanModel(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      tenantId: json['tenant_id'] as String,
      storeName: json['store_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      monthsTotal: json['months_total'] as int,
      monthsPaid: json['months_paid'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'tenant_id': tenantId,
      'store_name': storeName,
      'total_amount': totalAmount,
      'months_total': monthsTotal,
      'months_paid': monthsPaid,
      'start_date': startDate.toIso8601String().split('T').first,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get monthlyAmount => totalAmount / monthsTotal;

  int get monthsRemaining => monthsTotal - monthsPaid;

  double get amountRemaining => monthlyAmount * monthsRemaining;

  bool get isCompleted => monthsPaid >= monthsTotal;
}
