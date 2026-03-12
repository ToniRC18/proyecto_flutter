import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/numeric_keyboard.dart';
import 'widgets/category_selector.dart';

class AddExpenseScreen extends StatefulWidget {
  /// Categoría preseleccionada, leída desde el query param ?category=
  /// en app_router.dart. Si es null, se usa la primera de la lista.
  final CategoryItem? initialCategory;

  const AddExpenseScreen({super.key, this.initialCategory});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amount = '0';
  late CategoryItem _selectedCategory;
  bool _isSavePressed = false;

  @override
  void initState() {
    super.initState();
    // Si el router pasó una categoría inicial (vía ?category=), úsala.
    // De lo contrario, selecciona la primera de la lista.
    _selectedCategory = widget.initialCategory ?? kCategories.first;
  }

  void _handleKeyPress(String key) {
    setState(() {
      if (_amount == '0' && key != '.') {
        _amount = key;
      } else if (key == '.' && _amount.contains('.')) {
        return; // Solo un punto decimal
      } else {
        // Limitar la longitud por estética
        if (_amount.length < 9) {
          _amount += key;
        }
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _saveExpense() {
    // Aquí implementas si tienes backend, por ahora es solo pop
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'New Expense',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 48), // para balancear el icono de close
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Amount Display
                  Text(
                    '\$$_amount',
                    style: GoogleFonts.poppins(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selected Category Indicator (solo visual feedback rápido)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_selectedCategory.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCategory.label,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Horizontal Category Selector
                  CategorySelector(
                    selected: _selectedCategory,
                    onSelected: (cat) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Keyboard
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: NumericKeyboard(
                onKeyPress: _handleKeyPress,
                onBackspace: _handleBackspace,
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isSavePressed = true),
                onTapUp: (_) {
                  setState(() => _isSavePressed = false);
                  _saveExpense();
                },
                onTapCancel: () => setState(() => _isSavePressed = false),
                child: AnimatedScale(
                  scale: _isSavePressed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Save Expense',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8), // Bottom padding extra 
          ],
        ),
      ),
    );
  }
}
