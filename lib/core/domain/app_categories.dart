// Modelo de categoría
class AppCategory {
  final String id; // clave única en inglés (para DB)
  final String label; // texto que ve el usuario (español)
  final String emoji; // ícono visual
  final bool isExpense; // true = gasto, false = ingreso
  final bool isIncome; // puede ser true en ambos si aplica

  const AppCategory({
    required this.id,
    required this.label,
    required this.emoji,
    this.isExpense = false,
    this.isIncome = false,
  });
}

class AppCategories {
  // Categorías de GASTOS
  static const List<AppCategory> expenses = [
    AppCategory(
      id: 'food',
      label: 'Comida',
      emoji: '🍔',
      isExpense: true,
    ),
    AppCategory(
      id: 'transport',
      label: 'Transporte',
      emoji: '🚗',
      isExpense: true,
    ),
    AppCategory(
      id: 'rent',
      label: 'Renta',
      emoji: '🏠',
      isExpense: true,
    ),
    AppCategory(
      id: 'entertainment',
      label: 'Ocio',
      emoji: '🎮',
      isExpense: true,
    ),
    AppCategory(
      id: 'health',
      label: 'Salud',
      emoji: '💊',
      isExpense: true,
    ),
    AppCategory(
      id: 'shopping',
      label: 'Compras',
      emoji: '🛍️',
      isExpense: true,
    ),
    AppCategory(
      id: 'bills',
      label: 'Servicios',
      emoji: '💡',
      isExpense: true,
    ),
    AppCategory(
      id: 'education',
      label: 'Educación',
      emoji: '📚',
      isExpense: true,
    ),
    AppCategory(
      id: 'transfer',
      label: 'Transferencia',
      emoji: '🔄',
      isExpense: true,
      isIncome: true,
    ),
    AppCategory(
      id: 'other',
      label: 'Otro',
      emoji: '📦',
      isExpense: true,
      isIncome: true,
    ),
  ];

  // Categorías de INGRESOS
  static const List<AppCategory> income = [
    AppCategory(
      id: 'salary',
      label: 'Salario',
      emoji: '💼',
      isIncome: true,
    ),
    AppCategory(
      id: 'freelance',
      label: 'Freelance',
      emoji: '💻',
      isIncome: true,
    ),
    AppCategory(
      id: 'investment',
      label: 'Inversión',
      emoji: '📈',
      isIncome: true,
    ),
    AppCategory(
      id: 'gift',
      label: 'Regalo',
      emoji: '🎁',
      isIncome: true,
    ),
    AppCategory(
      id: 'transfer',
      label: 'Transferencia',
      emoji: '🔄',
      isExpense: true,
      isIncome: true,
    ),
    AppCategory(
      id: 'other',
      label: 'Otro',
      emoji: '📦',
      isExpense: true,
      isIncome: true,
    ),
  ];

  static const List<AppCategory> _legacy = [
    AppCategory(id: 'super', label: 'Super', emoji: '🛒', isExpense: true),
    AppCategory(id: 'grocery', label: 'Super', emoji: '🛒', isExpense: true),
    AppCategory(id: 'leisure', label: 'Ocio', emoji: '🎮', isExpense: true),
    AppCategory(id: 'clothing', label: 'Ropa', emoji: '👗', isExpense: true),
    AppCategory(id: 'tech', label: 'Tech', emoji: '📱', isExpense: true),
    AppCategory(id: 'bonus', label: 'Bonus', emoji: '💰', isIncome: true),
    AppCategory(id: 'internet', label: 'Internet', emoji: '📡', isExpense: true),
    AppCategory(id: 'gym', label: 'Gym', emoji: '🏋️', isExpense: true),
    AppCategory(id: 'water', label: 'Agua', emoji: '💧', isExpense: true),
    AppCategory(id: 'electricity', label: 'Electricidad', emoji: '💡', isExpense: true),
    AppCategory(id: 'phone', label: 'Teléfono', emoji: '📱', isExpense: true),
    AppCategory(id: 'streaming', label: 'Streaming', emoji: '📺', isExpense: true),
    AppCategory(id: 'insurance', label: 'Seguros', emoji: '🛡️', isExpense: true),
  ];

  static const Map<String, String> _aliases = {
    'comida': 'food',
    'transporte': 'transport',
    'renta': 'rent',
    'ocio': 'entertainment',
    'salud': 'health',
    'compras': 'shopping',
    'servicios': 'bills',
    'educacion': 'education',
    'educación': 'education',
    'transferencia': 'transfer',
    'otro': 'other',
    'salario': 'salary',
    'inversion': 'investment',
    'inversión': 'investment',
    'regalo': 'gift',
    'gimnasio': 'gym',
    'agua': 'water',
    'electricidad': 'electricity',
    'telefono': 'phone',
    'teléfono': 'phone',
    'seguros': 'insurance',
  };

  static List<AppCategory> get all => [...expenses, ...income, ..._legacy];

  static String normalizeId(String value) {
    final normalized = value.trim().toLowerCase();
    return _aliases[normalized] ?? normalized;
  }

  // Helper: buscar categoría por id
  static AppCategory? findById(String id) {
    final normalized = normalizeId(id);
    for (final category in all) {
      if (category.id == normalized) return category;
    }
    try {
      return all.firstWhere((c) => normalizeId(c.label) == normalized);
    } catch (_) {
      return null;
    }
  }

  // Helper: emoji por id (fallback '📦')
  static String emojiForId(String id) {
    return findById(id)?.emoji ?? '📦';
  }

  // Helper: label por id (fallback id)
  static String labelForId(String id) {
    return findById(id)?.label ?? id;
  }
}
