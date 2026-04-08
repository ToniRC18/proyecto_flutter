import 'package:flutter/material.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../features/accounts/presentation/accounts_screen.dart';
import '../../../features/budget/presentation/budget_screen.dart';
import '../../../features/profile/presentation/profile_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// Widget raíz que envuelve las pantallas del bottom nav con IndexedStack.
/// El IndexedStack mantiene el estado de cada tab al cambiar entre ellas.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Índice activo en la navbar (índice 2 = botón "+", no es una tab)
  int _currentIndex = 0;

  // Las 4 pantallas reales (el índice de la navbar se mapea de forma especial)
  // 0 → Home, 1 → Accounts, 3 → Budget, 4 → Profile
  static const _screens = [
    DashboardScreen(),
    AccountsScreen(),
    SizedBox.shrink(), // placeholder para el índice 2 (botón +)
    BudgetScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    // El índice 2 lo maneja el _CenterPlusButton directamente, no cambia tab
    if (index == 2) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // IndexedStack conserva el estado de cada pantalla
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Fondo de la extendedBody se muestra detrás de la navbar
      extendBody: true,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
