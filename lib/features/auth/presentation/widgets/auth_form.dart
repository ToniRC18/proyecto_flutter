import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Formulario reutilizable para login y registro.
/// Recibe los controllers del padre y llama callbacks en submit/toggle.
class AuthForm extends StatelessWidget {
  final bool isLogin;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo nombre (solo en registro)
        if (!isLogin) ...[
          _buildTextField(
            context: context,
            controller: nameController,
            label: 'Nombre',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
        ],

        // Campo email
        _buildTextField(
          context: context,
          controller: emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Campo contraseña
        _buildTextField(
          context: context,
          controller: passwordController,
          label: 'Contraseña',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 28),

        // Botón principal
        SizedBox(
          height: 52,
          child: GestureDetector(
            onTap: isLoading ? null : onSubmit,
            child: Container(
              decoration: BoxDecoration(
                color: b.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: b.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Link para cambiar de modo
        Center(
          child: GestureDetector(
            onTap: onToggleMode,
            child: Text(
              isLogin
                  ? '¿No tienes cuenta? Regístrate'
                  : '¿Ya tienes cuenta? Inicia sesión',
              style: GoogleFonts.dmSans(
                color: b.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final b = context.bruma;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(
        color: b.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          color: b.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: b.primary, size: 20),
        filled: true,
        fillColor: b.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: b.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: b.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
