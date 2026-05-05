import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../offline/providers/connectivity_provider.dart';
import '../theme/app_theme.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../features/accounts/presentation/accounts_screen.dart';
import '../../../features/profile/presentation/profile_screen.dart';
import '../../../features/shared_spaces/presentation/shared_spaces_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/offline_banner.dart';

/// Widget raíz que envuelve las pantallas del bottom nav con IndexedStack.
/// El IndexedStack mantiene el estado de cada tab al cambiar entre ellas.
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // Índice activo en la navbar (índice 2 = botón "+", no es una tab)
  late int _currentIndex;

  // Las tabs reales; el índice 2 es el FAB central.
  // 0 → Home, 1 → Accounts, 3 → Espacios, 4 → Profile
  static const _screens = [
    DashboardScreen(),
    AccountsScreen(),
    SizedBox.shrink(), // placeholder para el índice 2 (botón +)
    SharedSpacesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    // El índice 2 lo maneja el _CenterPlusButton directamente, no cambia tab
    if (index == 2) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(connectivitySyncListenerProvider);
    final b = context.bruma;

    return Scaffold(
      backgroundColor: b.bg,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            // IndexedStack conserva el estado de cada pantalla
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
