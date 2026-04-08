class Account {
  final String id;
  final String tenantId;
  final String name;
  final String type; // 'cash' | 'bank' | 'credit_card'
  final double balance;

  Account({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.balance,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}
