class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final String categoryEmoji;
  final DateTime date;
  final String type; // 'expense' or 'income'
  final String account; // e.g. 'Main Pocket'

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.categoryEmoji,
    required this.date,
    required this.type,
    required this.account,
  });
}
