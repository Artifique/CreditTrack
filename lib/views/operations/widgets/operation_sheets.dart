import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Feuille modale pour personnaliser l'affichage des soldes.
class OperationCustomizeSheet extends StatelessWidget {
  final bool showOmBalance;
  final bool showCreditBalance;
  final ValueChanged<bool> onToggleOm;
  final ValueChanged<bool> onToggleCredit;
  final VoidCallback onManageSims;

  const OperationCustomizeSheet({
    super.key,
    required this.showOmBalance,
    required this.showCreditBalance,
    required this.onToggleOm,
    required this.onToggleCredit,
    required this.onManageSims,
  });

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Personnaliser l’affichage',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Afficher le solde Orange Money', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: showOmBalance,
              activeThumbColor: AppTokens.primary500,
              onChanged: onToggleOm,
            ),
            SwitchListTile(
              title: const Text('Afficher le solde Crédit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: showCreditBalance,
              activeThumbColor: AppTokens.primary500,
              onChanged: onToggleCredit,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.sim_card_outlined, color: AppTokens.primary500),
              title: const Text('Gérer les cartes SIM associées', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
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
                const Text(
                  'Notifications & Alertes',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTokens.primary500, size: 20),
              ),
              title: const Text('Caisse Orange Money connectée', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              subtitle: const Text('Vos soldes sont synchronisés en direct.', style: TextStyle(fontSize: 12)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_rounded, color: Color(0xFF10B981), size: 20),
              ),
              title: const Text('Compte Crédit actif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              subtitle: const Text('Opérations de recharge disponibles à la caisse.', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
