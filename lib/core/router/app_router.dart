import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/add_expense_screen.dart';
import '../../features/transactions/presentation/widgets/category_selector.dart';
import '../../features/pockets/presentation/pockets_screen.dart';
import 'app_routes.dart';
import 'error_screen.dart';

/// Instancia global del router.
/// Se usa como singleton para que GoRouter mantenga el estado de navegación.
final appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  debugLogDiagnostics: true, // Útil en desarrollo: loggea cada cambio de ruta
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  routes: [
    GoRoute(
      path: AppRoutes.dashboard,
      name: AppRoutes.dashboardName,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.addExpense,
      name: AppRoutes.addExpenseName,
      // Lee el query param ?category=food y lo mapea a CategoryItem
      builder: (context, state) {
        final categoryKey = state.uri.queryParameters[AppRoutes.categoryParam];
        final initialCategory = _categoryFromKey(categoryKey);
        return AddExpenseScreen(initialCategory: initialCategory);
      },
    ),
    GoRoute(
      path: AppRoutes.pockets,
      name: AppRoutes.pocketsName,
      builder: (context, state) => const PocketsScreen(),
    ),
  ],
);

/// Mapea el valor del query param a un [CategoryItem].
/// Si el valor es nulo o no coincide, devuelve null (sin preselección).
///
/// Ejemplo de URL: /add?category=food
CategoryItem? _categoryFromKey(String? key) {
  if (key == null) return null;
  const mapping = {
    'food': '🍔',
    'transport': '🚗',
    'rent': '🏠', 
    'leisure': '🎮',
    'grocery': '🛒',
    'health': '💊',
  };
  final emoji = mapping[key.toLowerCase()];
  if (emoji == null) return null;
  try {
    return kCategories.firstWhere((c) => c.emoji == emoji);
  } catch (_) {
    return null;
  }
}
