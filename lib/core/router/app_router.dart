import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/transactions/presentation/add_expense_screen.dart';
import '../../features/transactions/presentation/add_income_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';
import '../../features/transactions/presentation/widgets/category_selector.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/pockets/presentation/pockets_screen.dart';
import '../../features/shared_spaces/presentation/shared_spaces_screen.dart';
import '../navigation/main_shell.dart';
import '../supabase/supabase_client.dart';
import 'app_routes.dart';
import 'error_screen.dart';

/// Listenable que envuelve el stream de auth de Supabase.
/// Notifica a GoRouter cada vez que cambia el estado de autenticación.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Router global con redirect basado en estado de autenticación.
final appRouter = GoRouter(
  initialLocation: AppRoutes.auth,
  debugLogDiagnostics: true,
  refreshListenable: _GoRouterRefreshStream(supabase.auth.onAuthStateChange),
  redirect: (context, state) {
    final session = supabase.auth.currentSession;
    final onAuth = state.matchedLocation == AppRoutes.auth;

    if (session == null && !onAuth) return AppRoutes.auth;
    if (session != null && onAuth) return AppRoutes.dashboard;
    return null;
  },
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  routes: [
    // ── Autenticación ──────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.auth,
      name: AppRoutes.authName,
      builder: (context, state) => const AuthScreen(),
    ),

    // ── Shell principal con bottom nav (IndexedStack) ──────────────────────
    GoRoute(
      path: AppRoutes.dashboard,
      name: AppRoutes.dashboardName,
      builder: (context, state) => const MainShell(),
    ),

    // ── Pantallas modales (se apilan sobre la navbar) ──────────────────────
    GoRoute(
      path: AppRoutes.addExpense,
      name: AppRoutes.addExpenseName,
      builder: (context, state) {
        final categoryKey = state.uri.queryParameters[AppRoutes.categoryParam];
        final initialCategory = _categoryFromKey(categoryKey);
        return AddExpenseScreen(initialCategory: initialCategory);
      },
    ),
    GoRoute(
      path: AppRoutes.addIncome,
      name: AppRoutes.addIncomeName,
      builder: (context, state) => const AddIncomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.pockets,
      name: AppRoutes.pocketsName,
      builder: (context, state) => const PocketsScreen(),
    ),
    GoRoute(
      path: AppRoutes.sharedSpaces,
      name: AppRoutes.sharedSpacesName,
      builder: (context, state) => const SharedSpacesScreen(),
    ),
    GoRoute(
      path: AppRoutes.transactionDetail,
      name: AppRoutes.transactionDetailName,
      builder: (context, state) {
        final transaction = state.extra as Transaction?;
        if (transaction == null) return const ErrorScreen(error: null);
        return TransactionDetailScreen(transaction: transaction);
      },
    ),
  ],
);

/// Mapea el query param ?category= a un [CategoryItem].
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
