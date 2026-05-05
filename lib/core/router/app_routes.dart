/// Constantes de rutas de la app.
/// Centralizar aquí evita errores de tipeo dispersos en el código.
abstract class AppRoutes {
  // Paths
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/';
  static const String stats = '/stats';
  static const String budget = '/budget';
  static const String accounts = '/accounts';
  static const String accountDetail = '/account-detail';
  static const String addExpense = '/add';
  static const String addIncome = '/add-income';
  static const String addTransfer = '/add-transfer';
  static const String bills = '/bills';
  static const String addBill = '/add-bill';
  static const String pockets = '/pockets';
  static const String sharedSpaces = '/shared-spaces';
  static const String spaceDetail = '/space-detail';
  static const String invitations = '/invitations';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transaction';
  static const String creditCardDetail = '/credit-card-detail';

  // Nombres (usados en context.goNamed / context.pushNamed)
  static const String authName = 'auth';
  static const String onboardingName = 'onboarding';
  static const String dashboardName = 'dashboard';
  static const String statsName = 'stats';
  static const String budgetName = 'budget';
  static const String accountsName = 'accounts';
  static const String accountDetailName = 'account-detail';
  static const String addExpenseName = 'add-expense';
  static const String addIncomeName = 'add-income';
  static const String addTransferName = 'add-transfer';
  static const String billsName = 'bills';
  static const String addBillName = 'add-bill';
  static const String pocketsName = 'pockets';
  static const String sharedSpacesName = 'shared-spaces';
  static const String spaceDetailName = 'space-detail';
  static const String invitationsName = 'invitations';
  static const String transactionsName = 'transactions';
  static const String transactionDetailName = 'transaction-detail';
  static const String creditCardDetailName = 'credit-card-detail';

  // Query parameters
  static const String categoryParam = 'category';
}
