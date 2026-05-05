class TransactionSplitModel {
  final String id;
  final String transactionId;
  final String userId;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;
  final DateTime createdAt;
  final String? profileName;
  final String? avatarUrl;

  const TransactionSplitModel({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.isSettled,
    required this.settledAt,
    required this.createdAt,
    this.profileName,
    this.avatarUrl,
  });

  factory TransactionSplitModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return TransactionSplitModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String? ?? '',
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      isSettled: json['is_settled'] as bool? ?? false,
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'] as String)
          : null,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      profileName: profile?['name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      'amount': amount,
      'is_settled': isSettled,
      'settled_at': settledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransactionSplitModel copyWith({
    String? id,
    String? transactionId,
    String? userId,
    double? amount,
    bool? isSettled,
    DateTime? settledAt,
    bool clearSettledAt = false,
    DateTime? createdAt,
    String? profileName,
    String? avatarUrl,
  }) {
    return TransactionSplitModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledAt: clearSettledAt ? null : settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
      profileName: profileName ?? this.profileName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Nombre listo para pintar en UI aunque el perfil no se haya cargado.
  String get displayName {
    final clean = profileName?.trim();
    if (clean == null || clean.isEmpty) return 'Miembro';
    return clean;
  }
}
