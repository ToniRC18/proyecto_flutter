import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/transaction_split_model.dart';
import '../providers/split_provider.dart';
import 'split_member_tile.dart';

class SplitExpenseSheet extends ConsumerStatefulWidget {
  final String tenantId;
  final double totalAmount;
  final List<TransactionSplitModel> initialSplits;

  const SplitExpenseSheet({
    super.key,
    required this.tenantId,
    required this.totalAmount,
    this.initialSplits = const [],
  });

  @override
  ConsumerState<SplitExpenseSheet> createState() => _SplitExpenseSheetState();
}

class _SplitExpenseSheetState extends ConsumerState<SplitExpenseSheet> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _selectedMembers = {};
  bool _equalParts = true;
  bool _initialized = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeMembers(List<Map<String, dynamic>> members) {
    if (_initialized) return;
    _initialized = true;

    final initialByUser = {
      for (final split in widget.initialSplits) split.userId: split,
    };
    final hasInitialSplits = initialByUser.isNotEmpty;

    for (final member in members) {
      final userId = member['userId'] as String;
      final initialSplit = initialByUser[userId];
      _selectedMembers[userId] = hasInitialSplits ? initialSplit != null : true;
      _controllers[userId] = TextEditingController(
        text: initialSplit != null ? initialSplit.amount.toStringAsFixed(2) : '0.00',
      );
    }

    if (!hasInitialSplits) {
      _applyEqualDistribution(members);
      return;
    }

    final initialSum = widget.initialSplits.fold<double>(
      0,
      (sum, split) => sum + split.amount,
    );
    _equalParts = (initialSum - widget.totalAmount).abs() > 0.009
        ? false
        : _looksLikeEqualDistribution();
  }

  bool _looksLikeEqualDistribution() {
    final selectedAmounts = _selectedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => _parsedAmount(entry.key))
        .toList();

    if (selectedAmounts.length < 2) return false;

    final min = selectedAmounts.reduce((a, b) => a < b ? a : b);
    final max = selectedAmounts.reduce((a, b) => a > b ? a : b);
    return (max - min).abs() <= 0.01;
  }

  double _parsedAmount(String userId) {
    final text = _controllers[userId]?.text.trim().replaceAll(',', '.');
    return double.tryParse(text ?? '') ?? 0;
  }

  List<String> _selectedUserIds(List<Map<String, dynamic>> members) {
    return members
        .where((member) => _selectedMembers[member['userId'] as String] ?? false)
        .map((member) => member['userId'] as String)
        .toList();
  }

  Map<String, double> _equalDistribution(List<Map<String, dynamic>> members) {
    final selectedIds = _selectedUserIds(members);
    if (selectedIds.isEmpty) return {};

    final totalCents = (widget.totalAmount * 100).round();
    final base = totalCents ~/ selectedIds.length;
    final remainder = totalCents % selectedIds.length;
    final distribution = <String, double>{};

    for (var index = 0; index < selectedIds.length; index++) {
      final cents = base + (index < remainder ? 1 : 0);
      distribution[selectedIds[index]] = cents / 100;
    }

    return distribution;
  }

  void _applyEqualDistribution(List<Map<String, dynamic>> members) {
    final distribution = _equalDistribution(members);
    for (final member in members) {
      final userId = member['userId'] as String;
      final value = distribution[userId] ?? 0;
      _controllers[userId]?.text = value.toStringAsFixed(2);
    }
  }

  double _assignedAmount(List<Map<String, dynamic>> members) {
    if (_equalParts) {
      final distribution = _equalDistribution(members);
      return distribution.values.fold<double>(0, (sum, amount) => sum + amount);
    }

    return _selectedUserIds(members).fold<double>(
      0,
      (sum, userId) => sum + _parsedAmount(userId),
    );
  }

  int _selectedCount(List<Map<String, dynamic>> members) {
    return _selectedUserIds(members).length;
  }

  String? _inlineError(List<Map<String, dynamic>> members) {
    final selectedCount = _selectedCount(members);
    if (selectedCount < 2) {
      return 'Selecciona al menos 2 miembros para dividir el gasto.';
    }

    if (!_equalParts) {
      final assigned = _assignedAmount(members);
      if ((assigned - widget.totalAmount).abs() > 0.009) {
        return 'La suma asignada debe ser exactamente igual al monto total.';
      }
    }

    return null;
  }

  void _toggleMember(String userId, bool selected, List<Map<String, dynamic>> members) {
    setState(() {
      _selectedMembers[userId] = selected;
      if (!selected) {
        _controllers[userId]?.text = '0.00';
      }
      if (_equalParts) {
        _applyEqualDistribution(members);
      }
    });
  }

  void _toggleMode(bool equalParts, List<Map<String, dynamic>> members) {
    setState(() {
      _equalParts = equalParts;
      if (_equalParts) {
        _applyEqualDistribution(members);
      }
    });
  }

  Future<void> _confirm(List<Map<String, dynamic>> members) async {
    final error = _inlineError(members);
    if (error != null) {
      setState(() {});
      return;
    }

    final now = DateTime.now();
    final distribution = _equalParts ? _equalDistribution(members) : <String, double>{};

    final splits = members
        .where((member) => _selectedMembers[member['userId'] as String] ?? false)
        .map((member) {
          final userId = member['userId'] as String;
          final amount = _equalParts ? (distribution[userId] ?? 0) : _parsedAmount(userId);
          return TransactionSplitModel(
            id: '',
            transactionId: '',
            userId: userId,
            amount: amount,
            isSettled: false,
            settledAt: null,
            createdAt: now,
            profileName: member['name'] as String?,
            avatarUrl: member['avatarUrl'] as String?,
          );
        })
        .toList();

    if (!mounted) return;
    Navigator.of(context).pop(splits);
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final membersAsync = ref.watch(tenantMembersProvider(widget.tenantId));
    final currentUserId = supabase.auth.currentUser?.id;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: b.bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: b.border),
      ),
      child: SafeArea(
        top: false,
        child: membersAsync.when(
          loading: () => SizedBox(
            height: 320,
            child: Center(
              child: CircularProgressIndicator(color: b.primary),
            ),
          ),
          error: (error, _) => SizedBox(
            height: 320,
            child: _SheetEmptyState(
              icon: Iconsax.danger,
              message: 'No se pudieron cargar los miembros.\n$error',
            ),
          ),
          data: (members) {
            if (members.isEmpty) {
              return const SizedBox(
                height: 320,
                child: _SheetEmptyState(
                  icon: Iconsax.people,
                  message: 'Este espacio aún no tiene miembros para dividir el gasto.',
                ),
              );
            }

            _initializeMembers(members);

            final errorText = _inlineError(members);
            final assignedAmount = _assignedAmount(members);
            final isExact = (assignedAmount - widget.totalAmount).abs() <= 0.009;
            final distribution = _equalDistribution(members);

            return Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: b.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dividir gasto',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: b.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Iconsax.close_circle,
                            color: b.textPrimary, size: 22),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTO TOTAL',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: b.textSecondary,
                            letterSpacing: 0.06 * 12,
                          ),
                        ),
                        Text(
                          '\$${widget.totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: b.primary,
                            letterSpacing: -0.03 * 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Partes iguales',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: b.textPrimary,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _equalParts,
                        activeColor: b.primary,
                        onChanged: (value) => _toggleMode(value, members),
                      ),
                      Text(
                        _equalParts ? 'Igual' : 'Custom',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: b.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_equalParts)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Asignado: \$${assignedAmount.toStringAsFixed(2)} / \$${widget.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isExact
                              ? b.success
                              : assignedAmount > widget.totalAmount
                                  ? b.error
                                  : b.textSecondary,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final userId = member['userId'] as String;
                      return SplitMemberTile(
                        name: member['name'] as String? ?? 'Miembro',
                        avatarUrl: member['avatarUrl'] as String?,
                        selected: _selectedMembers[userId] ?? false,
                        isCurrentUser: currentUserId == userId,
                        isEqualMode: _equalParts,
                        amount: distribution[userId] ?? 0,
                        amountController: _controllers[userId],
                        onSelected: (selected) => _toggleMember(userId, selected, members),
                        onAmountChanged: (_) => setState(() {}),
                      );
                    },
                  ),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: b.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: errorText == null ? () => _confirm(members) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: errorText == null
                                ? b.primary
                                : b.primary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Aplicar split',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              color: b.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SheetEmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: b.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: b.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
