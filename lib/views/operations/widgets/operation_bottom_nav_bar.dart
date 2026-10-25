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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, -2),
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
                onTap: onHomeTap,
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Menu',
                isSelected: false,
                onTap: onMenuTap,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Reporting',
                isSelected: false,
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTokens.primary500 : Colors.black87;

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
