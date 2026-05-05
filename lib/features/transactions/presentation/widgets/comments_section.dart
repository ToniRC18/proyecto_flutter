import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
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
        final b = context.bruma;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al enviar comentario: $e',
              style: GoogleFonts.dmSans()),
          backgroundColor: b.error,
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
    final b = context.bruma;
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
          loading: () => Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error al cargar comentarios',
                style: GoogleFonts.dmSans(color: b.textSecondary)),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Sé el primero en comentar 💬',
                    style: GoogleFonts.dmSans(color: b.textTertiary),
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
        AppCard(
          padding: 12,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Agrega un comentario...',
                    hintStyle:
                        GoogleFonts.dmSans(color: b.textTertiary),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  style:
                      GoogleFonts.dmSans(color: b.textPrimary),
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
                        ? b.primary.withValues(alpha: 0.4)
                        : b.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(Icons.send_rounded,
                          color: b.onPrimary, size: 18),
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
    final b = context.bruma;
    return Row(
      children: [
        Text(
          'Comentarios',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: b.textPrimary,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: b.primary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: b.onPrimary,
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
    final b = context.bruma;
    final initials = _initials(comment.authorName);
    final relativeDate = _relativeDate(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: 12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar circular con iniciales
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: b.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: comment.authorAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        comment.authorAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsWidget(initials, b),
                      ),
                    )
                  : _initialsWidget(initials, b),
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
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: b.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        relativeDate,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: b.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Contenido del comentario
                  Text(
                    comment.content,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: b.textPrimary,
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

  Widget _initialsWidget(String initials, BrumaTheme b) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: b.primary,
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
