class Account {
  final String id;
  final String tenantId;
  final String name;
  final String type; // 'cash' | 'bank' | 'credit_card'
  final double balance;
  final double? creditLimit;
  final int? billingCloseDay;
  final int? paymentDueDay;

  Account({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.balance,
    this.creditLimit,
    this.billingCloseDay,
    this.paymentDueDay,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      billingCloseDay: json['billing_close_day'] as int?,
      paymentDueDay: json['payment_due_day'] as int?,
    );
  }

  bool get isCreditCard => type == 'credit_card';

  double get availableCredit {
    final available = (creditLimit ?? 0) - balance;
    return available < 0 ? 0 : available;
  }

  double get usagePercent {
    if (creditLimit == null || creditLimit! <= 0) return 0.0;
    return (balance / creditLimit!).clamp(0.0, 1.0);
  }
}
