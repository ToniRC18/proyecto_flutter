/// Modelo de comentario en una transacción.
class TransactionComment {
  final String id;
  final String transactionId;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;

  const TransactionComment({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory TransactionComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TransactionComment(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      userId: json['user_id'] as String,
      authorName: profile?['name'] as String? ?? 'Usuario',
      authorAvatar: profile?['avatar_url'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
