import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/tokens.dart';
import 'operation_balance_card.dart';

/// Tiroir de navigation latéral pour les opérations et réglages.
class OperationDrawer extends StatelessWidget {
  final String businessName;
  final String activePhone;
  final VoidCallback onHomeTap;

  const OperationDrawer({
    super.key,
    required this.businessName,
    required this.activePhone,
    required this.onHomeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTokens.primary500, AppTokens.primary600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const OrangeMoneyLogo(size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          activePhone.isNotEmpty
                              ? 'Ligne active : $activePhone'
                              : 'Orange Money Caisse',
                          style: const TextStyle(
                            color: Color(0xFFFFF3E0),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_rounded, color: AppTokens.primary500),
                    title: const Text('Accueil / Nouvelle Opération', style: TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () {
                      Navigator.pop(context);
                      onHomeTap();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: Colors.black87),
                    title: const Text('Journal des transactions', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded, color: Colors.black87),
                    title: const Text('Reporting & Commissions', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sim_card_rounded, color: Colors.black87),
                    title: const Text('Gestion des cartes SIM', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings-sims');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: Colors.black87),
                    title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Orange Money • CreditTrack Pro',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
