class PocketModel {
  final String id;
  final String tenantId;
  final String name;
  final String emoji;
  final double goalAmount;
  final double savedAmount;
  final String color;
  final bool storedIsCompleted;
  final DateTime createdAt;

  const PocketModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.emoji,
    required this.goalAmount,
    required this.savedAmount,
    required this.color,
    required this.storedIsCompleted,
    required this.createdAt,
  });

  factory PocketModel.fromJson(Map<String, dynamic> json) {
    return PocketModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🎯',
      goalAmount: (json['goal_amount'] as num).toDouble(),
      savedAmount: (json['saved_amount'] as num).toDouble(),
      color: json['color'] as String? ?? '#5F4A8B',
      storedIsCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'emoji': emoji,
      'goal_amount': goalAmount,
      'saved_amount': savedAmount,
      'color': color,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get progress =>
      goalAmount <= 0 ? 0.0 : (savedAmount / goalAmount).clamp(0.0, 1.0);

  bool get isCompleted => storedIsCompleted || savedAmount >= goalAmount;
}
