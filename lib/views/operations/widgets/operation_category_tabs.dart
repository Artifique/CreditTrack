import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Onglets de sélection de catégorie (Mobile Money / Crédit) pour la caisse.
class OperationCategoryTabs extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final bool isDark;

  const OperationCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkBgSubtle : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onSelectCategory('UV'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedCategory == 'UV'
                      ? (isDark ? AppTokens.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedCategory == 'UV'
                      ? [const BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Mobile Money',
                  style: TextStyle(
                    fontWeight: selectedCategory == 'UV' ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13.5,
                    color: selectedCategory == 'UV'
                        ? (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary)
                        : (isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelectCategory('CREDIT'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedCategory == 'CREDIT'
                      ? (isDark ? AppTokens.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedCategory == 'CREDIT'
                      ? [const BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Crédit',
                  style: TextStyle(
                    fontWeight: selectedCategory == 'CREDIT' ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13.5,
                    color: selectedCategory == 'CREDIT'
                        ? (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary)
                        : (isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
