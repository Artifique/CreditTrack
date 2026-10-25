import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/tokens.dart';

/// Grande carte de solde (Orange Money ou Solde Crédit).
class OperationBalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final Widget logo;

  const OperationBalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.logo,
  });

  String _formatAmount(double amt) => NumberFormat('#,##0', 'fr_FR').format(amt);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.primary500, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVisible ? '${_formatAmount(amount)} CFA' : '•••••••• CFA',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF6B7280),
              size: 22,
            ),
            splashRadius: 20,
            tooltip: isVisible ? 'Masquer le solde' : 'Afficher le solde',
          ),
        ],
      ),
    );
  }
}

/// Logo Orange Money miniature stylisé
class OrangeMoneyLogo extends StatelessWidget {
  final double size;

  const OrangeMoneyLogo({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTokens.primary500,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTokens.primary500.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'om',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.42,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

/// Logo Crédit/Épargne miniature stylisé
class CreditBalanceLogo extends StatelessWidget {
  final double size;

  const CreditBalanceLogo({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1410B981),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.savings_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
