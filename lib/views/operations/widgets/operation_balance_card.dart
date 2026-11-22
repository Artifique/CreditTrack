import 'package:flutter/material.dart';
import '../../../core/app_formatters.dart';
import '../../../core/tokens.dart';

/// Grande carte de solde (Orange Money ou Solde Crédit).
class OperationBalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final Widget logo;
  final VoidCallback? onTap;

  const OperationBalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.logo,
    this.onTap,
  });

  String _formatAmount(double amt) => AppFormatters.formatAmount(amt);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppTokens.primary500,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDark ? const Color(0x18000000) : const Color(0x06000000),
                blurRadius: 5,
                offset: const Offset(0, 2),
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
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVisible
                          ? '${_formatAmount(amount)} CFA'
                          : '•••••••• CFA',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
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
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                  size: 22,
                ),
                splashRadius: 20,
                tooltip: isVisible ? 'Masquer le solde' : 'Afficher le solde',
              ),
            ],
          ),
        ),
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

/// Logo Espèce / Caisse Universelle miniature stylisé
class CashBalanceLogo extends StatelessWidget {
  final double size;

  const CashBalanceLogo({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140D9488),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.payments_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}
