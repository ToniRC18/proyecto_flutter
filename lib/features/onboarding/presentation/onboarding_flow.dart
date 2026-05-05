import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/onboarding/onboarding_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../accounts/data/accounts_repository.dart';
import 'widgets/onboarding_progress_dots.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pageController = PageController();
  final _initialBalanceCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  late final List<_QuickBillItem> _bills;

  int _currentPage = 0;
  String? _selectedProfile;
  String _initialAccountType = 'efectivo';
  bool _loading = false;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _initialBalanceCtrl.addListener(_refresh);
    _goalCtrl.addListener(_refresh);
    _bills = [
      _QuickBillItem('Netflix', '📱', 'entretenimiento', 219),
      _QuickBillItem('Spotify', '🎵', 'entretenimiento', 99),
      _QuickBillItem('Gimnasio', '🏋️', 'salud', 500),
      _QuickBillItem('iCloud/Drive', '☁️', 'suscripciones', 25),
      _QuickBillItem('Internet', '🌐', 'servicios', 499),
      _QuickBillItem('Luz/CFE', '💡', 'servicios', 800),
    ];
    for (final bill in _bills) {
      bill.amountController.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _initialBalanceCtrl
      ..removeListener(_refresh)
      ..dispose();
    _goalCtrl
      ..removeListener(_refresh)
      ..dispose();
    for (final bill in _bills) {
      bill.amountController
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;

    // El formatter actualiza el controller durante su propia notificación.
    // Diferir el setState evita mutar el árbol mientras el input se normaliza.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted) setState(() {});
    });
  }

  double get _initialBalance =>
      AmountInputField.parseAmount(_initialBalanceCtrl.text);

  double get _monthlyGoal => AmountInputField.parseAmount(_goalCtrl.text);

  int get _selectedBillsCount =>
      _bills.where((bill) => bill.selected && bill.amount > 0).length;

  bool get _canContinue {
    return switch (_currentPage) {
      1 => _selectedProfile != null,
      2 => _initialBalance > 0,
      3 => _monthlyGoal > 0,
      _ => true,
    };
  }

  Future<void> _goTo(int page) async {
    try {
      await _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      if (mounted) setState(() => _currentPage = page);
    } catch (e) {
      _showError('No se pudo avanzar: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    final b = context.bruma;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: b.error,
        content: Text(message),
      ),
    );
  }

  Future<void> _complete() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _showError('No hay sesión activa.');
      return;
    }

    setState(() => _loading = true);
    try {
      final rows = await supabase
          .from('tenant_members')
          .select('tenant_id, role')
          .eq('user_id', userId);

      final list = (rows as List).cast<Map<String, dynamic>>();

      // El tenant personal siempre tiene role='owner' (garantizado por trigger)
      final ownerRow = list.firstWhere(
        (r) => r['role'] == 'owner',
        orElse: () => list.isNotEmpty ? list.first : {},
      );

      final tenantId = ownerRow['tenant_id'] as String?;
      if (tenantId == null) {
        throw Exception('No se encontró el espacio personal.');
      }

      if (_initialBalance > 0) {
        if (_initialAccountType == 'efectivo') {
          await _updateCashAccount(tenantId, _initialBalance);
        } else {
          await ref.read(accountsRepositoryProvider).createAccount(
                tenantId: tenantId,
                name: _accountName(_initialAccountType),
                type: _accountDbType(_initialAccountType),
                initialBalance: _initialBalance,
              );
        }
      }

      if (_monthlyGoal > 0) {
        await onboardingService.saveMonthlySavingsGoal(tenantId, _monthlyGoal);
      }

      for (final bill in _bills.where((item) => item.selected)) {
        if (bill.amount <= 0) continue;
        await supabase.from('bills').insert({
          'tenant_id': tenantId,
          'name': bill.name,
          'amount': bill.amount,
          'category': bill.category,
          'due_day': 1,
          'frequency': 'monthly',
          'is_active': true,
        });
      }

      await onboardingService.markCompleted(tenantId);
    } catch (e) {
      _showError('No se pudo finalizar el onboarding: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateCashAccount(String tenantId, double balance) async {
    try {
      final account = await supabase
          .from('accounts')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('type', 'cash')
          .limit(1)
          .maybeSingle();
      final accountId = account?['id'] as String?;
      if (accountId == null) {
        await ref.read(accountsRepositoryProvider).createAccount(
              tenantId: tenantId,
              name: 'Efectivo',
              type: 'cash',
              initialBalance: balance,
            );
        return;
      }
      await supabase.from('accounts').update({
        'balance': balance,
      }).eq('id', accountId);
    } catch (e) {
      throw Exception('No se pudo guardar la cuenta de efectivo: $e');
    }
  }

  String _accountDbType(String type) => type == 'banco' ? 'bank' : 'bank';

  String _accountName(String type) {
    return switch (type) {
      'banco' => 'Cuenta bancaria',
      'debito' => 'Débito',
      _ => 'Efectivo',
    };
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: b.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: _currentPage == 0 ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: IconButton(
                      onPressed: _currentPage == 0
                          ? null
                          : () => _goTo(_currentPage - 1),
                      icon: Icon(Iconsax.arrow_left, color: b.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  if (_currentPage > 0 && _currentPage < 5)
                    TextButton(
                      onPressed: () => _goTo(5),
                      child: Text(
                        'Saltar',
                        style: GoogleFonts.dmSans(
                          color: b.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 72, height: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeScreen(onStart: () => _goTo(1)),
                  _ProfileScreen(
                    selectedProfile: _selectedProfile,
                    onSelected: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedProfile = value);
                    },
                    onContinue: _canContinue ? () => _goTo(2) : null,
                  ),
                  _AccountScreen(
                    selectedType: _initialAccountType,
                    balanceController: _initialBalanceCtrl,
                    onTypeSelected: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => _initialAccountType = value);
                    },
                    onContinue: _canContinue ? () => _goTo(3) : null,
                  ),
                  _SavingsGoalScreen(
                    controller: _goalCtrl,
                    onContinue: _canContinue ? () => _goTo(4) : null,
                  ),
                  _QuickBillsScreen(
                    bills: _bills,
                    onChanged: () {
                      HapticFeedback.lightImpact();
                      setState(() {});
                    },
                    onContinue: () => _goTo(5),
                  ),
                  _ReadyScreen(
                    goal: _monthlyGoal,
                    selectedBillsCount: _selectedBillsCount,
                    loading: _loading,
                    onComplete: _loading ? null : _complete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;

  const _WelcomeScreen({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return _OnboardingScreenFrame(
      top: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _BreathingLogo(),
          const SizedBox(height: 34),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 28,
                height: 1.05,
                color: b.textPrimary,
              ),
              children: [
                const TextSpan(text: 'Bienvenido a\nbruma'),
                TextSpan(text: '.', style: TextStyle(color: b.primary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tu dinero, sin ansiedad. Te ayudamos a entenderlo,\nno a culparte por él.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.45,
              color: b.textSecondary,
            ),
          ),
        ],
      ),
      bottom: Column(
        children: [
          const OnboardingProgressDots(active: 0),
          const SizedBox(height: 20),
          AppButton(label: 'Empezar', onPressed: onStart),
        ],
      ),
    );
  }
}

class _BreathingLogo extends StatefulWidget {
  const _BreathingLogo();

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 1 +
            (_controller.value <= 0.5
                ? _controller.value * 0.08
                : (1 - _controller.value) * 0.08);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: pulse),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          builder: (context, scale, animatedChild) {
            return Transform.scale(scale: scale, child: animatedChild);
          },
          child: child,
        );
      },
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _Circle(size: 220, color: b.primary.withValues(alpha: 0.08)),
            _Circle(size: 160, color: b.primary.withValues(alpha: 0.14)),
            _Circle(
              size: 96,
              color: b.primary,
              child: Text(
                'b.',
                style: GoogleFonts.dmSans(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: b.onPrimary,
                  letterSpacing: -0.03 * 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  final String? selectedProfile;
  final ValueChanged<String> onSelected;
  final VoidCallback? onContinue;

  const _ProfileScreen({
    required this.selectedProfile,
    required this.onSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('trabajo_fijo', '💼', 'Trabajo fijo'),
      ('freelance', '🚀', 'Freelance / negocio'),
      ('estudiante', '🎓', 'Estudiante'),
      ('otro', '✨', 'Otro'),
    ];

    return _StepFrame(
      active: 1,
      title: '¿Cómo describes\ntu situación?',
      subtitle: 'Lo usamos para sugerirte categorías útiles.',
      content: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.08,
        children: [
          for (final item in items)
            _SelectableCard(
              active: selectedProfile == item.$1,
              onTap: () => onSelected(item.$1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$2, style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  _CardTitle(item.$3),
                ],
              ),
            ),
        ],
      ),
      buttonLabel: 'Continuar',
      onPressed: onContinue,
    );
  }
}

class _AccountScreen extends StatelessWidget {
  final String selectedType;
  final TextEditingController balanceController;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback? onContinue;

  const _AccountScreen({
    required this.selectedType,
    required this.balanceController,
    required this.onTypeSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final chips = [
      ('efectivo', '💵 Efectivo'),
      ('banco', '🏦 Cuenta bancaria'),
      ('debito', '💳 Débito'),
    ];

    return _StepFrame(
      active: 2,
      title: '¿Cuánto tienes\nahora mismo?',
      subtitle: 'Empieza con lo que tienes.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final chip in chips) ...[
                  _TypeChip(
                    label: chip.$2,
                    active: selectedType == chip.$1,
                    onTap: () => onTypeSelected(chip.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          AmountInputField(
            controller: balanceController,
            autofocus: true,
            amountColor: b.primary,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.lock_1, size: 16, color: b.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Solo tú ves esto',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: b.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
      buttonLabel: 'Guardar cuenta',
      onPressed: onContinue,
    );
  }
}

class _SavingsGoalScreen extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onContinue;

  const _SavingsGoalScreen({
    required this.controller,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final suggestions = [1000, 2500, 5000, 10000];

    return _StepFrame(
      active: 3,
      title: '¿Cuánto quieres\nahorrar este mes?',
      subtitle: 'No es un compromiso. Es una brújula.',
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  r'$',
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    color: b.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  autofocus: false,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: const [MoneyInputFormatter()],
                  style: GoogleFonts.dmSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: b.primary,
                    letterSpacing: -0.03 * 48,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                ),
              ),
            ],
          ),
          Text(
            'MXN al mes',
            style: GoogleFonts.dmSans(fontSize: 13, color: b.textTertiary),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final amount in suggestions)
                _SuggestionChip(
                  label: '\$${_formatWhole(amount)}',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    controller.text = AmountInputField.formatAmount(
                      (amount * 100).toString(),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
      buttonLabel: 'Guardar meta',
      onPressed: onContinue,
    );
  }
}

class _QuickBillsScreen extends StatelessWidget {
  final List<_QuickBillItem> bills;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  const _QuickBillsScreen({
    required this.bills,
    required this.onChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return _StepFrame(
      active: 4,
      title: '¿Tienes gastos\nfijos cada mes?',
      subtitle: 'Agrégalos y bruma. te avisa antes de cada vencimiento.',
      content: Column(
        children: [
          for (final bill in bills) ...[
            AppCard(
              padding: 12,
              child: Row(
                children: [
                  Checkbox(
                    value: bill.selected,
                    activeColor: b.primary,
                    onChanged: (value) {
                      bill.selected = value ?? false;
                      onChanged();
                    },
                  ),
                  Text(bill.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardTitle(bill.name),
                        Text(
                          bill.category,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: b.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: bill.amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: const [MoneyInputFormatter()],
                      textAlign: TextAlign.right,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: b.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: b.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Text(
            'Puedes agregar más desde Pagos recurrentes.',
            style: GoogleFonts.dmSans(fontSize: 12, color: b.textTertiary),
          ),
        ],
      ),
      buttonLabel: 'Continuar',
      onPressed: onContinue,
    );
  }
}

class _ReadyScreen extends StatelessWidget {
  final double goal;
  final int selectedBillsCount;
  final bool loading;
  final VoidCallback? onComplete;

  const _ReadyScreen({
    required this.goal,
    required this.selectedBillsCount,
    required this.loading,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final summary = [
      'Cuenta de efectivo creada',
      goal > 0
          ? 'Meta: \$${_formatWhole(goal.round())}'
          : 'Puedes definirla después',
      selectedBillsCount > 0
          ? '$selectedBillsCount pagos recurrentes'
          : 'Sin pagos fijos por ahora',
    ];

    return _OnboardingScreenFrame(
      top: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _AnimatedCheckmark(),
          const SizedBox(height: 28),
          Text(
            'Ya está.\nVámonos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.03 * 28,
              height: 1.08,
              color: b.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tu cuenta de efectivo ya está lista.\nEmpieza registrando tu primer gasto.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.45,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Column(
            children: [
              for (final item in summary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: b.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: b.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      bottom: Column(
        children: [
          const OnboardingProgressDots(active: 5),
          const SizedBox(height: 20),
          AppButton(
            label: 'Ir a mi dashboard',
            loading: loading,
            onPressed: onComplete,
          ),
        ],
      ),
    );
  }
}

class _AnimatedCheckmark extends StatefulWidget {
  const _AnimatedCheckmark();

  @override
  State<_AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<_AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Circle(size: 96, color: b.success.withValues(alpha: 0.14)),
          _Circle(
            size: 64,
            color: b.success,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(32, 24),
                  painter: _CheckmarkPainter(
                    color: b.surface,
                    progress: _animation.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _CheckmarkPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.52)
      ..lineTo(size.width * 0.40, size.height * 0.78)
      ..lineTo(size.width * 0.88, size.height * 0.18);

    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(0, metric.length * progress);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(visiblePath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _StepFrame extends StatelessWidget {
  final int active;
  final String title;
  final String subtitle;
  final Widget content;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _StepFrame({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return _OnboardingScreenFrame(
      top: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.03 * 26,
                height: 1.08,
                color: b.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                height: 1.4,
                color: b.textSecondary,
              ),
            ),
            const SizedBox(height: 26),
            content,
          ],
        ),
      ),
      bottom: Column(
        children: [
          OnboardingProgressDots(active: active),
          const SizedBox(height: 20),
          AppButton(label: buttonLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}

class _OnboardingScreenFrame extends StatelessWidget {
  final Widget top;
  final Widget bottom;

  const _OnboardingScreenFrame({
    required this.top,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: Column(
        children: [
          Expanded(child: top),
          bottom,
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableCard({
    required this.active,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return AppCard(
      padding: 0,
      noBorder: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? b.primary.withValues(alpha: 0.06) : b.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? b.primary : b.border,
            width: active ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? b.primary : b.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: active ? b.onPrimary : b.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: b.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: b.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: b.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  final Widget? child;

  const _Circle({
    required this.size,
    required this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;

  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: b.textPrimary,
        letterSpacing: -0.02 * 15,
      ),
    );
  }
}

class _QuickBillItem {
  final String name;
  final String emoji;
  final String category;
  final double defaultAmount;
  final TextEditingController amountController;
  bool selected;

  _QuickBillItem(
    this.name,
    this.emoji,
    this.category,
    this.defaultAmount,
  )   : selected = false,
        amountController = TextEditingController(
          text: AmountInputField.formatAmount((defaultAmount * 100).toString()),
        );

  double get amount => AmountInputField.parseAmount(amountController.text);
}

String _formatWhole(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}
