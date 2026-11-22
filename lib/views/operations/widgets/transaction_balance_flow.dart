import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Bloc visuel présentant l'évolution du solde (Solde avant -> Solde après).
class TransactionBalanceFlow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? accentColor;
  final String soldeAvantFormatted;
  final String soldeApresFormatted;
  final bool isDark;

  const TransactionBalanceFlow({
    super.key,
    this.title = 'Évolution du solde caisse',
    this.icon = Icons.analytics_outlined,
    this.accentColor,
    required this.soldeAvantFormatted,
    required this.soldeApresFormatted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent =
        accentColor ?? (isDark ? AppTokens.primary300 : AppTokens.primary600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x331E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0x33475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: effectiveAccent,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: effectiveAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde avant',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTokens.darkTextTertiary
                            : AppTokens.lightTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      soldeAvantFormatted,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTokens.darkTextPrimary
                            : AppTokens.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.trending_flat_rounded,
                size: 20,
                color: isDark
                    ? AppTokens.darkTextTertiary
                    : AppTokens.lightTextTertiary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Solde après',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTokens.darkTextTertiary
                            : AppTokens.lightTextTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      soldeApresFormatted,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: effectiveAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
