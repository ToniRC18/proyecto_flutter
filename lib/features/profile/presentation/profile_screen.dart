import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/animations/bruma_animations.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _notificationsKey = 'notifications_enabled';

  bool _notificationsEnabled = true;
  bool _loadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationsPreference();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const SizedBox(height: 32),
            FadeUpAnimation(
              child: Center(
                child: Column(
                  children: [
                    userNameAsync.when(
                      data: (name) => _Avatar(
                        name: name,
                        onLongPress: () => _showEditNameDialog(name),
                        onEditTap: () => _showEditNameDialog(name),
                      ),
                      loading: () => const _Avatar(name: '?'),
                      error: (_, __) => const _Avatar(name: '?'),
                    ),
                    const SizedBox(height: 16),
                    userNameAsync.when(
                      data: (name) => Text(
                        name,
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: b.textPrimary,
                          letterSpacing: -0.03 * 22,
                        ),
                      ),
                      loading: () => const SizedBox(height: 28),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: b.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeUpAnimation(
              delayMs: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  padding: 20,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Miembro desde',
                        value: user?.createdAt != null
                            ? DateFormat('MMMM yyyy', 'es_MX')
                                .format(DateTime.parse(user!.createdAt))
                            : '—',
                      ),
                      Divider(color: b.border, height: 28),
                      tenantAsync.when(
                        data: (tenantId) {
                          final tenantNameAsync =
                              ref.watch(tenantNameProvider(tenantId));
                          return tenantNameAsync.when(
                            data: (tenantName) => _InfoRow(
                              label: 'Espacio',
                              value: tenantName,
                            ),
                            loading: () =>
                                const _InfoRow(label: 'Espacio', value: '…'),
                            error: (_, __) => _InfoRow(
                              label: 'Espacio',
                              value: _shortTenantLabel(tenantId),
                            ),
                          );
                        },
                        loading: () =>
                            const _InfoRow(label: 'Espacio', value: '…'),
                        error: (_, __) =>
                            const _InfoRow(label: 'Espacio', value: '—'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeUpAnimation(
              delayMs: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  padding: 0,
                  child: Column(
                    children: [
                      _ProfileSwitchOption(
                        icon: Iconsax.notification,
                        label: 'Notificaciones',
                        value: _notificationsEnabled,
                        loading: _loadingNotifications,
                        onChanged: _toggleNotifications,
                      ),
                      _Separator(),
                      _ProfileOption(
                        icon: Iconsax.chart_square,
                        label: 'Estadísticas',
                        onTap: () => context.push(AppRoutes.stats),
                      ),
                      _Separator(),
                      _ProfileOption(
                        icon: Iconsax.people,
                        label: 'Espacios compartidos',
                        onTap: () => context.push(AppRoutes.sharedSpaces),
                      ),
                      _Separator(),
                      _ProfileOption(
                        icon: Iconsax.receipt_2,
                        label: 'Pagos recurrentes',
                        onTap: () => context.push(AppRoutes.bills),
                      ),
                      _Separator(),
                      _ProfileOption(
                        icon: Iconsax.moneys,
                        label: 'Pockets',
                        onTap: () => context.push(AppRoutes.pockets),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeUpAnimation(
              delayMs: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await authRepo.signOut();
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          backgroundColor: b.error,
                          content: Text('Error: $error'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: b.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: b.error.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cerrar sesión',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: b.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNotificationsPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_notificationsKey);
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = saved ?? true;
        _loadingNotifications = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingNotifications = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final b = context.bruma;
    HapticFeedback.lightImpact();

    try {
      setState(() => _loadingNotifications = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, value);
      await FirebaseMessaging.instance.setAutoInitEnabled(value);
      if (value) {
        await FirebaseMessaging.instance.getToken();
      } else {
        await FirebaseMessaging.instance.deleteToken();
      }

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = value;
        _loadingNotifications = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingNotifications = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $error'),
        ),
      );
    }
  }

  Future<void> _showEditNameDialog(String currentName) async {
    final b = context.bruma;
    final controller = TextEditingController(text: currentName);

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: b.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tu nombre',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: b.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: b.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: b.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.dmSans(color: b.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Guardar',
                style: GoogleFonts.dmSans(
                  color: b.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldSave != true) return;

      final newName = controller.text.trim();
      if (newName.isEmpty) return;

      await ref.read(profileRepositoryProvider).updateUserName(newName);
      ref.invalidate(userNameProvider);
      if (!mounted) return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $error'),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  String _shortTenantLabel(String tenantId) {
    final normalized = tenantId.replaceAll('-', '').toUpperCase();
    return normalized.length >= 8 ? normalized.substring(0, 8) : normalized;
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final VoidCallback? onLongPress;
  final VoidCallback? onEditTap;

  const _Avatar({
    required this.name,
    this.onLongPress,
    this.onEditTap,
  });

  String _initials() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: b.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(),
                style: GoogleFonts.dmSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: b.primary,
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: b.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: b.border, width: 1),
                ),
                child: Icon(
                  Iconsax.edit,
                  size: 16,
                  color: b.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: b.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: b.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: b.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: b.textPrimary,
                ),
              ),
            ),
            Icon(
              Iconsax.arrow_right,
              color: b.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSwitchOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _ProfileSwitchOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: b.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: b.textPrimary,
              ),
            ),
          ),
          if (loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: b.primary,
              ),
            )
          else
            CupertinoSwitch(
              value: value,
              activeTrackColor: b.primary,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: context.bruma.border,
    );
  }
}
