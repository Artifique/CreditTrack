import 'package:flutter/material.dart';
import '../../../core/app_formatters.dart';

/// Bandeau vert clair présentant la commission estimée calculée automatiquement.
class OperationEstimatedCommissionCard extends StatelessWidget {
  final double estimatedCommission;
  final bool isDark;

  const OperationEstimatedCommissionCard({
    super.key,
    required this.estimatedCommission,
    required this.isDark,
  });

  String _formatAmount(double amt) => AppFormatters.formatAmount(amt);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
            : const Color(0xFFE6F8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF059669) : const Color(0xFFC7F0DF),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commission estimée',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFF065F46),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calculée automatiquement',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          Text(
            '+ ${_formatAmount(estimatedCommission)} F',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }
}
