import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/app_categories.dart';
import '../../../../core/theme/app_theme.dart';

class CategoryItem {
  final String id;
  final String emoji;
  final String label;

  const CategoryItem(this.id, this.emoji, this.label);

  factory CategoryItem.fromAppCategory(AppCategory category) {
    return CategoryItem(category.id, category.emoji, category.label);
  }
}

final List<CategoryItem> kCategories = AppCategories.expenses
    .map(CategoryItem.fromAppCategory)
    .toList(growable: false);

class CategorySelector extends StatelessWidget {
  final CategoryItem selected;
  final ValueChanged<CategoryItem> onSelected;

  const CategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kCategories.length,
        itemBuilder: (context, index) {
          final cat = kCategories[index];
          final isSelected = cat.label == selected.label;

          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? b.primary : b.surfaceAlt,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? b.primary
                      : b.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: GoogleFonts.dmSans(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? b.onPrimary : b.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
