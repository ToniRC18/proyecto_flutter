/// Constantes de rutas de la app.
/// Centralizar aquí evita errores de tipeo dispersos en el código.
abstract class AppRoutes {
  // Paths
  static const String auth = '/auth';
  static const String dashboard = '/';
  static const String addExpense = '/add';
  static const String addIncome = '/add-income';
  static const String pockets = '/pockets';
  static const String sharedSpaces = '/shared-spaces';
  static const String transactionDetail = '/transaction';

  // Nombres (usados en context.goNamed / context.pushNamed)
  static const String authName = 'auth';
  static const String dashboardName = 'dashboard';
  static const String addExpenseName = 'add-expense';
  static const String addIncomeName = 'add-income';
  static const String pocketsName = 'pockets';
  static const String sharedSpacesName = 'shared-spaces';
  static const String transactionDetailName = 'transaction-detail';

  // Query parameters
  static const String categoryParam = 'category';
}