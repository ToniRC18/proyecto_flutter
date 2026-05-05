import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/onboarding/onboarding_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/bruma_animations.dart';
import '../../../core/widgets/app_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../data/auth_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AuthScreen — Basado EXACTAMENTE en LoginScreen de screens-extra.jsx
// SIN AppBar, logo "bruma." 32sp w800, tagline, campos AppInputField,
// divider con "o", botón Google, toggle login↔register
// ═══════════════════════════════════════════════════════════════════════════════

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    if (!_isLogin && name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await repo.signIn(email, password);
      } else {
        await repo.signUp(email, password, name);
      }
      // Sincroniza estado de onboarding desde Supabase ahora que hay sesión.
      await onboardingService.syncFromServer();
      await NotificationService.syncTokenForCurrentUser();
      // GoRouter redirige automáticamente: dashboard u onboarding.
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: context.bruma.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: context.bruma.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // ── Logo + tagline ─────────────────────────────
                      FadeUpAnimation(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'bruma',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.04 * 32,
                                      color: b.textPrimary,
                                      height: 1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: b.primary,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tu dinero, sin ansiedad.',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: b.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Formulario ──────────────────────────────────
                      FadeUpAnimation(
                        delayMs: 100,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              AppInputField(
                                label: 'Nombre completo',
                                controller: _nameController,
                              ),
                              const SizedBox(height: 14),
                            ],
                            AppInputField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            AppInputField(
                              label: 'Contraseña',
                              controller: _passwordController,
                              obscureText: true,
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),
                              AppInputField(
                                label: 'Confirmar contraseña',
                                controller: _confirmController,
                                obscureText: true,
                              ),
                            ],

                            // ¿Olvidaste tu contraseña? (solo login)
                            if (_isLogin) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: b.primary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Botón principal
                            AppButton(
                              label:
                                  _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                              onPressed: _submit,
                              loading: _isLoading,
                            ),
                            const SizedBox(height: 20),

                            // Divider "o"
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: b.border,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'o',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: b.textTertiary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: b.border,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Botón Google
                            AppButton(
                              label: 'Continuar con Google',
                              variant: AppButtonVariant.ghost,
                              icon: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      Color(0xFFEA4335),
                                      Color(0xFFFBBC05),
                                      Color(0xFF34A853),
                                      Color(0xFF4285F4),
                                      Color(0xFFEA4335),
                                    ],
                                  ),
                                ),
                              ),
                              onPressed: () {
                                // TODO: Google Sign-In
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Toggle login/register ──────────────────────────
              FadeUpAnimation(
                delayMs: 200,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GestureDetector(
                    onTap: _toggleMode,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? '¿No tienes cuenta? '
                                : '¿Ya tienes cuenta? ',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: b.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: _isLogin ? 'Regístrate' : 'Inicia sesión',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: b.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
