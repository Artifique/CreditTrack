import 'package:flutter/material.dart';
import '../../../core/app_formatters.dart';
import '../../../core/tokens.dart';

/// Grille 2×3 des 6 montants rapides conforme à la capture d'écran.
class OperationQuickAmountsGrid extends StatelessWidget {
  final double currentAmount;
  final ValueChanged<int> onSelectAmount;
  final bool isDark;

  const OperationQuickAmountsGrid({
    super.key,
    required this.currentAmount,
    required this.onSelectAmount,
    required this.isDark,
  });

  static const List<int> quickAmounts = [1000, 2000, 3000, 4000, 5000, 10000];

  String _formatAmount(int amt) => AppFormatters.formatAmount(amt);

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTokens.primary500;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCard(quickAmounts[0], primaryColor)),
            const SizedBox(width: 10),
            Expanded(child: _buildCard(quickAmounts[1], primaryColor)),
            const SizedBox(width: 10),
            Expanded(child: _buildCard(quickAmounts[2], primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildCard(quickAmounts[3], primaryColor)),
            const SizedBox(width: 10),
            Expanded(child: _buildCard(quickAmounts[4], primaryColor)),
            const SizedBox(width: 10),
            Expanded(child: _buildCard(quickAmounts[5], primaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(int amount, Color iconColor) {
    final isSelected = currentAmount == amount.toDouble();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectAmount(amount),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTokens.primary50
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? iconColor
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_outlined,
                color: iconColor,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatAmount(amount)} FCFA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? iconColor
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
