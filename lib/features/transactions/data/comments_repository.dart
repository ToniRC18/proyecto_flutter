import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart' as sc;
import '../domain/transaction_comment_model.dart';

/// Repositorio de comentarios en transacciones.
/// Soporta lectura paginada y streaming en tiempo real con Supabase Realtime.
class CommentsRepository {
  final SupabaseClient _client;
  CommentsRepository(this._client);

  /// Obtiene todos los comentarios de una transacción (ASC por fecha).
  Future<List<TransactionComment>> getComments(String transactionId) async {
    try {
      final raw = await _client
          .from('transaction_comments')
          .select('id, transaction_id, user_id, content, created_at, profiles(name, avatar_url)')
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: true);

      return (raw as List)
          .map((json) => TransactionComment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar comentarios: $e');
    }
  }

  /// Agrega un comentario a una transacción.
  Future<void> addComment(String transactionId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    try {
      await _client.from('transaction_comments').insert({
        'transaction_id': transactionId,
        'user_id': userId,
        'content': content.trim(),
      });
    } catch (e) {
      throw Exception('Error al agregar comentario: $e');
    }
  }

  /// Stream con Supabase Realtime de comentarios de una transacción.
  /// Se actualiza automáticamente cuando se inserta un nuevo comentario.
  Stream<List<TransactionComment>> watchComments(String transactionId) {
    return _client
        .from('transaction_comments')
        .stream(primaryKey: ['id'])
        .eq('transaction_id', transactionId)
        .order('created_at')
        .map((rows) => rows
            .map((json) => TransactionComment.fromJson(json))
            .toList());
  }

  /// Obtiene la cantidad de comentarios de una transacción (para el badge).
  Future<int> getCommentCount(String transactionId) async {
    try {
      final raw = await _client
          .from('transaction_comments')
          .select('id')
          .eq('transaction_id', transactionId);
      return (raw as List).length;
    } catch (_) {
      return 0;
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  return CommentsRepository(sc.supabase);
});

/// Provider del stream de comentarios para una transacción (tiempo real).
final commentsStreamProvider = StreamProvider.autoDispose
    .family<List<TransactionComment>, String>((ref, transactionId) {
  return ref.watch(commentsRepositoryProvider).watchComments(transactionId);
});

/// Provider del conteo de comentarios por transacción.
final commentCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, transactionId) async {
  return ref.watch(commentsRepositoryProvider).getCommentCount(transactionId);
});
