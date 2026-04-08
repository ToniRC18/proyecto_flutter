// Archivo de datos mock obsoleto — los datos reales se obtienen
// desde Supabase a través de DashboardRepository.getRecentTransactions().
// Se conserva este archivo como stub para compatibilidad.

// ignore_for_file: unused_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_model.dart';

final mockTransactionsProvider = Provider<List<Transaction>>((ref) => const []);
