/// Constantes de rutas de la app.
/// Centralizar aquí evita errores de tipeo dispersos en el código.
abstract class AppRoutes {
  // Paths
  static const String dashboard = '/';
  static const String addExpense = '/add';
  static const String pockets = '/pockets';

  // Nombres (usados en context.goNamed / context.pushNamed)
  static const String dashboardName = 'dashboard';
  static const String addExpenseName = 'add-expense';
  static const String pocketsName = 'pockets';

  // Query parameters
  static const String categoryParam = 'category';
}