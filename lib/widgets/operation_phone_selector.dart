import 'package:flutter/material.dart';

import '../controllers/operation_phone_controller.dart';
import '../core/theme.dart';

/// Sélecteur de numéro d'opération (filtre historique / statistiques).
class OperationPhoneSelector extends StatelessWidget {
  const OperationPhoneSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OperationPhoneController.instance,
      builder: (context, _) {
        final c = OperationPhoneController.instance;
        final phones = c.registeredPhones;
        if (phones.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Text(
              "Ajoute jusqu'à 3 numéros d'opération dans Profil commerce pour filtrer l'historique et les stats.",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: c.selectedForFilter,
              hint: const Text("Tous les numéros"),
              icon: const Icon(Icons.sim_card_rounded, color: AppColors.primary),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text("Tous les numéros"),
                ),
                ...phones.map(
                  (p) => DropdownMenuItem<String?>(
                    value: p,
                    child: Text(p, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) async {
                if (v == null) {
                  await c.selectAllNumbers();
                } else {
                  await c.selectPhone(v);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
