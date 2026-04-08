class Transaction {
  final String id;
  final String accountId;
  final String tenantId;
  final double amount;
  final String type; // 'expense' | 'income'
  final String category;
  final String? notes;
  final DateTime date;

  Transaction({
    required this.id,
    required this.accountId,
    required this.tenantId,
    required this.amount,
    required this.type,
    required this.category,
    this.notes,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      tenantId: json['tenant_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      notes: json['notes'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'tenant_id': tenantId,
      'amount': amount,
      'type': type,
      'category': category,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }
}
