import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_categories.dart';
import '../supabase/supabase_client.dart';
import '../theme/app_theme.dart';
import '../../features/budget/data/budget_repository.dart';
import '../../features/transactions/domain/transaction_model.dart';

class MonthlyReportService {
  final SupabaseClient _client;
  final BudgetRepository _budgetRepository;

  MonthlyReportService(this._client, this._budgetRepository);

  /// Genera el PDF mensual del tenant con datos reales del mes solicitado.
  Future<Uint8List> generateMonthlyReport({
    required String tenantId,
    required int year,
    required int month,
  }) async {
    final theme = BrumaTheme.fromMode(
      dark: false,
      colorTheme: BrumaColorTheme.cobalt,
    );
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final totals = await _budgetRepository.getMonthlyTotals(tenantId, year, month);
    final categorySpend = await _budgetRepository.getMonthlySpendByCategory(
      tenantId,
      year,
      month,
    );
    final rawTransactions = await _client
        .from('transactions')
        .select()
        .eq('tenant_id', tenantId)
        .gte('date', start.toIso8601String())
        .lt('date', end.toIso8601String())
        .order('date', ascending: false)
        .limit(15);

    final transactions = (rawTransactions as List)
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();

    final sortedCategories = categorySpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(6).toList();
    final totalExpenses = totals['expenses'] ?? 0;

    final pdf = pw.Document();
    final monthLabel = _capitalize(
      DateFormat('MMMM yyyy', 'es_MX').format(DateTime(year, month, 1)),
    );
    final generatedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'bruma.',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfColor(theme.primary),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                monthLabel,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: _pdfColor(theme.textSecondary),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generado el $generatedDate',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _pdfColor(theme.textTertiary),
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Divider(color: _pdfColor(theme.border)),
              pw.SizedBox(height: 18),
              _buildSummarySection(theme, totals),
              pw.SizedBox(height: 18),
              _buildCategoriesSection(
                theme,
                topCategories: topCategories,
                totalExpenses: totalExpenses,
              ),
              pw.SizedBox(height: 18),
              _buildTransactionsSection(theme, transactions),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'bruma. — Tu dinero, sin ansiedad.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: _pdfColor(theme.textTertiary),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummarySection(
    BrumaTheme theme,
    Map<String, double> totals,
  ) {
    final income = totals['income'] ?? 0;
    final expenses = totals['expenses'] ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('RESUMEN', theme),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _summaryColumn(
                label: 'INGRESOS',
                value: income,
                theme: theme,
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: _summaryColumn(
                label: 'GASTOS',
                value: expenses,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCategoriesSection(
    BrumaTheme theme, {
    required List<MapEntry<String, double>> topCategories,
    required double totalExpenses,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('TOP CATEGORÍAS', theme),
        pw.SizedBox(height: 10),
        if (topCategories.isEmpty)
          pw.Text(
            'Sin gastos este mes.',
            style: pw.TextStyle(
              fontSize: 11,
              color: _pdfColor(theme.textSecondary),
            ),
          )
        else
          ...topCategories.asMap().entries.map((entry) {
            final isEven = entry.key.isEven;
            final category = entry.value.key;
            final amount = entry.value.value;
            final percent = totalExpenses > 0 ? amount / totalExpenses : 0;

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: isEven
                    ? _pdfColor(theme.surfaceAlt)
                    : PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          '${AppCategories.emojiForId(category)} ${AppCategories.labelForId(category)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: _pdfColor(theme.textPrimary),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          _formatCurrency(amount),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _pdfColor(theme.textPrimary),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.SizedBox(
                        width: 44,
                        child: pw.Text(
                          '${(percent * 100).toStringAsFixed(1)}%',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: _pdfColor(theme.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 7),
                  pw.Container(
                    height: 4,
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      color: _pdfColor(theme.border),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(999),
                      ),
                    ),
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Container(
                        width: 260 * percent.clamp(0, 1).toDouble(),
                        decoration: pw.BoxDecoration(
                          color: _pdfColor(theme.textSecondary),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  pw.Widget _buildTransactionsSection(
    BrumaTheme theme,
    List<Transaction> transactions,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('ÚLTIMAS TRANSACCIONES', theme),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _tableHeader('Fecha', flex: 2, theme: theme),
            _tableHeader('Descripción', flex: 4, theme: theme),
            _tableHeader('Categoría', flex: 3, theme: theme),
            _tableHeader('Monto', flex: 2, theme: theme, alignRight: true),
          ],
        ),
        pw.SizedBox(height: 6),
        ...transactions.map((transaction) {
          final isExpense = transaction.type == 'expense';
          final amountColor = isExpense ? theme.error : theme.success;
          final description = transaction.notes?.trim().isNotEmpty == true
              ? transaction.notes!.trim()
              : AppCategories.labelForId(transaction.category);

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _tableCell(
                  DateFormat('dd/MM').format(transaction.date),
                  flex: 2,
                  theme: theme,
                ),
                _tableCell(description, flex: 4, theme: theme),
                _tableCell(
                  AppCategories.labelForId(transaction.category),
                  flex: 3,
                  theme: theme,
                ),
                _tableCell(
                  '${isExpense ? '-' : '+'}${_formatCurrency(transaction.amount)}',
                  flex: 2,
                  theme: theme,
                  alignRight: true,
                  color: amountColor,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _summaryColumn({
    required String label,
    required double value,
    required BrumaTheme theme,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: _pdfColor(theme.textSecondary),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          _formatCurrency(value),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _pdfColor(theme.textPrimary),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title, BrumaTheme theme) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _pdfColor(theme.textSecondary),
      ),
    );
  }

  pw.Widget _tableHeader(
    String text, {
    required int flex,
    required BrumaTheme theme,
    bool alignRight = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _pdfColor(theme.textSecondary),
        ),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    required int flex,
    required BrumaTheme theme,
    bool alignRight = false,
    Color? color,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        maxLines: 2,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          color: _pdfColor(color ?? theme.textPrimary),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    ).format(value);
  }

  PdfColor _pdfColor(Color color) {
    return PdfColor(
      color.r,
      color.g,
      color.b,
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

final monthlyReportServiceProvider = Provider<MonthlyReportService>((ref) {
  return MonthlyReportService(
    supabase,
    ref.watch(budgetRepositoryProvider),
  );
});
