/// Modelo de invitación a un tenant compartido.
class TenantInvitation {
  final String id;
  final String tenantId;
  final String tenantName;   // nombre del espacio compartido
  final String invitedBy;    // nombre de quien invitó
  final String invitedEmail;
  final String status;       // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  const TenantInvitation({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.invitedBy,
    required this.invitedEmail,
    required this.status,
    required this.createdAt,
  });

  factory TenantInvitation.fromJson(Map<String, dynamic> json) {
    // El JOIN con tenants y profiles se resuelve en el repositorio
    final tenantData = json['tenants'] as Map<String, dynamic>?;
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return TenantInvitation(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      tenantName: tenantData?['name'] as String? ?? 'Espacio compartido',
      invitedBy: profileData?['name'] as String? ?? 'Alguien',
      invitedEmail: json['invited_email'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
