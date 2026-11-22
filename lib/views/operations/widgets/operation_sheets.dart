import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Feuille modale pour personnaliser l'affichage des soldes.
class OperationCustomizeSheet extends StatelessWidget {
  final bool showOmBalance;
  final bool showCreditBalance;
  final bool showCashBalance;
  final ValueChanged<bool> onToggleOm;
  final ValueChanged<bool> onToggleCredit;
  final ValueChanged<bool>? onToggleCash;
  final VoidCallback onManageSims;

  const OperationCustomizeSheet({
    super.key,
    required this.showOmBalance,
    required this.showCreditBalance,
    this.showCashBalance = true,
    required this.onToggleOm,
    required this.onToggleCredit,
    this.onToggleCash,
    required this.onManageSims,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personnaliser l’affichage',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(
                'Afficher le solde Orange Money',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              value: showOmBalance,
              activeThumbColor: AppTokens.primary500,
              onChanged: onToggleOm,
            ),
            SwitchListTile(
              title: Text(
                'Afficher le solde Crédit',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              value: showCreditBalance,
              activeThumbColor: AppTokens.primary500,
              onChanged: onToggleCredit,
            ),
            if (onToggleCash != null)
              SwitchListTile(
                title: Text(
                  'Afficher le solde Espèce',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                value: showCashBalance,
                activeThumbColor: const Color(0xFF0D9488),
                onChanged: onToggleCash,
              ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  Icon(Icons.sim_card_outlined, color: AppTokens.primary500),
              title: Text(
                'Gérer les cartes SIM associées',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              onTap: onManageSims,
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille modale d'affichage des alertes et notifications système.
class OperationNotificationsSheet extends StatelessWidget {
  const OperationNotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications & Alertes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x33FF6600)
                      : const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: AppTokens.primary500, size: 20),
              ),
              title: Text(
                'Caisse Orange Money connectée',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                'Vos soldes sont synchronisés en direct.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x3310B981)
                      : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_rounded,
                    color: Color(0xFF10B981), size: 20),
              ),
              title: Text(
                'Compte Crédit actif',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                'Opérations de recharge disponibles à la caisse.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
