/// Modelo de miembro de un espacio compartido.
class SharedMember {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String role;         // 'owner' | 'member'
  final double totalSpent;  // calculado al cargar

  const SharedMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.totalSpent,
  });

  factory SharedMember.fromJson(Map<String, dynamic> json, {double totalSpent = 0}) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return SharedMember(
      userId: json['user_id'] as String,
      name: profile?['name'] as String? ?? 'Usuario',
      avatarUrl: profile?['avatar_url'] as String?,
      role: json['role'] as String,
      totalSpent: totalSpent,
    );
  }
}

/// Modelo ligero de un tenant compartido (para listas).
class SharedTenant {
  final String id;
  final String name;
  final int memberCount;
  final double totalThisMonth;

  const SharedTenant({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.totalThisMonth,
  });

  factory SharedTenant.fromJson(Map<String, dynamic> json) {
    return SharedTenant(
      id: json['id'] as String,
      name: json['name'] as String,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      totalThisMonth: (json['total_this_month'] as num?)?.toDouble() ?? 0,
    );
  }
}
