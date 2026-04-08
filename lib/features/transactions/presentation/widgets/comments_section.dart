import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/comments_repository.dart';
import '../../domain/transaction_comment_model.dart';

/// Widget que muestra y permite agregar comentarios a una transacción.
/// Usa Supabase Realtime para actualización en tiempo real.
class CommentsSection extends ConsumerStatefulWidget {
  final String transactionId;
  const CommentsSection({super.key, required this.transactionId});

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviarComentario() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await ref
          .read(commentsRepositoryProvider)
          .addComment(widget.transactionId, text);

      _controller.clear();

      // Scroll al final después de enviar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al enviar comentario: $e',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync =
        ref.watch(commentsStreamProvider(widget.transactionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Título de la sección ─────────────────────────────────
        commentsAsync.when(
          data: (comments) => _SectionTitle(count: comments.length),
          loading: () => const _SectionTitle(count: 0),
          error: (_, __) => const _SectionTitle(count: 0),
        ),
        const SizedBox(height: 12),

        // ── Lista de comentarios ─────────────────────────────────
        commentsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error al cargar comentarios',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Sé el primero en comentar 💬',
                    style: GoogleFonts.poppins(color: AppColors.textLight),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 260,
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, i) =>
                    _CommentBubble(comment: comments[i]),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // ── Input de nuevo comentario ────────────────────────────
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: 20,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Agrega un comentario...',
                    hintStyle:
                        GoogleFonts.poppins(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  style:
                      GoogleFonts.poppins(color: AppColors.textPrimary),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviarComentario(),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              GestureDetector(
                onTap: _sending ? null : _enviarComentario,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _sending
                        ? AppColors.primary.withAlpha(80)
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Título de sección ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final int count;
  const _SectionTitle({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Comentarios',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Burbuja de comentario ────────────────────────────────────────────────────

class _CommentBubble extends StatelessWidget {
  final TransactionComment comment;
  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(comment.authorName);
    final relativeDate = _relativeDate(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar circular con iniciales
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: comment.authorAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        comment.authorAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsWidget(initials),
                      ),
                    )
                  : _initialsWidget(initials),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + fecha
                  Row(
                    children: [
                      Text(
                        comment.authorName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        relativeDate,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Contenido del comentario
                  Text(
                    comment.content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Genera las iniciales del nombre (máx 2).
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Devuelve una cadena de fecha relativa amigable.
  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}
