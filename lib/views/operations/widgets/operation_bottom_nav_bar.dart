import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Barre de navigation inférieure pour la vue principale de la caisse.
class OperationBottomNavBar extends StatelessWidget {
  final bool isHomeSelected;
  final VoidCallback onHomeTap;
  final VoidCallback onMenuTap;
  final VoidCallback onReportingTap;

  const OperationBottomNavBar({
    super.key,
    required this.isHomeSelected,
    required this.onHomeTap,
    required this.onMenuTap,
    required this.onReportingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x08000000),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                isSelected: isHomeSelected,
                isDark: isDark,
                onTap: onHomeTap,
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Menu',
                isSelected: false,
                isDark: isDark,
                onTap: onMenuTap,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Reporting',
                isSelected: false,
                isDark: isDark,
                onTap: onReportingTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppTokens.primary500
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
